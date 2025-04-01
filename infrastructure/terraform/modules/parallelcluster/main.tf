# AWS ParallelCluster configuration for HPC infrastructure.

# Create ParallelCluster configuration
resource "aws_parallelcluster" "hpc" {
  name = "${var.project_name}-${var.environment}-cluster"
  cluster_configuration = jsonencode({
    HeadNode = {
      InstanceType = var.head_node_instance_type
      Networking = {
        SubnetId = var.subnet_id
        SecurityGroups = [aws_security_group.cluster.id]
      }
      Ssh = {
        KeyName = var.key_name
      }
    }
    ComputeResources = {
      Name = "ComputeFleet"
      InstanceType = var.compute_node_instance_type
      MinCount = var.min_compute_nodes
      MaxCount = var.max_compute_nodes
      DesiredCount = var.desired_compute_nodes
      SpotPrice = var.spot_price
    }
    SharedStorage = {
      Name = "Shared"
      StorageType = "FsxLustre"
      MountDir = "/shared"
      FsxLustreSettings = {
        StorageCapacity = 1200
        DeploymentType = "SCRATCH_2"
        StorageType = "SSD"
      }
    }
    Region = var.aws_region
    Image = {
      Os = "alinux2"
      CustomAmi = var.ami_id
    }
    Tags = {
      Name = "${var.project_name}-${var.environment}-cluster"
      Environment = var.environment
    }
  })
}

# Security group for the cluster
resource "aws_security_group" "cluster" {
  name_prefix = "${var.project_name}-${var.environment}-cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster"
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