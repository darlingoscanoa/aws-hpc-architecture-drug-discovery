# AWS ParallelCluster configuration for HPC infrastructure.

# Create ParallelCluster configuration
resource "aws_parallelcluster_cluster" "hpc" {
  cluster_name = "${var.project_name}-${var.environment}"
  
  head_node {
    instance_type = var.head_node_instance_type
    subnet_id     = var.subnet_id
    key_name      = var.key_name
    
    iam_instance_profile {
      name = aws_iam_instance_profile.head_node.name
    }
  }
  
  compute_resources {
    name                 = "compute"
    instance_type        = var.compute_node_instance_type
    min_count           = var.min_compute_nodes
    max_count           = var.max_compute_nodes
    desired_count       = var.desired_compute_nodes
    spot_price          = var.spot_price
    subnet_id           = var.subnet_id
    
    iam_instance_profile {
      name = aws_iam_instance_profile.compute_node.name
    }
  }
  
  shared_storage {
    name      = "fsx"
    type      = "fsx_lustre"
    mount_dir = "/fsx"
    
    fsx_lustre {
      deployment_type = "PERSISTENT_1"
      per_unit_storage_throughput = 200
      storage_capacity = var.fsx_storage_capacity
    }
  }
  
  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
  }
}

# Create IAM roles and instance profiles
resource "aws_iam_role" "head_node" {
  name = "${var.project_name}-head-node-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "compute_node" {
  name = "${var.project_name}-compute-node-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "head_node" {
  name = "${var.project_name}-head-node-profile"
  role = aws_iam_role.head_node.name
}

resource "aws_iam_instance_profile" "compute_node" {
  name = "${var.project_name}-compute-node-profile"
  role = aws_iam_role.compute_node.name
}

# Attach necessary policies
resource "aws_iam_role_policy_attachment" "head_node_s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.head_node.name
}

resource "aws_iam_role_policy_attachment" "compute_node_s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.compute_node.name
} 