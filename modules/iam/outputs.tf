output "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

output "flow_logs_role_arn" {
  description = "ARN of the VPC Flow Logs role"
  value       = aws_iam_role.flow_logs.arn
}

output "cloudtrail_role_arn" {
  description = "ARN of the CloudTrail role"
  value       = aws_iam_role.cloudtrail.arn
}

output "bastion_instance_profile_name" {
  description = "Name of the bastion instance profile"
  value       = var.create_bastion_role ? aws_iam_instance_profile.bastion[0].name : ""
}

output "bastion_instance_profile_arn" {
  description = "ARN of the bastion instance profile"
  value       = var.create_bastion_role ? aws_iam_instance_profile.bastion[0].arn : ""
}
