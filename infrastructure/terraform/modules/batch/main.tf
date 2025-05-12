resource "aws_batch_compute_environment" "gpu" {
  compute_environment_name = "${var.project_name}-gpu"
  service_role            = aws_iam_role.batch_service_role.arn

  compute_resources {
    max_vcpus = 4
    min_vcpus = 0

    instance_type = [
      "g4dn.xlarge"
    ]

    security_group_ids = [aws_security_group.batch.id]
    subnets           = var.subnet_ids
    type              = "EC2"

    instance_role = aws_iam_instance_profile.batch_instance_role.arn
  }

  type = "MANAGED"
}

resource "aws_batch_job_queue" "training" {
  name     = "${var.project_name}-training"
  state    = "ENABLED"
  priority = 100

  compute_environments = [
    aws_batch_compute_environment.gpu.arn
  ]
}

resource "aws_batch_job_queue" "inference" {
  name     = "${var.project_name}-inference"
  state    = "ENABLED"
  priority = 50

  compute_environments = [
    aws_batch_compute_environment.gpu.arn
  ]
}

resource "aws_batch_job_definition" "training" {
  name = "${var.project_name}-training"
  type = "container"
  platform_capabilities = ["EC2"]

  container_properties = jsonencode({
    image = "${var.ecr_repository_url}:latest"
    command = ["train"]
    resourceRequirements = [
      {
        type  = "VCPU"
        value = "4"
      },
      {
        type  = "MEMORY"
        value = "16384"
      },
      {
        type  = "GPU"
        value = "1"
      }
    ]
    environment = [
      {
        name  = "S3_BUCKET"
        value = var.s3_bucket_name
      },
      {
        name  = "AWS_DEFAULT_REGION"
        value = data.aws_region.current.name
      }
    ]
    executionRoleArn = aws_iam_role.batch_execution_role.arn
    jobRoleArn      = aws_iam_role.batch_job_role.arn
  })
}

resource "aws_batch_job_definition" "inference" {
  name = "${var.project_name}-inference"
  type = "container"
  platform_capabilities = ["EC2"]

  container_properties = jsonencode({
    image = "${var.ecr_repository_url}-inference:latest"
    command = ["streamlit", "run", "src/inference/predict.py"]
    resourceRequirements = [
      {
        type  = "VCPU"
        value = "4"
      },
      {
        type  = "MEMORY"
        value = "16384"
      },
      {
        type  = "GPU"
        value = "1"
      }
    ]
    environment = [
      {
        name  = "S3_BUCKET"
        value = var.s3_bucket_name
      },
      {
        name  = "AWS_DEFAULT_REGION"
        value = data.aws_region.current.name
      },
      {
        name  = "PORT"
        value = "8501"
      }
    ]
    executionRoleArn = aws_iam_role.batch_execution_role.arn
    jobRoleArn      = aws_iam_role.batch_job_role.arn
    networkConfiguration = {
      assignPublicIp = "ENABLED"
    }
    portMappings = [
      {
        containerPort = 8501
        hostPort = 8501
        protocol = "tcp"
      }
    ]
  })
}

# IAM roles for job execution
resource "aws_iam_role" "batch_execution_role" {
  name = "${var.project_name}-batch-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "batch_job_role" {
  name = "${var.project_name}-batch-job-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Add required policies
resource "aws_iam_role_policy" "batch_job_s3" {
  name = "${var.project_name}-s3-access"
  role = aws_iam_role.batch_job_role.name
  policy = file("${path.module}/iam_policies/s3_access.json")
}

resource "aws_iam_role_policy_attachment" "batch_job_cloudwatch" {
  role       = aws_iam_role.batch_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

# Get current region
data "aws_region" "current" {}

# IAM Roles and Security Groups
resource "aws_iam_role" "batch_service_role" {
  name = "${var.project_name}-batch-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["batch.amazonaws.com", "ecs-tasks.amazonaws.com"]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "batch_service_ecs" {
  name = "${var.project_name}-batch-service-ecs"
  role = aws_iam_role.batch_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:*",
          "ecs:DeleteCluster",
          "ecs:ListClusters",
          "ecs:DescribeClusters",
          "ecs:ListContainerInstances",
          "ecs:DeregisterContainerInstance",
          "ecs:UpdateContainerInstancesState",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "logs:*",
          "ec2:*",
          "autoscaling:*",
          "iam:PassRole",
          "batch:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "batch_service" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}



resource "aws_iam_role" "batch_instance_role" {
  name = "${var.project_name}-batch-instance-role"

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

resource "aws_iam_instance_profile" "batch_instance_role" {
  name = "${var.project_name}-batch-instance-profile"
  role = aws_iam_role.batch_instance_role.name
}

resource "aws_iam_role_policy_attachment" "batch_instance" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_security_group" "batch" {
  name        = "${var.project_name}-batch-sg"
  description = "Security group for AWS Batch compute environment"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
