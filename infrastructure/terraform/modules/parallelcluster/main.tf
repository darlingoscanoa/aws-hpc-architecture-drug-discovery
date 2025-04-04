# AWS ParallelCluster configuration for HPC infrastructure.

# Launch template for compute nodes
resource "aws_launch_template" "compute_node" {
  name_prefix   = "${var.project_name}-compute-"
  image_id      = "ami-0557a15b87f6559cf"  # Amazon Linux 2 with NVIDIA drivers
  instance_type = var.compute_node_instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.cluster.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.compute_node.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-efs-utils
              mkdir -p /shared
              mount -t efs ${aws_efs_file_system.shared.id}:/ /shared
              echo "${aws_efs_file_system.shared.id}:/ /shared efs defaults,_netdev 0 0" >> /etc/fstab
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-compute-node"
    }
  }
}

# Head node instance
resource "aws_instance" "head_node" {
  ami           = "ami-0557a15b87f6559cf"  # Amazon Linux 2 with NVIDIA drivers
  instance_type = var.head_node_instance_type
  subnet_id     = var.subnet_id
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.cluster.id]
  iam_instance_profile   = aws_iam_instance_profile.head_node.name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-efs-utils
              mkdir -p /shared
              mount -t efs ${aws_efs_file_system.shared.id}:/ /shared
              echo "${aws_efs_file_system.shared.id}:/ /shared efs defaults,_netdev 0 0" >> /etc/fstab
              
              # Install SLURM
              amazon-linux-extras install -y epel
              yum install -y munge munge-libs munge-devel
              yum install -y mariadb-server mariadb-devel
              yum install -y openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel man2html libibmad libibumad perl-ExtUtils-MakeMaker
              
              # Configure SLURM
              mkdir -p /etc/slurm
              cat > /etc/slurm/slurm.conf <<'EOL'
              ClusterName=hpc-cluster
              SlurmctldHost=${var.project_name}-head
              
              SlurmUser=slurm
              StateSaveLocation=/var/spool/slurm/ctld
              SlurmdSpoolDir=/var/spool/slurm/d
              
              SlurmctldPort=6817
              SlurmdPort=6818
              
              AuthType=auth/munge
              CryptoType=crypto/munge
              MpiDefault=none
              
              ProctrackType=proctrack/pgid
              ReturnToService=1
              
              SlurmctldPidFile=/var/run/slurmctld.pid
              SlurmdPidFile=/var/run/slurmd.pid
              
              SlurmdParameters=config_overrides
              
              # COMPUTE NODES
              NodeName=compute[1-${var.max_compute_nodes}] CPUs=${var.compute_node_vcpus} State=UNKNOWN
              PartitionName=gpu Nodes=compute[1-${var.max_compute_nodes}] Default=YES MaxTime=INFINITE State=UP
              EOL
              
              # Start SLURM services
              systemctl enable slurmctld
              systemctl start slurmctld
              EOF
  )

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-head-node"
  }
}

# Auto Scaling Group for compute nodes
resource "aws_autoscaling_group" "compute" {
  name                = "${var.project_name}-compute-asg"
  desired_capacity    = var.desired_compute_nodes
  max_size           = var.max_compute_nodes
  min_size           = var.min_compute_nodes
  target_group_arns  = []
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.compute_node.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-compute-node"
    propagate_at_launch = true
  }
}

# Security group for the cluster
resource "aws_security_group" "cluster" {
  name_prefix = "${var.project_name}-cluster-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6817
    to_port     = 6818
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-cluster-sg"
  }
}

# EFS for shared storage
resource "aws_efs_file_system" "shared" {
  creation_token = "${var.project_name}-shared-storage"
  encrypted      = true

  tags = {
    Name = "${var.project_name}-shared-storage"
  }
}

resource "aws_efs_mount_target" "shared" {
  file_system_id  = aws_efs_file_system.shared.id
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.cluster.id]
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

resource "aws_iam_role_policy" "cloudwatch_policy" {
  name = "${var.project_name}-cloudwatch-policy"
  role = aws_iam_role.compute_node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "head_node_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.head_node.name
}

resource "aws_iam_role_policy_attachment" "compute_node_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.compute_node.name
}