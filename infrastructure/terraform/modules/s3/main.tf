# S3 bucket configuration for data storage.

# Create S3 bucket for HPC data
resource "aws_s3_bucket" "hpc_data" {
  bucket = "${var.project_name}-${var.environment}-data"

  tags = {
    Name        = "${var.project_name}-${var.environment}-data"
    Environment = var.environment
  }
}

# Server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "hpc_data" {
  bucket = aws_s3_bucket.hpc_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "hpc_data" {
  bucket = aws_s3_bucket.hpc_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "hpc_data" {
  bucket = aws_s3_bucket.hpc_data.id

  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Bucket public access block
resource "aws_s3_bucket_public_access_block" "hpc_data" {
  bucket = aws_s3_bucket.hpc_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy for secure access
resource "aws_s3_bucket_policy" "data_bucket_policy" {
  bucket = aws_s3_bucket.hpc_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.hpc_data.arn,
          "${aws_s3_bucket.hpc_data.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}