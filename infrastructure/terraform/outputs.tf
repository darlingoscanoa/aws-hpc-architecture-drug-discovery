# Outputs for the main Terraform configuration.

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "cluster_id" {
  description = "ID of the created ParallelCluster"
  value       = module.parallelcluster.cluster_id
}

output "cluster_name" {
  description = "Name of the created ParallelCluster"
  value       = module.parallelcluster.cluster_name
}

output "head_node_public_ip" {
  description = "Public IP address of the head node"
  value       = module.parallelcluster.head_node_public_ip
}

output "fsx_id" {
  description = "ID of the created FSx for Lustre filesystem"
  value       = module.fsx.fsx_id
}

output "fsx_dns_name" {
  description = "The DNS name of the FSx for Lustre filesystem"
  value       = module.fsx.dns_name
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

output "cluster_endpoint" {
  description = "The endpoint of the ParallelCluster"
  value       = module.parallelcluster.cluster_endpoint
} 