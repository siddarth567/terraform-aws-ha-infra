################################################################################
# Remote State Backend — S3 + DynamoDB Locking
#
# The S3 bucket and DynamoDB table must be created BEFORE running terraform init.
# Use the bootstrap script or create manually:
#   - S3 Bucket:      terraform-ha-infra-state-<account-id>
#   - DynamoDB Table: terraform-ha-infra-lock
#
# Workspace-aware: state is stored at env:/<workspace>/terraform.tfstate
################################################################################

terraform {
  backend "s3" {
    bucket         = "terraform-ha-infra-state-new"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true      # replaces deprecated dynamodb_table (requires S3 versioning)

    # Enable S3 bucket versioning for state file history
    # These settings should be configured on the S3 bucket itself:
    #   - Versioning: Enabled
    #   - Server-Side Encryption: AES-256 or KMS
    #   - Block Public Access: All enabled
  }
}
