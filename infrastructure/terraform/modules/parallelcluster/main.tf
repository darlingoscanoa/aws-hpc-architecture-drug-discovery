"""
AWS ParallelCluster configuration for HPC infrastructure.
"""

resource "aws_parallelcluster" "cluster" {
  cluster_name = "${var.project_name}-${var.environment}"

  # Cluster configuration
  cluster_configuration = {
    vpc_id = var.vpc_id
    subnet_id = var.subnet_id
    key_name = var.key_name

    # Head node configuration
    head_node = {
      instance_type = var.head_node_instance_type
      ami_id = var.ami_id
      root_volume_size = 50
      root_volume_type = "gp3"
    }

    # Compute nodes configuration
    compute_nodes = {
      instance_type = var.compute_node_instance_type
      ami_id = var.ami_id
      root_volume_size = 50
      root_volume_type = "gp3"
      min_count = var.min_compute_nodes
      max_count = var.max_compute_nodes
      desired_count = var.desired_compute_nodes
      spot_price = var.spot_price
    }

    # Shared storage configuration
    shared_storage = {
      fsx_lustre = {
        storage_capacity = 1200
        deployment_type = "SCRATCH_2"
        storage_type = "SSD"
        subnet_id = var.subnet_id
      }
    }

    # Additional settings
    tags = {
      Name = "${var.project_name}-${var.environment}"
      Environment = var.environment
    }
  }

  # Additional configuration
  additional_resources = {
    s3_bucket = var.s3_bucket_name
    efa_enabled = true
    ebs_volume_size = 100
    ebs_volume_type = "gp3"
  }
} 