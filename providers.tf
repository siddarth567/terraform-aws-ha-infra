################################################################################
# AWS Provider Configuration
#
# Primary region: var.primary_region (default: us-east-1)
# DR region:      var.dr_region (default: us-west-2) — aliased as "dr"
################################################################################

provider "aws" {
  region = var.primary_region

  default_tags {
    tags = local.common_tags
  }
}

# DR Region provider — used for cross-region replication & DR resources
provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = local.common_tags
  }
}

# US-East-1 provider — required for CloudFront ACM certificates & WAF
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = local.common_tags
  }
}
