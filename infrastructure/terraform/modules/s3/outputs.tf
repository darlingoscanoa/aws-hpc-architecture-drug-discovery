# Outputs for the S3 module.

output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.hpc_data.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.hpc_data.arn
}

output "bucket_region" {
  description = "Region where the bucket is created"
  value       = aws_s3_bucket.data_bucket.region
} 