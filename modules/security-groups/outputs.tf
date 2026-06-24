output "alb_sg_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "ecs_sg_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs.id
}

output "rds_sg_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}

output "redis_sg_id" {
  description = "Security group ID for Redis"
  value       = aws_security_group.redis.id
}

output "bastion_sg_id" {
  description = "Security group ID for Bastion host"
  value       = var.create_bastion_sg ? aws_security_group.bastion[0].id : ""
}
