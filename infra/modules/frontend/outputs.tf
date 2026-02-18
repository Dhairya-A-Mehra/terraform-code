output "bucket_domain_name" {
  value = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "website_url" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}

