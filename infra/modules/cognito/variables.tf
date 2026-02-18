variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
  default     = "reviewpulse-user-pool"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

