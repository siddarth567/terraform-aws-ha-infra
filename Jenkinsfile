/**
 * Jenkins CI/CD Pipeline for Terraform AWS HA Infrastructure
 *
 * This pipeline manages infrastructure deployment across dev, qa, and prod
 * environments using Terraform workspaces.
 *
 * Prerequisites:
 *   - Jenkins with Pipeline plugin
 *   - Terraform >= 1.6 installed on agents
 *   - AWS credentials configured (Jenkins credentials or IAM role)
 *   - S3 backend bucket and DynamoDB table created
 *
 * Parameters:
 *   - ENVIRONMENT: Target environment (dev, qa, prod)
 *   - ACTION: Terraform action (plan, apply, destroy)
 *   - AUTO_APPROVE: Skip manual approval (dev only)
 */

pipeline {
    agent any
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'qa', 'prod'],
            description: 'Target environment to deploy'
        )
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Terraform action to perform'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Auto-approve apply (dev only, ignored for qa/prod)'
        )
    }

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_INPUT         = 'false'
        AWS_REGION       = 'us-east-1'
        TF_VAR_FILE      = "environments/${params.ENVIRONMENT}.tfvars"
    }

    options {
        timestamps()
        ansiColor('xterm')
        timeout(time: 60, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '30'))
    }

    stages {
        // ─── Stage 1: Checkout ───────────────────────────────────────────────
        stage('Checkout') {
            steps {
                checkout scm
                sh 'terraform version'
            }
        }

        // ─── Stage 2: Initialize ────────────────────────────────────────────
        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-terraform-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {

                    sh '''
                        terraform init \
                            -backend-config="bucket=terraform-ha-infra-state" \
                            -backend-config="key=infrastructure/terraform.tfstate" \
                            -backend-config="region=${AWS_REGION}" \
                            -backend-config="dynamodb_table=terraform-ha-infra-lock" \
                            -backend-config="encrypt=true" \
                            -no-color
                    '''
                }
            }
        }

        // ─── Stage 3: Workspace ─────────────────────────────────────────────
        stage('Select Workspace') {
            steps {
                sh """
                    terraform workspace select ${params.ENVIRONMENT} || \
                    terraform workspace new ${params.ENVIRONMENT}
                """
                sh 'terraform workspace show'
            }
        }

        // ─── Stage 4: Validate ──────────────────────────────────────────────
        stage('Validate') {
            steps {
                sh 'terraform fmt -check -recursive -diff'
                sh 'terraform validate -no-color'
            }
        }

        // ─── Stage 5: Plan ──────────────────────────────────────────────────
        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-terraform-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {

                    script {
                        def planCommand = "terraform plan -var-file=${TF_VAR_FILE} -out=tfplan -no-color"
                        if (params.ACTION == 'destroy') {
                            planCommand = "terraform plan -var-file=${TF_VAR_FILE} -destroy -out=tfplan -no-color"
                        }
                        sh planCommand
                    }

                    // Archive the plan for review
                    sh 'terraform show -no-color tfplan > tfplan.txt'
                    archiveArtifacts artifacts: 'tfplan.txt', fingerprint: true
                }
            }
        }

        // ─── Stage 6: Manual Approval (qa/prod only) ────────────────────────
        stage('Approval') {
            when {
                expression {
                    return params.ACTION != 'plan' && (
                        params.ENVIRONMENT != 'dev' || !params.AUTO_APPROVE
                    )
                }
            }
            steps {
                script {
                    def planOutput = readFile('tfplan.txt')
                    def approvalMsg = """
                        Environment: ${params.ENVIRONMENT}
                        Action: ${params.ACTION}

                        Please review the Terraform plan above and approve to proceed.

                        Plan Summary (last 20 lines):
                        ${planOutput.split('\n').takeRight(20).join('\n')}
                    """.stripIndent()

                    timeout(time: 30, unit: 'MINUTES') {
                        input message: approvalMsg,
                              ok: "Approve ${params.ACTION}",
                              submitter: 'infra-approvers'
                    }
                }
            }
        }

        // ─── Stage 7: Apply / Destroy ───────────────────────────────────────
        stage('Terraform Apply') {
            when {
                expression { return params.ACTION != 'plan' }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-terraform-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {

                    sh 'terraform apply -auto-approve -no-color tfplan'
                }
            }
        }

        // ─── Stage 8: Output ────────────────────────────────────────────────
        stage('Show Outputs') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                sh 'terraform output -no-color'
            }
        }
    }

    post {
        always {
            // Clean up plan files
            sh 'rm -f tfplan tfplan.txt'
            cleanWs()
        }
        success {
            script {
                def emoji = params.ACTION == 'destroy' ? '🗑️' : '✅'
                echo "${emoji} Terraform ${params.ACTION} succeeded for ${params.ENVIRONMENT}"

                // Uncomment to enable Slack notifications:
                // slackSend(
                //     channel: '#infra-deployments',
                //     color: 'good',
                //     message: "${emoji} Terraform ${params.ACTION} succeeded for *${params.ENVIRONMENT}*\n" +
                //              "Build: ${env.BUILD_URL}\n" +
                //              "Triggered by: ${currentBuild.getBuildCauses()[0].shortDescription}"
                // )
            }
        }
        failure {
            script {
                echo "❌ Terraform ${params.ACTION} failed for ${params.ENVIRONMENT}"

                // Uncomment to enable Slack notifications:
                // slackSend(
                //     channel: '#infra-deployments',
                //     color: 'danger',
                //     message: "❌ Terraform ${params.ACTION} FAILED for *${params.ENVIRONMENT}*\n" +
                //              "Build: ${env.BUILD_URL}\n" +
                //              "Triggered by: ${currentBuild.getBuildCauses()[0].shortDescription}"
                // )
            }
        }
    }
}
