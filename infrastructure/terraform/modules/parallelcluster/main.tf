# AWS ParallelCluster configuration for HPC infrastructure.

# Launch template for head node
resource "aws_launch_template" "head_node" {
  name_prefix   = "${var.project_name}-head-"
  image_id      = var.ami_id
  instance_type = var.head_node_instance_type

  network_interfaces {
    subnet_id = var.subnet_id
    security_groups = [aws_security_group.cluster.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.head_node.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # ParallelCluster head node setup
              yum install -y amazon-efs-utils
              # Additional setup commands
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-head"
      Environment = var.environment
    }
  }
}

# Launch template for compute nodes
resource "aws_launch_template" "compute_node" {
  name_prefix   = "${var.project_name}-compute-"
  image_id      = var.ami_id
  instance_type = var.compute_node_instance_type

  network_interfaces {
    subnet_id = var.subnet_id
    security_groups = [aws_security_group.cluster.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.compute_node.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # ParallelCluster compute node setup
              yum install -y amazon-efs-utils
              # Additional setup commands
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-compute"
      Environment = var.environment
    }
  }
}

# Auto Scaling Group for compute nodes
resource "aws_autoscaling_group" "compute_nodes" {
  name                = "${var.project_name}-compute"
  desired_capacity    = var.desired_compute_nodes
  max_size           = var.max_compute_nodes
  min_size           = var.min_compute_nodes
  vpc_zone_identifier = [var.subnet_id]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "capacity-optimized"
      spot_max_price                          = var.spot_price
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.compute_node.id
        version           = "$Latest"
      }
    }
  }

  tag {
    key                 = "Name"
    value              = "${var.project_name}-${var.environment}-compute"
    propagate_at_launch = true
  }
}

# Head node instance
resource "aws_instance" "head_node" {
  launch_template {
    id      = aws_launch_template.head_node.id
    version = "$Latest"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-head"
    Environment = var.environment
  }
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

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
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

# IAM roles and instance profiles
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

# IAM policies for the roles
resource "aws_iam_role_policy_attachment" "head_node_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.head_node.name
}

resource "aws_iam_role_policy_attachment" "compute_node_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.compute_node.name
}