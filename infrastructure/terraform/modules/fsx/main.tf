# FSx for Lustre filesystem configuration for high-performance storage.

# Create FSx for Lustre filesystem
resource "aws_fsx_lustre_file_system" "hpc" {
  storage_capacity              = var.storage_capacity
  subnet_id                     = var.subnet_ids[0]  # Use first subnet only
  deployment_type              = "SCRATCH_2"
  storage_type                 = "SSD"
  per_unit_storage_throughput = 1000
  security_groups             = [aws_security_group.fsx.id]
  automatic_backup_retention_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-fsx"
    Environment = var.environment
  }
}

# Create data repository association with S3
resource "aws_fsx_data_repository_association" "hpc" {
  file_system_id    = aws_fsx_lustre_file_system.hpc.id
  data_repository_path = "s3://${var.s3_bucket_name}"
  file_system_path    = "/data"

  tags = {
    Name        = "${var.project_name}-dra"
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