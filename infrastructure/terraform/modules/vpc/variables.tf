# Variables for VPC module configuration.

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones that support g3.4xlarge instances"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1c"]  # g3 instances are available in these AZs
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}