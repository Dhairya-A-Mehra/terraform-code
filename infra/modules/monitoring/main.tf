variable "lambda_name" {
  type = string
}

resource "aws_cloudwatch_dashboard" "app_dashboard" {
  dashboard_name = "serverless-app-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ],
          period = 300,
          stat   = "Sum",
          region = "us-east-1",
          title  = "Lambda Metrics"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "lambda-error-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    FunctionName = var.lambda_name
  }

  alarm_description = "Triggers when Lambda errors occur"
}

