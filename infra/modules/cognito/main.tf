resource "aws_cognito_user_pool" "this" {
  name = var.user_pool_name

  # SMS MFA
  mfa_configuration = "ON"

  sms_configuration {
    external_id    = "${var.user_pool_name}-external"
    sns_caller_arn = aws_iam_role.cognito_sms_role.arn
  }

  sms_authentication_message = "Your ReviewPulse verification code is {####}"

  # Password policy
  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }

  # Auto verify email
  auto_verified_attributes = ["email"]

  # Schema
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  schema {
    name                = "brand_id"
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }

  tags = {
    Environment = "demo"
  }
}

# IAM role for Cognito to send SMS via SNS
resource "aws_iam_role" "cognito_sms_role" {
  name = "${var.user_pool_name}-sms-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "cognito-idp.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cognito_sms_policy" {
  role = aws_iam_role.cognito_sms_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "sns:Publish",
      Resource = "*"
    }]
  })
}

# App Client
resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.user_pool_name}-client"
  user_pool_id = aws_cognito_user_pool.this.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
  refresh_token_validity        = 7
}

# Admin group
resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "ReviewPulse internal admins"
}

# Brand group
resource "aws_cognito_user_group" "brand" {
  name         = "brand"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "Brand users — scoped to their own brand"
}
