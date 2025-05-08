# Variables for the main Terraform configuration

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hpc-drug-discovery"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "persistent_bucket_name" {
  description = "Name of the existing S3 bucket for persistent storage"
  type        = string
  default     = "drug-discovery-persistent-storage"
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
  default     = null
}