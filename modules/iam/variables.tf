variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = ""
}

variable "create_bastion_role" {
  description = "Whether to create bastion IAM role"
  type        = bool
  default     = true
}
