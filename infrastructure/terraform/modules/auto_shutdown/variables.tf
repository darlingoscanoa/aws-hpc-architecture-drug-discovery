# Variables for auto-shutdown module configuration.

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "shutdown_hour" {
  description = "Hour of the day to trigger shutdown (0-23)"
  type        = number
  default     = 22
}

variable "shutdown_threshold_hours" {
  description = "Number of hours of inactivity before shutdown"
  type        = number
  default     = 4
} 