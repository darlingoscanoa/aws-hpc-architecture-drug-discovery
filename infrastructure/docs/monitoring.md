# HPC Infrastructure Monitoring and Observability Guide

This guide provides comprehensive monitoring and observability recommendations for the HPC infrastructure.

## 1. CloudWatch Integration

### Metrics Collection
```hcl
# CloudWatch Agent Configuration
resource "aws_cloudwatch_agent" "hpc" {
  name = "hpc-monitoring"

  configuration = jsonencode({
    agent = {
      metrics_collection_interval = 60
      run_as_user = "root"
    }
    metrics = {
      metrics_collected = {
        mem = {
          measurement = ["mem_used_percent"]
        }
        disk = {
          measurement = ["disk_used_percent"]
        }
        net = {
          measurement = ["net_bytes_recv", "net_bytes_sent"]
        }
      }
    }
  })
}

# Custom Metrics
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "CPU utilization is too high"
  alarm_actions      = [aws_sns_topic.alerts.arn]
}
```

### Log Management
```hcl
# Log Group
resource "aws_cloudwatch_log_group" "hpc" {
  name              = "/hpc/${var.environment}"
  retention_in_days = 30
}

# Log Stream
resource "aws_cloudwatch_log_stream" "system" {
  name           = "system-logs"
  log_group_name = aws_cloudwatch_log_group.hpc.name
}

# Log Metric Filter
resource "aws_cloudwatch_log_metric_filter" "error" {
  name           = "error-logs"
  pattern        = "[timestamp, level=ERROR*, message]"
  log_group_name = aws_cloudwatch_log_group.hpc.name

  metric_transformation {
    name          = "ErrorCount"
    namespace     = "HPC/Logs"
    value         = "1"
    default_value = "0"
  }
}
```

## 2. System Monitoring

### Resource Monitoring
```bash
# Resource Monitoring Script
#!/bin/bash
MONITOR_LOG="/var/log/monitoring.$DATE.log"

monitor_resources() {
    # CPU Monitoring
    top -bn1 | grep "Cpu(s)" >> $MONITOR_LOG
    
    # Memory Monitoring
    free -m >> $MONITOR_LOG
    
    # Disk Monitoring
    df -h >> $MONITOR_LOG
    
    # Network Monitoring
    netstat -i >> $MONITOR_LOG
}
```

### Process Monitoring
```bash
# Process Monitoring Script
#!/bin/bash
PROCESS_LOG="/var/log/processes.$DATE.log"

monitor_processes() {
    # Slurm Processes
    ps aux | grep slurm >> $PROCESS_LOG
    
    # System Processes
    ps aux --sort=-%cpu | head -n 10 >> $PROCESS_LOG
    
    # User Processes
    ps aux | grep -v root >> $PROCESS_LOG
}
```

## 3. Application Monitoring

### Slurm Monitoring
```bash
# Slurm Monitoring Script
#!/bin/bash
SLURM_LOG="/var/log/slurm.$DATE.log"

monitor_slurm() {
    # Queue Status
    squeue >> $SLURM_LOG
    
    # Node Status
    sinfo >> $SLURM_LOG
    
    # Job Statistics
    sacct --format=JobID,State,Elapsed,CPUTime >> $SLURM_LOG
}
```

### Storage Monitoring
```bash
# Storage Monitoring Script
#!/bin/bash
STORAGE_LOG="/var/log/storage.$DATE.log"

monitor_storage() {
    # FSx Status
    lfs df >> $STORAGE_LOG
    
    # S3 Status
    aws s3 ls s3://$BUCKET_NAME >> $STORAGE_LOG
    
    # Local Storage
    df -h >> $STORAGE_LOG
}
```

## 4. Performance Monitoring

### Network Performance
```bash
# Network Performance Script
#!/bin/bash
NETWORK_LOG="/var/log/network.$DATE.log"

monitor_network() {
    # Bandwidth Usage
    ifstat -t 1 60 >> $NETWORK_LOG
    
    # Latency
    ping -c 4 head-node >> $NETWORK_LOG
    
    # Connection Status
    netstat -ant | grep ESTABLISHED >> $NETWORK_LOG
}
```

### I/O Performance
```bash
# I/O Performance Script
#!/bin/bash
IO_LOG="/var/log/io.$DATE.log"

monitor_io() {
    # Disk I/O
    iostat -x 1 60 >> $IO_LOG
    
    # File System I/O
    lfs df -h >> $IO_LOG
    
    # Cache Status
    free -m >> $IO_LOG
}
```

## 5. Alerting System

### Alert Configuration
```hcl
# SNS Topic
resource "aws_sns_topic" "alerts" {
  name = "hpc-alerts"
}

# Alert Policy
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}
```

