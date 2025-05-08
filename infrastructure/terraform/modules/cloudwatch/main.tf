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

resource "aws_cloudwatch_metric_alarm" "gpu_utilization" {
  alarm_name          = "${var.project_name}-gpu-utilization-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "GPUMemoryUsed"
  namespace           = "DrugDiscovery"
  period             = "300"
  statistic          = "Average"
  threshold          = "0.1"
  alarm_description  = "GPU utilization is very low"
  alarm_actions      = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
}

resource "aws_cloudwatch_metric_alarm" "training_loss" {
  alarm_name          = "${var.project_name}-training-loss-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "TrainingLoss"
  namespace           = "DrugDiscovery"
  period             = "300"
  statistic          = "Average"
  threshold          = "10.0"
  alarm_description  = "Training loss is too high"
  alarm_actions      = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
}

# Create CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "hpc" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["DrugDiscovery", "GPUUtilization", "InstanceId", "*", { "label": "GPU Core Utilization %" }],
            ["DrugDiscovery", "GPUMemoryUtilization", "InstanceId", "*", { "label": "GPU Memory %" }],
            ["DrugDiscovery", "GPUTemperature", "InstanceId", "*", { "label": "GPU Temperature °C" }],
            ["DrugDiscovery", "GPUPowerUsage", "InstanceId", "*", { "label": "Power Usage (W)" }]
          ]
          period = 60
          stat = "Average"
          region = var.aws_region
          title = "GPU Performance Metrics"
          view = "timeSeries"
          stacked = false
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["DrugDiscovery", "BatchSize", "JobType", "Training", { "label": "Training Batch Size" }],
            ["DrugDiscovery", "SamplesPerSecond", "JobType", "Training", { "label": "Samples/Second" }],
            ["DrugDiscovery", "TrainingLoss", "JobType", "Training", { "label": "Loss" }],
            ["DrugDiscovery", "ValidationAccuracy", "JobType", "Training", { "label": "Accuracy" }]
          ]
          period = 60
          stat = "Average"
          region = var.aws_region
          title = "Training Metrics"
          view = "timeSeries"
          stacked = false
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["DrugDiscovery", "InferenceThroughput", "JobType", "Inference", { "label": "Inferences/Second" }],
            ["DrugDiscovery", "InferenceLatency", "JobType", "Inference", { "label": "Latency (ms)" }],
            ["DrugDiscovery", "BatchSuccessRate", "JobType", "Inference", { "label": "Success Rate" }]
          ]
          period = 60
          stat = "Average"
          region = var.aws_region
          title = "Inference Performance"
          view = "timeSeries"
          stacked = false
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${var.project_name}-compute-nodes", { "label": "CPU %" }],
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", "${var.project_name}-compute-nodes", { "label": "Network In" }],
            ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", "${var.project_name}-compute-nodes", { "label": "Network Out" }]
          ]
          period = 60
          stat = "Average"
          region = var.aws_region
          title = "Instance Metrics"
          view = "timeSeries"
          stacked = false
        }
      }
    ]
  })
}