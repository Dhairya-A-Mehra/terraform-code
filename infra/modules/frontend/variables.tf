variable "bucket_name" {
  description = "Frontend S3 bucket name"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of CloudFront distribution for OAC bucket policy"
  type        = string
}
