output "cluster_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.this.address
}

output "reader_endpoint" {
  description = "Endpoint of the RDS instance (same as writer for standard RDS)"
  value       = aws_db_instance.this.address
}

output "cluster_id" {
  description = "Identifier of the RDS instance"
  value       = aws_db_instance.this.identifier
}

output "cluster_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "port" {
  description = "Database port"
  value       = aws_db_instance.this.port
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  value       = aws_secretsmanager_secret.db_password.arn
}
