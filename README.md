# Terraform AWS HA Infrastructure — Hiqode Banking

Highly Available, Globally Available, Disaster Recovery & Secured AWS Infrastructure built with Terraform.  
Includes a **full-stack banking application** (Hiqode) — frontend, backend API, and PostgreSQL database.

## Architecture

```
                        ┌──────────────────────┐
                        │   CloudFront CDN     │
                        │   + WAF v2 (OWASP)   │
                        └──────┬───────┬───────┘
                               │       │
                    /frontend/* │       │ /api/*
                               ▼       ▼
                        ┌──────────┐ ┌─────────────────┐
                        │ S3 Bucket│ │ Application LB   │
                        │ (static) │ │ (HTTPS/TLS 1.2+) │
                        └──────────┘ └────────┬────────┘
                                              │
                                     ┌────────▼────────┐
                                     │  ECS Fargate     │
                                     │  banking-api:3000│
                                     │  (Auto-scaling)  │
                                     └────────┬────────┘
                                              │
                              ┌───────────────┼───────────────┐
                              ▼                               ▼
                     ┌────────────────┐            ┌──────────────────┐
                     │ Aurora PostgreSQL│            │ ElastiCache Redis│
                     │ (Multi-AZ)      │            │ (Session Cache)  │
                     └────────────────┘            └──────────────────┘
```

- **16 Terraform Modules**: VPC, Security Groups, IAM, KMS, ALB, ECS Fargate, ECR, Aurora RDS, ElastiCache Redis, S3, CloudFront, WAF, Route53, ACM, Bastion, Monitoring
- **3 Environments**: dev, qa, prod (via Terraform workspaces)
- **Multi-Region DR**: Cross-region replication for prod
- **Jenkins CI/CD**: Pipeline with approval gates

## Banking App (Hiqode)

| Layer | Technology | Deployment Target |
|-------|-----------|-------------------|
| **Frontend** | HTML / CSS / JavaScript | S3 → CloudFront |
| **Backend** | Node.js / Express API | ECR → ECS Fargate |
| **Database** | PostgreSQL (Aurora) | RDS Multi-AZ |

### Features
- 🔐 JWT authentication (login/register)
- 💰 Multi-account management (savings, checking, business)
- 💸 Real-time fund transfers with ACID transactions
- 📊 Transaction history & balance dashboard
- 🎨 Dark theme UI with glassmorphism design
- 🏥 Health check endpoint for ALB

### App Structure

```
app/
├── frontend/
│   ├── index.html       # Banking UI — login, dashboard, transfers
│   ├── style.css        # Dark theme with responsive design
│   └── app.js           # Client logic with demo mode
├── backend/
│   ├── server.js        # Express API — auth, accounts, transactions
│   ├── package.json     # Node.js dependencies
│   └── Dockerfile       # Container image for ECS
├── db/
│   └── init.sql         # PostgreSQL schema + seed data
└── deploy.sh            # One-command deploy script
```

## Quick Start

```bash
# 1. Initialize
terraform init

# 2. Create workspace
terraform workspace new dev

# 3. Plan & Apply infrastructure
terraform plan -var-file=environments/dev.tfvars -out=tfplan
terraform apply tfplan

# 4. Deploy the banking app
./app/deploy.sh all       # Builds, pushes, and deploys everything
```

### Deploy Commands

```bash
./app/deploy.sh backend   # Build Docker → Push to ECR → ECS redeploy
./app/deploy.sh frontend  # Sync HTML/CSS/JS → S3 → Invalidate CloudFront
./app/deploy.sh db        # Show DB init instructions (via bastion)
./app/deploy.sh all       # Deploy everything
```

## Project Structure

```
├── main.tf              # Root module — wires all 16 modules
├── variables.tf         # Root variables
├── outputs.tf           # Root outputs (incl. ECR URL)
├── providers.tf         # AWS providers (primary + DR)
├── backend.tf           # S3 remote state
├── versions.tf          # Version constraints
├── locals.tf            # Environment configs & common tags
├── Jenkinsfile          # CI/CD pipeline
├── app/                 # ← Banking application
│   ├── frontend/        # Static HTML/CSS/JS
│   ├── backend/         # Node.js API + Dockerfile
│   ├── db/              # PostgreSQL schema
│   └── deploy.sh        # Deploy script
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
    ├── ecs/             # ECS Fargate with auto-scaling + DB env vars
    ├── ecr/             # Container registry for banking-api
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

## Infrastructure ↔ App Connection

| App Layer | Terraform Module | Connection Method |
|-----------|-----------------|-------------------|
| Frontend (HTML/JS) | `s3` + `cloudfront` | `aws s3 sync` via deploy.sh |
| Backend (Node.js) | `ecr` + `ecs` | Docker push → ECS task update |
| Database (PostgreSQL) | `rds` | ECS env vars: `DB_HOST`, `DB_PORT`, `DB_NAME` |
| API Routing | `alb` | ALB target group → ECS port 3000 |
| DNS | `route53` + `acm` | HTTPS via CloudFront + ACM certs |
| Security | `waf` + `security-groups` | WAF rules + SG chaining |

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
3. **Docker** (for building backend image)
4. **Node.js 20+** (for local development)
5. **S3 bucket** for remote state (create before init)

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
```

## Local Development

```bash
# Frontend — just open in browser (demo mode enabled)
open app/frontend/index.html

# Backend — requires PostgreSQL running locally
cd app/backend
npm install
DB_HOST=localhost DB_NAME=bankingdb npm run dev
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
- 🔐 JWT authentication for API endpoints
- 🗄️ Database credentials via AWS Secrets Manager
