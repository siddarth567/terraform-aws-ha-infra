variable "name_prefix" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "create_zone" {
  type    = bool
  default = true
}

variable "existing_zone_id" {
  type    = string
  default = ""
}

variable "primary_alb_dns" {
  type = string
}

variable "primary_alb_zone_id" {
  type = string
}

variable "dr_alb_dns" {
  type    = string
  default = ""
}

variable "dr_alb_zone_id" {
  type    = string
  default = ""
}

variable "cloudfront_domain_name" {
  type    = string
  default = ""
}

variable "cloudfront_hosted_zone_id" {
  type    = string
  default = ""
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "enable_dr" {
  type    = bool
  default = false
}

variable "enable_failover" {
  type    = bool
  default = false
}

variable "create_cloudfront_record" {
  type    = bool
  default = true
}
