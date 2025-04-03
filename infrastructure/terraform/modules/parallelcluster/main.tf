# AWS ParallelCluster configuration for HPC infrastructure.

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
              yum install -y amazon-efs-utils nvidia-driver
              # Mount shared storage
              mkdir -p /shared
              mount -t nfs4 ${aws_efs_file_system.shared.dns_name}:/ /shared
              # GPU setup for ML workloads
              nvidia-smi -pm 1
              EOF
  )

  tags = {
    Name        = "${var.project_name}-${var.environment}-compute"
    Environment = var.environment
  }

  monitoring {
    enabled = true
  }
}

# Head node instance
resource "aws_instance" "head_node" {
  ami           = var.ami_id
  instance_type = var.head_node_instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [aws_security_group.cluster.id]
  iam_instance_profile = aws_iam_instance_profile.head_node.name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Install required packages
              yum install -y amazon-efs-utils nvidia-driver slurm
              
              # Mount shared storage
              mkdir -p /shared
              mount -t nfs4 ${aws_efs_file_system.shared.dns_name}:/ /shared
              
              # Configure SLURM
              cat > /etc/slurm/slurm.conf <<'EOL'
              ClusterName=${var.project_name}
              SlurmctldHost=$(hostname)
              
              # Node configurations
              NodeName=compute[1-${var.max_compute_nodes}] CPUs=${var.compute_node_vcpus} State=UNKNOWN
              PartitionName=gpu Nodes=compute[1-${var.max_compute_nodes}] Default=YES MaxTime=INFINITE State=UP
              EOL
              
              # Start SLURM services
              systemctl enable --now slurmctld
              EOF
  )

  tags = {
    Name        = "${var.project_name}-${var.environment}-head"
    Environment = var.environment
  }

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
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

# Shared Storage - EFS for HPC workloads
resource "aws_efs_file_system" "shared" {
  creation_token = "${var.project_name}-shared-storage"
  performance_mode = "maxIO"
  throughput_mode = "provisioned"
  provisioned_throughput_in_mibps = 1024

  tags = {
    Name        = "${var.project_name}-shared"
    Environment = var.environment
  }
}

resource "aws_efs_mount_target" "shared" {
  file_system_id = aws_efs_file_system.shared.id
  subnet_id      = var.subnet_id
  security_groups = [aws_security_group.cluster.id]
}

# CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "hpc" {
  dashboard_name = "${var.project_name}-metrics"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.compute_nodes.name],
            ["AWS/EC2", "GPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.compute_nodes.name]
          ]
          period = 300
          stat   = "Average"
          title  = "Cluster Resource Utilization"
        }
      }
    ]
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

  ingress {
    from_port   = 6817
    to_port     = 6819
    protocol    = "tcp"
    self        = true
    description = "Slurm"
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self        = true
    description = "NFS"
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

# IAM policies
resource "aws_iam_role_policy_attachment" "head_node_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.head_node.name
}

resource "aws_iam_role_policy_attachment" "compute_node_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.compute_node.name
}

resource "aws_iam_role_policy" "cloudwatch_policy" {
  name = "${var.project_name}-cloudwatch-policy"
  role = aws_iam_role.compute_node.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}