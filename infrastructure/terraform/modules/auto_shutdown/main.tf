# Lambda function for automatic cluster shutdown to optimize costs.

# Auto-shutdown Lambda function
resource "aws_lambda_function" "auto_shutdown" {
  filename         = "${path.module}/lambda/auto_shutdown.zip"
  function_name    = "${var.project_name}-auto-shutdown"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      SHUTDOWN_HOUR = var.shutdown_hour
      THRESHOLD_HOURS = var.shutdown_threshold_hours
    }
  }

  tags = {
    Name        = "${var.project_name}-auto-shutdown"
    Environment = var.environment
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-auto-shutdown-role"

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
}

# Custom policy for EC2 control
resource "aws_iam_role_policy" "lambda_ec2" {
  name = "${var.project_name}-ec2-control"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "ec2:StartInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# CloudWatch Event Rule
resource "aws_cloudwatch_event_rule" "auto_shutdown" {
  name                = "${var.project_name}-auto-shutdown"
  description         = "Trigger auto-shutdown Lambda function"
  schedule_expression = "cron(0 * * * ? *)"  # Run every hour
}

# Create CloudWatch Event Target
resource "aws_cloudwatch_event_target" "auto_shutdown" {
  rule      = aws_cloudwatch_event_rule.auto_shutdown.name
  target_id = "AutoShutdownLambda"
  arn       = aws_lambda_function.auto_shutdown.arn
}