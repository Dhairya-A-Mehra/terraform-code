variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "lambda_zip_path" {
  description = "Path to lambda zip file"
  type        = string
}

variable "runtime" {
  default = "python3.11"
}

