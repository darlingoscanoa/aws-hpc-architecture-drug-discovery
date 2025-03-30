"""
Variables for FSx module configuration.
"""

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "storage_capacity" {
  description = "Storage capacity in GB"
  type        = number
  default     = 1200
}

variable "subnet_ids" {
  description = "List of subnet IDs where FSx will be deployed"
  type        = list(string)
}

variable "deployment_type" {
  description = "FSx deployment type"
  type        = string
  default     = "SCRATCH_2"
}

variable "storage_type" {
  description = "FSx storage type"
  type        = string
  default     = "SSD"
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "maintenance_start_time" {
  description = "Weekly maintenance start time"
  type        = string
  default     = "1:00:00"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for data repository"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
} 