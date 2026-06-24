output "app_bucket_name" {
  value = aws_s3_bucket.app.bucket
}

output "app_bucket_arn" {
  value = aws_s3_bucket.app.arn
}

output "alb_logs_bucket_name" {
  value = aws_s3_bucket.alb_logs.bucket
}

output "alb_logs_bucket_arn" {
  value = aws_s3_bucket.alb_logs.arn
}

output "cloudtrail_bucket_name" {
  value = aws_s3_bucket.cloudtrail.bucket
}

output "cloudtrail_bucket_arn" {
  value = aws_s3_bucket.cloudtrail.arn
}
