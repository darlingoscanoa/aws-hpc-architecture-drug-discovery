# Variables for ParallelCluster module configuration.

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for head node and EFS mount target"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for compute nodes"
  type        = list(string)
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "head_node_instance_type" {
  description = "Instance type for head node"
  type        = string
  default     = "c5.2xlarge"
}

variable "compute_node_instance_type" {
  description = "Instance type for compute nodes"
  type        = string
  default     = "g4dn.xlarge"
}

variable "compute_node_vcpus" {
  description = "Number of vCPUs per compute node for SLURM configuration"
  type        = number
  default     = 4  # g4dn.xlarge has 4 vCPUs
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
  default     = 0
}

variable "spot_price" {
  description = "Maximum spot price for compute nodes"
  type        = number
  default     = 1.0
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for cluster data"
  type        = string
}

variable "fsx_storage_capacity" {
  description = "Storage capacity in GB for FSx"
  type        = number
  default     = 1200
}

variable "aws_region" {
  description = "AWS region for the cluster"
  type        = string
  default     = "us-east-1"
}