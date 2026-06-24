variable "name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "kms_key_arn" {
  type    = string
  default = ""
}

variable "log_retention_days" {
  type    = number
  default = 90
}

variable "enable_replication" {
  type    = bool
  default = false
}

variable "dr_bucket_arn" {
  type    = string
  default = ""
}
