"""
Outputs for the FSx module.
"""

output "fsx_id" {
  description = "ID of the created FSx for Lustre filesystem"
  value       = aws_fsx_lustre_file_system.fsx.id
}

output "fsx_dns_name" {
  description = "DNS name of the FSx for Lustre filesystem"
  value       = aws_fsx_lustre_file_system.fsx.dns_name
}

output "fsx_mount_name" {
  description = "Mount name of the FSx for Lustre filesystem"
  value       = aws_fsx_lustre_file_system.fsx.mount_name
}

output "security_group_id" {
  description = "ID of the security group created for FSx"
  value       = aws_security_group.fsx.id
} 