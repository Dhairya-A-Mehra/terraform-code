variable "function_name" {
  type = string
}

variable "lambda_zip_path" {
  type = string
}

variable "stream_arn" {
  type = string
}

variable "table_name" {
  type = string
}

variable "runtime" {
  default = "python3.11"
}


