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

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "hpc-key"
}

variable "head_node_instance_type" {
  description = "Instance type for head node"
  type        = string
  default     = "c5.xlarge"
}

variable "compute_node_instance_type" {
  description = "Instance type for compute nodes"
  type        = string
  default     = "g3.4xlarge"  # GPU instance with NVIDIA V100 GPU, better for ML/AI workloads
}

variable "min_compute_nodes" {
  description = "Minimum number of compute nodes"
  type        = number
  default     = 0
}

variable "max_compute_nodes" {
  description = "Maximum number of compute nodes"
  type        = number
  default     = 1
}

variable "desired_compute_nodes" {
  description = "Desired number of compute nodes"
  type        = number
  default     = 1
}

variable "fsx_storage_capacity" {
  description = "Storage capacity in GB for FSx"
  type        = number
  default     = 1200
}

variable "shutdown_hour" {
  description = "Hour when the cluster should automatically shut down (UTC)"
  type        = number
  default     = 22
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
  default     = null
}