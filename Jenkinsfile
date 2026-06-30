pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'qa', 'prod'], description: 'Target environment')
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action')
        booleanParam(name: 'AUTO_APPROVE', defaultValue: false, description: 'Auto approve (dev only)')
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
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                sh 'terraform version'
            }
        }

        // 🔥 GLOBAL AWS CREDENTIALS (FIXES YOUR ERROR)
        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-terraform-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

                    sh '''
                        rm -rf .terraform

                        terraform init -reconfigure \
                            -backend-config="bucket=terraform-ha-infra-state-file" \
                            -backend-config="key=infrastructure/terraform.tfstate" \
                            -backend-config="region=us-east-1" \
                            -backend-config="encrypt=true" \
                            -no-color
                    '''
                }
            }
        }

        // 🔥 FIXED WORKSPACE HANDLING
        stage('Select Workspace') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-terraform-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

                    sh """
                        terraform workspace list
                        terraform workspace select ${params.ENVIRONMENT} || terraform workspace new ${params.ENVIRONMENT}
                        terraform workspace show
                    """
                }
            }
        }

        stage('Validate') {
    steps {
        sh 'terraform fmt -recursive'
        sh 'terraform validate -no-color'
    }
}

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-terraform-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

                    script {
                        def action = params.ACTION

                        def cmd = "terraform plan -var-file=${TF_VAR_FILE} -out=tfplan -no-color"

                        if (action == 'destroy') {
                            cmd = "terraform plan -destroy -var-file=${TF_VAR_FILE} -out=tfplan -no-color"
                        }

                        sh cmd
                    }

                    sh 'terraform show -no-color tfplan > tfplan.txt'
                    archiveArtifacts artifacts: 'tfplan.txt'
                }
            }
        }

        stage('Approval') {
            when {
                expression {
                    return params.ACTION != 'plan' &&
                           (params.ENVIRONMENT != 'dev' || !params.AUTO_APPROVE)
                }
            }
            steps {
                input message: "Approve ${params.ACTION} for ${params.ENVIRONMENT}?"
            }
        }

        stage('Terraform Apply') {
            when {
                expression { return params.ACTION != 'plan' }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-terraform-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

                    sh '''
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Outputs') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                sh 'terraform output'
            }
        }
    }

    post {
        always {
            sh 'rm -f tfplan tfplan.txt || true'
            cleanWs()
        }

        success {
            echo "✅ Terraform ${params.ACTION} succeeded for ${params.ENVIRONMENT}"
        }

        failure {
            echo "❌ Terraform ${params.ACTION} failed for ${params.ENVIRONMENT}"
        }
    }
}
