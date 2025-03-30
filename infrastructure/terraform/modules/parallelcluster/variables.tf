"""
Variables for ParallelCluster module configuration.
"""

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where the cluster will be deployed"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair for cluster access"
  type        = string
}

variable "head_node_instance_type" {
  description = "EC2 instance type for the head node"
  type        = string
  default     = "c5.xlarge"
}

variable "compute_node_instance_type" {
  description = "EC2 instance type for compute nodes"
  type        = string
  default     = "hpc6a.48xlarge"
}

variable "ami_id" {
  description = "AMI ID for cluster nodes"
  type        = string
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
  default     = 1
}

variable "spot_price" {
  description = "Maximum spot price for compute nodes"
  type        = number
  default     = 0.0
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for cluster storage"
  type        = string
} 