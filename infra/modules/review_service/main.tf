resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "dynamodb_policy" {
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["ses:SendEmail", "ses:SendRawEmail"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  runtime          = "python3.11"
  handler          = "handler.lambda_handler"
  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  role             = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      REVIEW_TOKENS_TABLE = var.review_tokens_table
      FEEDBACK_TABLE      = var.feedback_table
      FRONTEND_URL        = var.frontend_url
      SENDER_EMAIL        = var.sender_email
    }
  }
}

