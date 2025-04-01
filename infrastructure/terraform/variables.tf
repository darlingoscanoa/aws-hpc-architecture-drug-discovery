# Variables for the main Terraform configuration.

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hpc-drug-discovery"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "key_name" {
  description = "Name of the SSH key pair for cluster access"
  type        = string
  default     = "hpc-key"
}

variable "head_node_instance_type" {
  description = "EC2 instance type for the head node"
  type        = string
  default     = "g4dn.xlarge"
}

variable "compute_node_instance_type" {
  description = "EC2 instance type for compute nodes"
  type        = string
  default     = "g4dn.2xlarge"
}

variable "ami_id" {
  description = "AMI ID for cluster nodes"
  type        = string
  default     = "/aws/service/parallelcluster/3.7/alinux2/ami_id/latest"
}

variable "min_compute_nodes" {
  description = "Minimum number of compute nodes"
  type        = number
  default     = 0
}

variable "max_compute_nodes" {
  description = "Maximum number of compute nodes"
  type        = number
  default     = 10
}

variable "desired_compute_nodes" {
  description = "Desired number of compute nodes"
  type        = number
  default     = 2
}

variable "spot_price" {
  description = "Maximum spot price for compute nodes"
  type        = string
  default     = "1.00"
}

variable "fsx_storage_capacity" {
  description = "Storage capacity in GB for FSx"
  type        = number
  default     = 1200
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications"
  type        = string
  default     = ""
}

variable "shutdown_hour" {
  description = "Hour of the day to trigger shutdown (0-23)"
  type        = number
  default     = 18
}

variable "shutdown_threshold_hours" {
  description = "Number of hours of inactivity before shutdown"
  type        = number
  default     = 2
} 