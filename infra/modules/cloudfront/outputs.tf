output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.frontend.id
}

output "distribution_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "distribution_url" {
  description = "CloudFront URL"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "distribution_arn" {
  description = "CloudFront distribution ARN for S3 bucket policy"
  value       = aws_cloudfront_distribution.frontend.arn
}
