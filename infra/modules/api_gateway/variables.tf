variable "api_name" {
  description = "Name of API Gateway"
  type        = string
}

variable "lambda_arn" {
  description = "Lambda invoke ARN"
  type        = string
}

variable "lambda_name" {
  description = "Lambda function name"
  type        = string
}

variable "route_key" {
  description = "HTTP route"
  type        = string
  default     = "GET /demo"
}

variable "review_service_lambda_invoke_arn" {
  type = string
}

variable "review_service_lambda_name" {
  type = string
}



