output "zone_id" {
  value = local.zone_id
}

output "nameservers" {
  value = var.create_zone ? aws_route53_zone.this[0].name_servers : []
}

output "primary_health_check_id" {
  value = aws_route53_health_check.primary.id
}
