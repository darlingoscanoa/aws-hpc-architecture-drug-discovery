# Variables for ParallelCluster module configuration.

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (e.g. dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for head node"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for compute nodes"
  type        = list(string)
}

variable "ssh_public_key" {
  description = "SSH public key content for the instances"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "head_node_instance_type" {
  description = "Instance type for head node"
  type        = string
  default     = "t2.micro"  # Most basic instance type
}

variable "compute_node_instance_type" {
  description = "Instance type for compute nodes"
  type        = string
  default     = "t2.micro"  # Most basic instance type
}

variable "compute_node_vcpus" {
  description = "Number of vCPUs per compute node"
  type        = number
  default     = 1  # t2.micro has 1 vCPU
}

variable "ami_id" {
  description = "AMI ID for cluster nodes"
  type        = string
  default     = "ami-0557a15b87f6559cf"  # Amazon Linux 2 AMI
}

variable "min_compute_nodes" {
  description = "Minimum number of compute nodes"
  type        = number
  default     = 0
}

variable "max_compute_nodes" {
  description = "Maximum number of compute nodes"
  type        = number
  default     = 1  # Single compute node for testing
}

variable "desired_compute_nodes" {
  description = "Desired number of compute nodes"
  type        = number
  default     = 0
}

variable "spot_price" {
  description = "Spot price for compute nodes"
  type        = string
  default     = null
}

variable "s3_bucket_name" {
  description = "Name of S3 bucket for data storage"
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