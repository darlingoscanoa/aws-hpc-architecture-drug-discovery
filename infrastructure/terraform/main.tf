# Main Terraform configuration for the HPC infrastructure.

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  
  backend "s3" {
    bucket = "hpc-drug-discovery-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

# Configure AWS provider
provider "aws" {
  region = var.aws_region
}

# VPC module
module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# ECR Repository for container images
resource "aws_ecr_repository" "app" {
  name = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"
}

# AWS Batch module
module "batch" {
  source = "./modules/batch"
  
  project_name = var.project_name
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
  s3_bucket_name = var.persistent_bucket_name
  ecr_repository_url = aws_ecr_repository.app.repository_url
}

# CloudWatch module
module "cloudwatch" {
  source = "./modules/cloudwatch"
  
  project_name    = var.project_name
  environment     = var.environment
  aws_region      = var.aws_region
  sns_topic_arn   = var.sns_topic_arn
}