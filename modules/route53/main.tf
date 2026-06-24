################################################################################
# Route53 Module — DNS with Health Checks and Failover Routing
################################################################################

# ─── Hosted Zone ──────────────────────────────────────────────────────────────

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0
  name  = var.domain_name

  tags = {
    Name = "${var.name_prefix}-zone"
  }
}

locals {
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : var.existing_zone_id
}

# ─── Health Check — Primary ALB ──────────────────────────────────────────────

resource "aws_route53_health_check" "primary" {
  fqdn              = var.primary_alb_dns
  port               = 443
  type               = "HTTPS"
  resource_path      = var.health_check_path
  failure_threshold  = 3
  request_interval   = 30
  measure_latency    = true

  tags = {
    Name = "${var.name_prefix}-primary-health-check"
  }
}

# ─── Health Check — DR ALB (if DR enabled) ───────────────────────────────────

resource "aws_route53_health_check" "dr" {
  count = var.enable_dr ? 1 : 0

  fqdn              = var.dr_alb_dns
  port               = 443
  type               = "HTTPS"
  resource_path      = var.health_check_path
  failure_threshold  = 3
  request_interval   = 30
  measure_latency    = true

  tags = {
    Name = "${var.name_prefix}-dr-health-check"
  }
}

# ─── CloudFront Alias Record ─────────────────────────────────────────────────

resource "aws_route53_record" "cloudfront" {
  count = var.create_cloudfront_record ? 1 : 0

  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = true
  }
}

# ─── Failover Records (Primary + Secondary) ─────────────────────────────────

resource "aws_route53_record" "primary" {
  count = var.enable_failover ? 1 : 0

  zone_id = local.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = var.primary_alb_dns
    zone_id                = var.primary_alb_zone_id
    evaluate_target_health = true
  }

  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id
}

resource "aws_route53_record" "secondary" {
  count = var.enable_failover && var.enable_dr ? 1 : 0

  zone_id = local.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.dr_alb_dns
    zone_id                = var.dr_alb_zone_id
    evaluate_target_health = true
  }

  set_identifier  = "secondary"
  health_check_id = aws_route53_health_check.dr[0].id
}
