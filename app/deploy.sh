#!/bin/bash
################################################################################
# Deploy Script — Build, Push, and Deploy Banking App
#
# Usage:
#   ./deploy.sh                    # Deploy all (backend + frontend)
#   ./deploy.sh backend            # Deploy backend only
#   ./deploy.sh frontend           # Deploy frontend only
################################################################################

set -euo pipefail

COMPONENT=${1:-all}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Get Terraform outputs
echo "📋 Reading Terraform outputs..."
cd "$PROJECT_ROOT"
ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
APP_BUCKET=$(terraform output -raw app_bucket_name 2>/dev/null || echo "")
AWS_REGION=$(terraform output -raw primary_region 2>/dev/null || "us-east-1")
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
ECS_SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")
CF_DOMAIN=$(terraform output -raw cloudfront_domain_name 2>/dev/null || echo "")

# ─── Backend Deploy ──────────────────────────────────────────────────────────
deploy_backend() {
    echo "🐳 Building Docker image..."
    cd "$PROJECT_ROOT/app/backend"
    
    # Login to ECR
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URL"
    
    # Build and push
    docker build -t banking-app .
    docker tag banking-app:latest "$ECR_URL:latest"
    docker push "$ECR_URL:latest"
    
    # Force new deployment
    echo "🚀 Deploying to ECS..."
    aws ecs update-service \
        --cluster "$ECS_CLUSTER" \
        --service "$ECS_SERVICE" \
        --force-new-deployment \
        --region "$AWS_REGION"
    
    echo "✅ Backend deployed! ECS will roll out the new image."
}

# ─── Frontend Deploy ─────────────────────────────────────────────────────────
deploy_frontend() {
    echo "📦 Uploading frontend to S3..."
    cd "$PROJECT_ROOT/app/frontend"
    
    aws s3 sync . "s3://$APP_BUCKET/frontend/" \
        --delete \
        --cache-control "public, max-age=3600" \
        --region "$AWS_REGION"
    
    # Invalidate CloudFront cache
    if [ -n "$CF_DOMAIN" ]; then
        echo "🔄 Invalidating CloudFront cache..."
        CF_DIST_ID=$(aws cloudfront list-distributions --query \
            "DistributionList.Items[?DomainName=='$CF_DOMAIN'].Id" --output text)
        if [ -n "$CF_DIST_ID" ]; then
            aws cloudfront create-invalidation --distribution-id "$CF_DIST_ID" --paths "/frontend/*"
        fi
    fi
    
    echo "✅ Frontend deployed to s3://$APP_BUCKET/frontend/"
}

# ─── DB Init ─────────────────────────────────────────────────────────────────
init_db() {
    echo "🗄️  Running database init script..."
    DB_ENDPOINT=$(terraform output -raw rds_cluster_endpoint 2>/dev/null || echo "")
    
    if [ -z "$DB_ENDPOINT" ]; then
        echo "⚠️  No RDS endpoint found. Run 'terraform apply' first."
        exit 1
    fi
    
    echo "Connect to bastion and run:"
    echo "  psql -h $DB_ENDPOINT -U dbadmin -d bankingdb -f app/db/init.sql"
}

# ─── Execute ─────────────────────────────────────────────────────────────────
case "$COMPONENT" in
    backend)  deploy_backend ;;
    frontend) deploy_frontend ;;
    db)       init_db ;;
    all)
        deploy_backend
        deploy_frontend
        echo ""
        echo "🎉 Full deployment complete!"
        echo "   Frontend: https://$CF_DOMAIN/frontend/"
        echo "   API:      https://$CF_DOMAIN/api/"
        ;;
    *) echo "Usage: $0 {all|backend|frontend|db}" && exit 1 ;;
esac