### Alert Rules
```hcl
# CPU Alert
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "CPU utilization is too high"
  alarm_actions      = [aws_sns_topic.alerts.arn]
}

# Memory Alert
resource "aws_cloudwatch_metric_alarm" "memory" {
  alarm_name          = "memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "HPC/System"
  period             = "300"
  statistic          = "Average"
  threshold          = "85"
  alarm_description  = "Memory utilization is too high"
  alarm_actions      = [aws_sns_topic.alerts.arn]
}
```

## 6. Dashboard Configuration

### CloudWatch Dashboard
```hcl
# Dashboard
resource "aws_cloudwatch_dashboard" "hpc" {
  dashboard_name = "hpc-monitoring"

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
            ["AWS/EC2", "CPUUtilization", "InstanceId", "i-1234567890abcdef0"]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "CPU Utilization"
        }
      }
    ]
  })
}
```

### Grafana Integration
```yaml
# Grafana Configuration
apiVersion: 1
datasources:
  - name: CloudWatch
    type: cloudwatch
    access: proxy
    jsonData:
      authType: arn
      assumeRoleArn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/grafana-role
    editable: false
```

## 7. Log Analysis

### Log Processing
```bash
# Log Analysis Script
#!/bin/bash
ANALYSIS_LOG="/var/log/analysis.$DATE.log"

analyze_logs() {
    # Error Analysis
    grep "ERROR" /var/log/slurm/* >> $ANALYSIS_LOG
    
    # Performance Analysis
    awk '{print $1, $2}' /var/log/performance.* >> $ANALYSIS_LOG
    
    # Security Analysis
    grep "Failed password" /var/log/secure >> $ANALYSIS_LOG
}
```

### Log Aggregation
```hcl
# Log Aggregation
resource "aws_cloudwatch_log_group" "aggregated" {
  name              = "/hpc/aggregated"
  retention_in_days = 90
}

# Log Subscription Filter
resource "aws_cloudwatch_log_subscription_filter" "aggregate" {
  name            = "aggregate-logs"
  role_arn        = aws_iam_role.log_aggregation.arn
  log_group_name  = aws_cloudwatch_log_group.aggregated.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.logs.arn
}
```

## 8. Performance Analysis

### Performance Metrics
```bash
# Performance Analysis Script
#!/bin/bash
PERF_LOG="/var/log/performance.$DATE.log"

analyze_performance() {
    # CPU Analysis
    mpstat 1 60 >> $PERF_LOG
    
    # Memory Analysis
    vmstat 1 60 >> $PERF_LOG
    
    # I/O Analysis
    iostat -x 1 60 >> $PERF_LOG
}
```

### Bottleneck Detection
```bash
# Bottleneck Detection Script
#!/bin/bash
BOTTLENECK_LOG="/var/log/bottleneck.$DATE.log"

detect_bottlenecks() {
    # CPU Bottlenecks
    top -bn1 | grep "Cpu(s)" >> $BOTTLENECK_LOG
    
    # Memory Bottlenecks
    free -m | grep Mem >> $BOTTLENECK_LOG
    
    # I/O Bottlenecks
    iostat -x | grep -v avg-cpu >> $BOTTLENECK_LOG
}
```

## 9. Reporting

### Daily Reports
```bash
# Daily Report Script
#!/bin/bash
REPORT_FILE="/var/log/daily_report.$DATE.log"

generate_daily_report() {
    # System Summary
    echo "=== System Summary ===" >> $REPORT_FILE
    uptime >> $REPORT_FILE
    free -m >> $REPORT_FILE
    
    # Job Summary
    echo "=== Job Summary ===" >> $REPORT_FILE
    sacct --format=JobID,State,Elapsed >> $REPORT_FILE
    
    # Performance Summary
    echo "=== Performance Summary ===" >> $REPORT_FILE
    sar -u -r -b >> $REPORT_FILE
}
```

### Weekly Reports
```bash
# Weekly Report Script
#!/bin/bash
WEEKLY_REPORT="/var/log/weekly_report.$DATE.log"

generate_weekly_report() {
    # Resource Utilization
    echo "=== Resource Utilization ===" >> $WEEKLY_REPORT
    sar -u -r -b -f /var/log/sa/sa* >> $WEEKLY_REPORT
    
    # Job Statistics
    echo "=== Job Statistics ===" >> $WEEKLY_REPORT
    sacct --format=JobID,State,Elapsed,CPUTime >> $WEEKLY_REPORT
    
    # System Events
    echo "=== System Events ===" >> $WEEKLY_REPORT
    journalctl -p err..emerg >> $WEEKLY_REPORT
}
``` 