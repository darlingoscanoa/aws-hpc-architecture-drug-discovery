# Variables for CloudWatch module configuration.

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  type        = string
  default     = null
}

variable "fsx_id" {
  description = "ID of the FSx filesystem to monitor"
  type        = string
  default     = null
}