resource "aws_apigatewayv2_api" "this" {
  name          = var.api_name
  protocol_type = "HTTP"
}

############################################
# 1️⃣ Review Service Integration
############################################

resource "aws_apigatewayv2_integration" "review_service" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.review_service_lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# POST /simulate-purchase — PUBLIC
resource "aws_apigatewayv2_route" "simulate_purchase" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /simulate-purchase"

  target = "integrations/${aws_apigatewayv2_integration.review_service.id}"
}

# GET /review — PUBLIC
resource "aws_apigatewayv2_route" "review_validate" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /review"

  target = "integrations/${aws_apigatewayv2_integration.review_service.id}"
}

# POST /submit-review — PUBLIC
resource "aws_apigatewayv2_route" "submit_review" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /submit-review"

  target = "integrations/${aws_apigatewayv2_integration.review_service.id}"
}

############################################
# 2️⃣ Default Stage
############################################

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn

    format = jsonencode({
      requestId      = "$context.requestId"
      status         = "$context.status"
      latency        = "$context.responseLatency"
      routeKey       = "$context.routeKey"
      integrationErr = "$context.integrationErrorMessage"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 5000
    throttling_rate_limit    = 10000
  }
}

############################################
# 3️⃣ JWT Authorizer (Cognito)
############################################

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-jwt-authorizer"

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = var.cognito_user_pool_endpoint
  }
}

############################################
# 4️⃣ Lambda Permissions
############################################

# Permission for Review Service Lambda
resource "aws_lambda_permission" "allow_review_service_api" {
  statement_id  = "AllowAPIGatewayInvokeReview"
  action        = "lambda:InvokeFunction"
  function_name = var.review_service_lambda_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

############################################
# 5️⃣ CloudWatch Logs
############################################

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "review_service_lambda_logs" {
  name              = "/aws/lambda/${var.review_service_lambda_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "insights_lambda_logs" {
  name              = "/aws/lambda/${var.insights_lambda_name}"
  retention_in_days = 14
}

############################################
# 6️⃣ Insights Integration — PROTECTED
############################################

resource "aws_apigatewayv2_integration" "insights" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.insights_lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# GET /insights — PROTECTED (JWT Required)
resource "aws_apigatewayv2_route" "insights" {
  api_id               = aws_apigatewayv2_api.this.id
  route_key            = "GET /insights"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito.id
  authorization_scopes = ["aws.cognito.signin.user.admin"]

  target = "integrations/${aws_apigatewayv2_integration.insights.id}"
}

resource "aws_lambda_permission" "allow_insights_api" {
  statement_id  = "AllowAPIGatewayInvokeInsights"
  action        = "lambda:InvokeFunction"
  function_name = var.insights_lambda_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
