# Outputs for the main Terraform configuration.

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "training_queue_arn" {
  description = "ARN of the training job queue"
  value       = module.batch.training_queue_arn
}

output "inference_queue_arn" {
  description = "ARN of the inference job queue"
  value       = module.batch.inference_queue_arn
}

output "training_job_definition_arn" {
  description = "ARN of the training job definition"
  value       = module.batch.training_job_definition_arn
}

output "inference_job_definition_arn" {
  description = "ARN of the inference job definition"
  value       = module.batch.inference_job_definition_arn
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.cloudwatch.dashboard_name
}