resource "aws_apigatewayv2_api" "this" {
  name          = var.api_name
  protocol_type = "HTTP"
}

############################################
# 1️⃣ Primary Lambda Integration (Existing)
############################################

#resource "aws_apigatewayv2_integration" "primary_lambda" {
 # api_id                 = aws_apigatewayv2_api.this.id
  #integration_type       = "AWS_PROXY"
  #integration_uri        = var.lambda_arn
  #integration_method     = "POST"
  #payload_format_version = "2.0"
#}

#resource "aws_apigatewayv2_route" "primary_route" {
#  api_id    = aws_apigatewayv2_api.this.id
#  route_key = var.route_key
#
#  target = "integrations/${aws_apigatewayv2_integration.primary_lambda.id}"
#}

############################################
# 2️⃣ Review Service Integration
############################################

resource "aws_apigatewayv2_integration" "review_service" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.review_service_lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}


# POST /simulate-purchase
resource "aws_apigatewayv2_route" "simulate_purchase" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /simulate-purchase"

  target = "integrations/${aws_apigatewayv2_integration.review_service.id}"
}

# GET /review
resource "aws_apigatewayv2_route" "review_validate" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /review"

  target = "integrations/${aws_apigatewayv2_integration.review_service.id}"
}

# POST /submit-review
resource "aws_apigatewayv2_route" "submit_review" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /submit-review"

  target = "integrations/${aws_apigatewayv2_integration.review_service.id}"
}

############################################
# 3️⃣ Default Stage
############################################

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn

    format = jsonencode({
      requestId = "$context.requestId"
      status    = "$context.status"
      latency   = "$context.responseLatency"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = true
  }
}

############################################
# 4️⃣ Lambda Permissions
############################################

# Permission for Primary Lambda
#resource "aws_lambda_permission" "allow_primary_api" {
#  statement_id  = "AllowAPIGatewayInvokePrimary"
#  action        = "lambda:InvokeFunction"
#  function_name = var.lambda_name
#  principal     = "apigateway.amazonaws.com"
#
#  source_arn = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
#}

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

