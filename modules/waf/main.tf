################################################################################
# WAF v2 Module — Web Application Firewall with Managed Rules
################################################################################

resource "aws_wafv2_web_acl" "this" {
  name        = "${var.name_prefix}-waf"
  description = "WAF for ${var.name_prefix}"
  scope       = var.scope # "CLOUDFRONT" or "REGIONAL"

  default_action {
    allow {}
  }

  # ─── AWS Managed Rules: Common Rule Set ────────────────────────────────────

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # ─── AWS Managed Rules: Known Bad Inputs ───────────────────────────────────

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # ─── AWS Managed Rules: SQL Injection ──────────────────────────────────────

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-sqli-rules"
      sampled_requests_enabled   = true
    }
  }

  # ─── AWS Managed Rules: Linux Protection ──────────────────────────────────

  rule {
    name     = "AWSManagedRulesLinuxRuleSet"
    priority = 40

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-linux-rules"
      sampled_requests_enabled   = true
    }
  }

  # ─── Rate Limiting Rule ───────────────────────────────────────────────────

  rule {
    name     = "RateLimitRule"
    priority = 50

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.name_prefix}-waf"
  }
}

# ─── CloudWatch Logging for WAF ──────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.name_prefix}-waf-logs"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  resource_arn            = aws_wafv2_web_acl.this.arn
}
