variable "name_prefix" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "kms_key_arn" {
  type    = string
  default = ""
}

variable "assign_eip" {
  type    = bool
  default = true
}
