# Outputs for the CloudWatch module.

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.hpc.name
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.hpc.dashboard_name
}

output "cpu_alarm_name" {
  description = "Name of the CPU utilization alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_alarm.alarm_name
}

output "memory_alarm_name" {
  description = "Name of the memory utilization alarm"
  value       = aws_cloudwatch_metric_alarm.memory_alarm.alarm_name
} 