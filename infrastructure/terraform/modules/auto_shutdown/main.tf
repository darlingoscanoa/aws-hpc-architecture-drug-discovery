"""
Lambda function for automatic cluster shutdown to optimize costs.
"""

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-lambda-role"
    Environment = var.environment
  }
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-${var.environment}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "auto_shutdown" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-${var.environment}-auto-shutdown"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.8"
  timeout         = 300
  memory_size     = 128
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      CLUSTER_NAME = "${var.project_name}-${var.environment}"
      SHUTDOWN_THRESHOLD = var.shutdown_threshold_hours
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-auto-shutdown"
    Environment = var.environment
  }
}

# CloudWatch Event rule for scheduling
resource "aws_cloudwatch_event_rule" "shutdown_schedule" {
  name                = "${var.project_name}-${var.environment}-shutdown-schedule"
  description         = "Schedule for cluster auto-shutdown"
  schedule_expression = "cron(0 ${var.shutdown_hour} * * ? *)"
}

# CloudWatch Event target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.shutdown_schedule.name
  target_id = "AutoShutdownLambda"
  arn       = aws_lambda_function.auto_shutdown.arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_shutdown.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.shutdown_schedule.arn
}

# ZIP archive for Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/auto_shutdown.py"
  output_path = "${path.module}/lambda/auto_shutdown.zip"
} 