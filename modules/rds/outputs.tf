output "cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "cluster_id" {
  description = "ID of the Aurora cluster"
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the Aurora cluster"
  value       = aws_rds_cluster.this.arn
}

output "port" {
  description = "Database port"
  value       = aws_rds_cluster.this.port
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  value       = aws_secretsmanager_secret.db_password.arn
}
