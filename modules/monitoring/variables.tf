variable "name_prefix" {
  type = string
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "kms_key_id" {
  type    = string
  default = ""
}

variable "kms_key_arn" {
  type    = string
  default = ""
}

variable "log_retention_days" {
  type    = number
  default = 90
}

variable "cloudtrail_bucket_name" {
  type = string
}

variable "cloudtrail_role_arn" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "rds_cluster_id" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}
