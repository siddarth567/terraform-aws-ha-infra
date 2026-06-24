# Terraform AWS HA Infrastructure

Highly Available, Globally Available, Disaster Recovery & Secured AWS Infrastructure built with Terraform.

## Architecture

- **15 Terraform Modules**: VPC, Security Groups, IAM, KMS, ALB, ECS Fargate, Aurora RDS, ElastiCache Redis, S3, CloudFront, WAF, Route53, ACM, Bastion, Monitoring
- **3 Environments**: dev, qa, prod (via Terraform workspaces)
- **Multi-Region DR**: Cross-region replication for prod
- **Jenkins CI/CD**: Pipeline with approval gates

## Quick Start

```bash
# 1. Initialize
terraform init

# 2. Create workspace
terraform workspace new dev

# 3. Plan
terraform plan -var-file=environments/dev.tfvars -out=tfplan

# 4. Apply
terraform apply tfplan
```

## Project Structure

```
├── main.tf              # Root module — wires all modules
├── variables.tf         # Root variables
├── outputs.tf           # Root outputs
├── providers.tf         # AWS providers (primary + DR)
├── backend.tf           # S3 remote state
├── versions.tf          # Version constraints
├── locals.tf            # Environment configs & common tags
├── Jenkinsfile          # CI/CD pipeline
├── environments/
│   ├── dev.tfvars       # Dev overrides
│   ├── qa.tfvars        # QA overrides
│   └── prod.tfvars      # Prod overrides
└── modules/
    ├── vpc/             # Multi-AZ VPC, NAT, Flow Logs, NACLs
    ├── security-groups/ # Chained SGs (ALB→ECS→RDS→Redis)
    ├── iam/             # Least-privilege roles
    ├── kms/             # Encryption keys with rotation
    ├── alb/             # Application Load Balancer
    ├── ecs/             # ECS Fargate with auto-scaling
    ├── rds/             # Aurora PostgreSQL Multi-AZ
    ├── elasticache/     # Redis cluster
    ├── s3/              # Encrypted buckets + CRR
    ├── cloudfront/      # CDN distribution
    ├── waf/             # WAF v2 with OWASP rules
    ├── route53/         # DNS with failover routing
    ├── acm/             # SSL/TLS certificates
    ├── bastion/         # Bastion host with SSM
    └── monitoring/      # CloudWatch, CloudTrail, SNS
```

## Environment Comparison

| Feature | Dev | QA | Prod |
|---------|-----|-----|------|
| NAT Gateways | 1 | 2 | 3 |
| ECS Tasks | 1-2 | 2-4 | 3-10 |
| RDS Instances | 1 | 2 | 3 |
| WAF | ❌ | ✅ | ✅ |
| Multi-Region DR | ❌ | ❌ | ✅ |
| Deletion Protection | ❌ | ✅ | ✅ |
| Backup Retention | 7 days | 14 days | 35 days |

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform >= 1.6**
3. **S3 bucket** for remote state (create before init)
4. **DynamoDB table** for state locking (create before init)

### Bootstrap State Backend

```bash
aws s3api create-bucket \
  --bucket terraform-ha-infra-state \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket terraform-ha-infra-state \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket terraform-ha-infra-state \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws dynamodb create-table \
  --table-name terraform-ha-infra-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Jenkins Pipeline

The `Jenkinsfile` supports:
- **Parameters**: ENVIRONMENT (dev/qa/prod), ACTION (plan/apply/destroy)
- **Approval Gates**: Manual approval for qa/prod deployments
- **Workspace Isolation**: Each environment uses a separate state
- **Artifact Archival**: Plans are saved for audit

## Security Highlights

- 🔐 KMS encryption at rest (S3, RDS, ElastiCache, CloudWatch)
- 🔒 TLS 1.2+ in transit everywhere
- 🛡️ WAF with OWASP managed rules + rate limiting
- 🏠 Private subnets for compute and database tiers
- 🔑 IAM least-privilege policies
- 📋 CloudTrail audit logging (all regions)
- 🔗 Security group chaining (no direct access to databases)
- 🚪 SSM Session Manager (no SSH keys)
- 🔒 IMDSv2 enforced on all EC2 instances
