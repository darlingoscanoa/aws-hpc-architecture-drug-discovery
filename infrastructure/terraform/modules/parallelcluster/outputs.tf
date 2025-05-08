# Outputs for the ParallelCluster module.

output "head_node_id" {
  description = "ID of the head node instance"
  value       = aws_instance.head_node.id
}

output "head_node_public_ip" {
  description = "Public IP address of the head node"
  value       = aws_instance.head_node.public_ip
}

output "training_asg_name" {
  description = "Name of the training nodes Auto Scaling Group"
  value       = aws_autoscaling_group.training.name
}

output "inference_asg_name" {
  description = "Name of the inference nodes Auto Scaling Group"
  value       = aws_autoscaling_group.inference.name
}

output "shared_storage_dns" {
  description = "DNS name of the shared EFS storage"
  value       = aws_efs_file_system.shared.dns_name
}

output "slurm_config_path" {
  description = "Path to the SLURM configuration file"
  value       = "/etc/slurm/slurm.conf"
}

output "cluster_security_group_id" {
  description = "ID of the cluster security group"
  value       = aws_security_group.cluster.id
}