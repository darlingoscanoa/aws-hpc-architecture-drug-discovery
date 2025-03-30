"""
Outputs for the auto-shutdown module.
"""

output "lambda_function_name" {
  description = "Name of the auto-shutdown Lambda function"
  value       = aws_lambda_function.auto_shutdown.function_name
}

output "lambda_function_arn" {
  description = "ARN of the auto-shutdown Lambda function"
  value       = aws_lambda_function.auto_shutdown.arn
}

output "cloudwatch_event_rule_name" {
  description = "Name of the CloudWatch Event rule"
  value       = aws_cloudwatch_event_rule.shutdown_schedule.name
} 