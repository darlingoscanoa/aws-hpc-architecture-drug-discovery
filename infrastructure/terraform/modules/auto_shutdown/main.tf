# Lambda function for automatic cluster shutdown to optimize costs.

# Create Lambda function
resource "aws_lambda_function" "auto_shutdown" {
  filename         = "auto_shutdown.zip"
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

# Create IAM role for Lambda
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

# Attach necessary policies
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_parallelcluster" {
  policy_arn = "arn:aws:iam::aws:policy/AWSParallelClusterFullAccess"
  role       = aws_iam_role.lambda_role.name
}

# Create CloudWatch Event Rule
resource "aws_cloudwatch_event_rule" "auto_shutdown" {
  name                = "${var.project_name}-auto-shutdown"
  description         = "Trigger auto-shutdown Lambda function"
  schedule_expression = "cron(0 ${var.shutdown_hour} * * ? *)"
}

# Create CloudWatch Event Target
resource "aws_cloudwatch_event_target" "auto_shutdown" {
  rule      = aws_cloudwatch_event_rule.auto_shutdown.name
  target_id = "auto_shutdown"
  arn       = aws_lambda_function.auto_shutdown.arn
} 