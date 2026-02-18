resource "aws_dynamodb_table" "review_tokens" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "token_id"

  attribute {
    name = "token_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Environment = "dev"
    Project     = "Headphone-Reviews"
  }
}

