# Variables for the main Terraform configuration.

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

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
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

variable "shutdown_hour" {
  description = "Hour when the cluster should automatically shut down (UTC)"
  type        = number
  default     = 22
}