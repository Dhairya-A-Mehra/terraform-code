output "lambda_invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}

output "lambda_name" {
  value = aws_lambda_function.this.function_name

}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

