# FSx for Lustre filesystem configuration for high-performance storage.

# Security group for FSx
resource "aws_security_group" "fsx" {
  name_prefix = "${var.project_name}-fsx-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 988
    to_port         = 988
    protocol        = "tcp"
    security_groups = var.security_group_ids
    self           = true
  }

  ingress {
    from_port       = 1021
    to_port         = 1023
    protocol        = "tcp"
    security_groups = var.security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-fsx-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create FSx for Lustre filesystem
resource "aws_fsx_lustre_file_system" "hpc" {
  storage_capacity    = var.storage_capacity
  subnet_ids         = [var.subnet_id]
  deployment_type    = "SCRATCH_2"
  security_group_ids = [aws_security_group.fsx.id]

  tags = {
    Name        = "${var.project_name}-fsx"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create data repository association with S3
# Removed data repository association as it's not supported with SCRATCH_2