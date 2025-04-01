# Outputs for the FSx module.

output "fsx_id" {
  description = "ID of the FSx for Lustre filesystem"
  value       = aws_fsx_lustre_file_system.hpc.id
}

output "dns_name" {
  description = "DNS name of the FSx for Lustre filesystem"
  value       = aws_fsx_lustre_file_system.hpc.dns_name
}

output "fsx_mount_name" {
  description = "Mount name of the FSx for Lustre filesystem"
  value       = aws_fsx_lustre_file_system.hpc.mount_name
}

output "security_group_id" {
  description = "ID of the security group for FSx"
  value       = aws_security_group.fsx.id
} 