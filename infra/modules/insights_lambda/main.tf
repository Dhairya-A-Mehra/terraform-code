resource "aws_lambda_function" "this" {
  function_name = "insights-service"

  handler = "handler.lambda_handler"
  runtime = "python3.11"

  role = var.lambda_role_arn

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }
}
