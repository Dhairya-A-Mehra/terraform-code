variable "bucket_domain_name" {
  description = "S3 bucket domain name"
  type        = string
}

variable "origin_id" {
  description = "CloudFront origin ID"
  type        = string
  default     = "s3-origin"
}

