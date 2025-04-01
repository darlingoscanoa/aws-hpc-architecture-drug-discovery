# Outputs for the ParallelCluster module.

output "cluster_id" {
  description = "ID of the created ParallelCluster"
  value       = aws_parallelcluster_cluster.hpc.id
}

output "cluster_name" {
  description = "Name of the created ParallelCluster"
  value       = aws_parallelcluster_cluster.hpc.cluster_name
}

output "head_node_public_ip" {
  description = "Public IP address of the head node"
  value       = aws_parallelcluster_cluster.hpc.head_node.public_ip
}

output "compute_nodes_private_ips" {
  description = "Private IP addresses of compute nodes"
  value       = aws_parallelcluster.cluster.compute_nodes_private_ips
}

output "fsx_lustre_id" {
  description = "ID of the FSx for Lustre filesystem"
  value       = aws_parallelcluster.cluster.shared_storage.fsx_lustre.id
}

output "cluster_endpoint" {
  description = "The endpoint of the ParallelCluster"
  value       = aws_parallelcluster_cluster.hpc.endpoint
} 