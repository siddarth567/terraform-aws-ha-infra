output "app_key_arn" {
  description = "ARN of the application KMS key"
  value       = aws_kms_key.app.arn
}

output "app_key_id" {
  description = "ID of the application KMS key"
  value       = aws_kms_key.app.key_id
}

output "rds_key_arn" {
  description = "ARN of the RDS KMS key"
  value       = aws_kms_key.rds.arn
}

output "rds_key_id" {
  description = "ID of the RDS KMS key"
  value       = aws_kms_key.rds.key_id
}

output "logs_key_arn" {
  description = "ARN of the logs KMS key"
  value       = aws_kms_key.logs.arn
}

output "logs_key_id" {
  description = "ID of the logs KMS key"
  value       = aws_kms_key.logs.key_id
}
