# S3 bucket configuration for data storage.

# Create S3 bucket for HPC data
resource "aws_s3_bucket" "hpc_data" {
  bucket = "${var.project_name}-${var.environment}-data"

  # Enable versioning for data protection
  versioning {
    enabled = true
  }

  # Enable server-side encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # Lifecycle rules for cost optimization
  lifecycle_rule {
    id      = "data_lifecycle"
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 180
    }
  }

  # CORS configuration for web access
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-data"
    Environment = var.environment
  }
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

# Block public access
resource "aws_s3_bucket_public_access_block" "data_bucket" {
  bucket = aws_s3_bucket.hpc_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "hpc_data" {
  bucket = aws_s3_bucket.hpc_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "hpc_data" {
  bucket = aws_s3_bucket.hpc_data.id

  rule {
    id     = "archive_old_data"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }
  }
}

# Configure server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "hpc_data" {
  bucket = aws_s3_bucket.hpc_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
} 