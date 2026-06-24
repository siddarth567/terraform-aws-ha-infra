output "primary_certificate_arn" {
  description = "ARN of the primary region ACM certificate"
  value       = aws_acm_certificate_validation.primary.certificate_arn
}

output "cloudfront_certificate_arn" {
  description = "ARN of the CloudFront ACM certificate (us-east-1)"
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}
