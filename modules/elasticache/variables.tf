variable "name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "engine_version" {
  type    = string
  default = "7.0"
}

variable "node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "num_cache_clusters" {
  type    = number
  default = 1
}

variable "parameter_group_family" {
  type    = string
  default = "redis7"
}

variable "subnet_group_name" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "kms_key_arn" {
  type    = string
  default = ""
}

variable "multi_az_enabled" {
  type    = bool
  default = false
}

variable "snapshot_retention_limit" {
  type    = number
  default = 1
}

variable "sns_topic_arn" {
  type    = string
  default = ""
}
