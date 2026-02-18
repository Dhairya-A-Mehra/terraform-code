resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key

  # Primary key attribute
  attribute {
    name = var.hash_key
    type = "S"
  }

  # Additional attributes for GSI
  attribute {
    name = "product_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"
  }

  # Global Secondary Index
  global_secondary_index {
    name            = "product-created-index"
    hash_key        = "product_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  tags = {
    Environment = "demo"
  }
}
