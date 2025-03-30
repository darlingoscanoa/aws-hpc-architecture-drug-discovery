"""
FSx for Lustre filesystem configuration for high-performance storage.
"""

resource "aws_fsx_lustre_file_system" "fsx" {
  storage_capacity            = var.storage_capacity
  subnet_ids                 = var.subnet_ids
  deployment_type            = var.deployment_type
  storage_type               = var.storage_type
  security_group_ids         = var.security_group_ids
  weekly_maintenance_start_time = var.maintenance_start_time

  # Data repository configuration
  data_repository_configuration {
    data_repository_path = "s3://${var.s3_bucket_name}"
    imported_file_chunk_size = 1024
    auto_import_policy = {
      events = ["NEW", "CHANGED", "DELETED"]
    }
  }

  # Tags
  tags = {
    Name        = "${var.project_name}-${var.environment}-fsx"
    Environment = var.environment
  }
}

# Security group for FSx
resource "aws_security_group" "fsx" {
  name        = "${var.project_name}-${var.environment}-fsx-sg"
  description = "Security group for FSx for Lustre"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 988
    to_port     = 988
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-fsx-sg"
    Environment = var.environment
  }
} 