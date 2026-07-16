variable "name_prefix" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1 for CloudFront). Leave empty to use CloudFront default certificate."
  type        = string
  default     = ""
}

variable "domain_aliases" {
  type    = list(string)
  default = []
}

variable "waf_acl_arn" {
  type    = string
  default = ""
}

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "geo_restriction_type" {
  type    = string
  default = "none"
}

variable "geo_restriction_locations" {
  type    = list(string)
  default = []
}

variable "origin_custom_header_value" {
  description = "Secret header value to verify traffic comes through CloudFront"
  type        = string
  default     = "cf-secret-header-value"
}
