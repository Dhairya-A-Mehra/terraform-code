module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name = "demo-app-table"
}

module "lambda" {
  source = "../../modules/lambda"

  function_name   = "demo-app-lambda"
  lambda_zip_path = "../../lambda-code/function.zip"
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  api_name     = "review-platform-api"
  lambda_arn   = module.lambda.lambda_arn
  lambda_name  = module.lambda.lambda_name

  route_key   = "POST /feedback"

  review_service_lambda_invoke_arn = module.review_service.lambda_invoke_arn
  review_service_lambda_name = module.review_service.lambda_name

  insights_lambda_invoke_arn = module.insights_lambda.lambda_invoke_arn
  insights_lambda_name       = module.insights_lambda.lambda_name
}

output "api_url" {
  value = module.api_gateway.api_endpoint
}

module "frontend" {
  source = "../../modules/frontend"

  bucket_name = "demo-app-frontend-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

output "website_url" {
  value = module.frontend.website_url
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  bucket_domain_name = module.frontend.bucket_domain_name
}

output "cdn_url" {
  value = module.cloudfront.distribution_url
}

module "monitoring" {
  source = "../../modules/monitoring"

  lambda_name = module.lambda.lambda_name
}

module "processor_lambda" {
  source = "../../modules/processor_lambda"

  function_name   = "feedback-processor"
  lambda_zip_path = "../../lambda-code/processor.zip"

  stream_arn  = module.dynamodb.stream_arn
  table_name  = module.dynamodb.table_name
}

module "review_tokens" {
  source = "../../modules/review_tokens"
}

module "review_service" {
  source = "../../modules/review_service"

  function_name        = "review-service"
  lambda_zip_path      = "../../lambda-code/review_service.zip"
  review_tokens_table  = module.review_tokens.review_tokens_table_name
  feedback_table       = module.dynamodb.table_name
}

