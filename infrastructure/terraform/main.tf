# Main Terraform configuration for the HPC infrastructure.

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 0.1"
    }
  }
  
  # Commenting out S3 backend temporarily
  # backend "s3" {
  #   bucket = "hpc-drug-discovery-terraform-state"
  #   key    = "terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# Configure AWS provider
provider "aws" {
  region = var.aws_region
}

# Configure AWSCC provider for ParallelCluster
provider "awscc" {
  region = var.aws_region
}

# VPC module
module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# S3 module
module "s3" {
  source = "./modules/s3"
  
  project_name = var.project_name
  environment  = var.environment
}

# FSx module
module "fsx" {
  source = "./modules/fsx"
  
  project_name      = var.project_name
  environment       = var.environment
  storage_capacity  = var.fsx_storage_capacity
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.security_group_id]
  s3_bucket_name    = module.s3.bucket_name
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
}

# ParallelCluster module
module "parallelcluster" {
  source = "./modules/parallelcluster"
  
  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  subnet_id              = module.vpc.private_subnet_ids[0]
  key_name               = var.key_name
  head_node_instance_type = var.head_node_instance_type
  compute_node_instance_type = var.compute_node_instance_type
  ami_id                 = var.ami_id
  min_compute_nodes      = var.min_compute_nodes
  max_compute_nodes      = var.max_compute_nodes
  desired_compute_nodes  = var.desired_compute_nodes
  spot_price            = var.spot_price
  s3_bucket_name        = module.s3.bucket_name
}

# CloudWatch module
module "cloudwatch" {
  source = "./modules/cloudwatch"
  
  project_name    = var.project_name
  environment     = var.environment
  aws_region      = var.aws_region
  sns_topic_arn   = var.sns_topic_arn
  fsx_id          = module.fsx.fsx_id
}

# Auto-shutdown module
module "auto_shutdown" {
  source = "./modules/auto_shutdown"
  
  project_name           = var.project_name
  environment            = var.environment
  shutdown_hour         = var.shutdown_hour
  shutdown_threshold_hours = var.shutdown_threshold_hours
} 