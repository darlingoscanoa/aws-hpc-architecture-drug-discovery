# Outputs for the ParallelCluster module.

output "cluster_id" {
  description = "ID of the created ParallelCluster"
  value       = aws_parallelcluster.hpc.id
}

output "cluster_name" {
  description = "Name of the created ParallelCluster"
  value       = aws_parallelcluster.hpc.name
}

output "head_node_public_ip" {
  description = "Public IP address of the head node"
  value       = aws_parallelcluster.hpc.head_node_public_ip
}

output "compute_nodes_private_ips" {
  description = "Private IP addresses of compute nodes"
  value       = aws_parallelcluster.hpc.compute_nodes_private_ips
}

output "fsx_lustre_id" {
  description = "ID of the FSx for Lustre filesystem"
  value       = aws_parallelcluster.hpc.shared_storage.fsx_lustre.id
}

output "cluster_endpoint" {
  description = "The endpoint of the ParallelCluster"
  value       = aws_parallelcluster.hpc.endpoint
} 