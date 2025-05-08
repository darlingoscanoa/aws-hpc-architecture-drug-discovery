variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Batch compute environment"
  type        = list(string)
}

variable "s3_bucket_name" {
  description = "Name of the existing S3 bucket for storage"
  type        = string
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository containing the training/inference container"
  type        = string
}
