output "primary_endpoint" {
  description = "Primary endpoint address of the Redis cluster"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Reader endpoint address of the Redis cluster"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.this.port
}

output "auth_token_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Redis auth token"
  value       = aws_secretsmanager_secret.redis_auth.arn
}
