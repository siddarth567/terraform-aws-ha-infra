variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "deletion_window_in_days" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}

variable "enable_multi_region" {
  description = "Enable multi-region KMS key for DR"
  type        = bool
  default     = false
}
