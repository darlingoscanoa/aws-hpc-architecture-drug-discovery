# CloudWatch configuration for monitoring and logging.

# Create CloudWatch Log Group
resource "aws_cloudwatch_log_group" "hpc" {
  name              = "/aws/parallelcluster/${var.project_name}"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-logs"
    Environment = var.environment
  }
}

# Create CloudWatch Metric Alarms
resource "aws_cloudwatch_metric_alarm" "cluster_cpu" {
  count = var.sns_topic_arn != null ? 1 : 0

  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    AutoScalingGroupName = "${var.project_name}-compute-nodes"
  }
}

resource "aws_cloudwatch_metric_alarm" "fsx_storage" {
  count = var.sns_topic_arn != null ? 1 : 0

  alarm_name          = "${var.project_name}-fsx-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageCapacity"
  namespace           = "AWS/FSx"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "This metric monitors FSx storage capacity"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    FileSystemId = var.fsx_id
  }
}

# Create CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "hpc" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${var.project_name}-compute-nodes"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Compute Node CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/FSx", "FreeStorageCapacity", "FileSystemId", var.fsx_id]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "FSx Storage Capacity"
        }
      }
    ]
  })
} 