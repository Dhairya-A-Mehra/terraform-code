variable "function_name" {
  type = string
}

variable "lambda_zip_path" {
  type = string
}

variable "review_tokens_table" {
  type = string
}

variable "feedback_table" {
  type = string
}

variable "frontend_url" {
  description = "CloudFront URL for review links"
  type        = string
}

variable "sender_email" {
  description = "Verified SES sender email"
  type        = string
}

