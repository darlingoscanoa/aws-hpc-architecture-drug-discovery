output "training_queue_arn" {
  description = "ARN of the training job queue"
  value       = aws_batch_job_queue.training.arn
}

output "inference_queue_arn" {
  description = "ARN of the inference job queue"
  value       = aws_batch_job_queue.inference.arn
}

output "training_job_definition_arn" {
  description = "ARN of the training job definition"
  value       = aws_batch_job_definition.training.arn
}

output "inference_job_definition_arn" {
  description = "ARN of the inference job definition"
  value       = aws_batch_job_definition.inference.arn
}
