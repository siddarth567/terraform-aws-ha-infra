variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the application container"
  type        = number
  default     = 80
}

variable "allowed_bastion_cidrs" {
  description = "CIDR blocks allowed to SSH into the bastion host"
  type        = list(string)
  default     = []
}

variable "create_bastion_sg" {
  description = "Whether to create bastion security group"
  type        = bool
  default     = true
}
