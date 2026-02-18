output "lambda_name" {
  description = "Name of the review service Lambda"
  value = aws_lambda_function.this.function_name
}

output "lambda_invoke_arn" {
  description = "ARN of the review service Lambda"
  value       = aws_lambda_function.this.invoke_arn
}

