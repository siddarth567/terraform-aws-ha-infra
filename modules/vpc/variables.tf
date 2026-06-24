################################################################################
# VPC Module — Variables
################################################################################

variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways (1 for dev, 3 for prod)"
  type        = number
  default     = 1
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_role_arn" {
  description = "IAM role ARN for VPC Flow Logs"
  type        = string
  default     = ""
}

variable "flow_log_retention_days" {
  description = "Retention period for flow logs in CloudWatch"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting logs"
  type        = string
  default     = ""
}
