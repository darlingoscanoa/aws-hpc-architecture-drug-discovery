# Outputs for the main Terraform configuration.

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "head_node_id" {
  description = "ID of the head node instance"
  value       = module.parallelcluster.head_node_id
}

output "head_node_public_ip" {
  description = "Public IP address of the head node"
  value       = module.parallelcluster.head_node_public_ip
}

output "compute_asg_name" {
  description = "Name of the compute nodes Auto Scaling Group"
  value       = module.parallelcluster.compute_asg_name
}

output "shared_storage_dns" {
  description = "DNS name of the shared EFS storage"
  value       = module.parallelcluster.shared_storage_dns
}

output "slurm_config_path" {
  description = "Path to the SLURM configuration file"
  value       = module.parallelcluster.slurm_config_path
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.s3.bucket_name
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.cloudwatch.dashboard_name
}

output "auto_shutdown_lambda_name" {
  description = "Name of the auto-shutdown Lambda function"
  value       = module.auto_shutdown.lambda_function_name
}