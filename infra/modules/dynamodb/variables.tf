variable "table_name" {
  description = "Name of DynamoDB table"
  type        = string
}

variable "hash_key" {
  description = "Primary key name"
  type        = string
  default     = "id"
}

