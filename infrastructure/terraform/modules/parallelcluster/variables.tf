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
  description = "ID of the subnet for cluster deployment"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "head_node_instance_type" {
  description = "Instance type for head node"
  type        = string
}

variable "compute_node_instance_type" {
  description = "Instance type for compute nodes"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for cluster nodes"
  type        = string
}

variable "min_compute_nodes" {
  description = "Minimum number of compute nodes"
  type        = number
}

variable "max_compute_nodes" {
  description = "Maximum number of compute nodes"
  type        = number
}

variable "desired_compute_nodes" {
  description = "Desired number of compute nodes"
  type        = number
}

variable "spot_price" {
  description = "Maximum spot price for compute nodes"
  type        = number
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