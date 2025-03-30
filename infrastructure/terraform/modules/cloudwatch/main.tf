"""
CloudWatch configuration for monitoring and logging.
"""

# CloudWatch Log Group for cluster logs
resource "aws_cloudwatch_log_group" "cluster_logs" {
  name              = "/aws/parallelcluster/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-logs"
    Environment = var.environment
  }
}

# CloudWatch Dashboard for cluster metrics
resource "aws_cloudwatch_dashboard" "cluster_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

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
            ["AWS/ParallelCluster", "CPUUtilization", "ClusterName", "${var.project_name}-${var.environment}"],
            [".", "MemoryUtilization", ".", "."],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Cluster Performance Metrics"
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
            ["AWS/FSx", "DataReadIOPS", "FileSystemId", aws_fsx_lustre_file_system.fsx.id],
            [".", "DataWriteIOPS", ".", "."],
            [".", "DataReadBytes", ".", "."],
            [".", "DataWriteBytes", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "FSx Performance Metrics"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ParallelCluster"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "CPU utilization is too high"
  alarm_actions      = [var.sns_topic_arn]

  dimensions = {
    ClusterName = "${var.project_name}-${var.environment}"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cpu-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-memory-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ParallelCluster"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "Memory utilization is too high"
  alarm_actions      = [var.sns_topic_arn]

  dimensions = {
    ClusterName = "${var.project_name}-${var.environment}"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-memory-alarm"
    Environment = var.environment
  }
} 