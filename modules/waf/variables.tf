variable "name_prefix" {
  type = string
}

variable "scope" {
  description = "CLOUDFRONT or REGIONAL"
  type        = string
  default     = "CLOUDFRONT"
}

variable "rate_limit" {
  description = "Rate limit per 5-minute period per IP"
  type        = number
  default     = 2000
}

variable "log_retention_days" {
  type    = number
  default = 30
}
