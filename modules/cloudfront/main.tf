################################################################################
# CloudFront Module — CDN Distribution with ALB Origin
################################################################################

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.name_prefix} CDN distribution"
  default_root_object = ""
  price_class         = var.price_class
  aliases             = var.domain_aliases
  web_acl_id          = var.waf_acl_arn

  # ALB Origin
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 60
    }

    custom_header {
      name  = "X-Custom-Header"
      value = var.origin_custom_header_value
    }
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "alb-origin"

    forwarded_values {
      query_string = true
      headers      = ["Host", "Origin", "Authorization"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 86400
    compress               = true
  }

  # SSL Certificate
  dynamic "viewer_certificate" {
    for_each = var.certificate_arn != "" ? [1] : []
    content {
      acm_certificate_arn      = var.certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.certificate_arn != "" ? [] : [1]
    content {
      cloudfront_default_certificate = true
    }
  }

  # Geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # Custom error responses
  custom_error_response {
    error_code            = 503
    response_code         = 503
    response_page_path    = "/error/503.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 502
    response_code         = 502
    response_page_path    = "/error/502.html"
    error_caching_min_ttl = 10
  }

  tags = {
    Name = "${var.name_prefix}-cdn"
  }
}
