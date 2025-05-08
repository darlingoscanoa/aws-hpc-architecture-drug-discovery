# HPC Infrastructure Disaster Recovery Guide

This guide provides comprehensive procedures for disaster recovery and business continuity for the HPC infrastructure.

## 1. Backup Strategy

### Data Backup
```hcl
# S3 Backup Configuration
resource "aws_s3_bucket" "backup" {
  bucket = "hpc-backup-bucket"

  lifecycle_rule {
    id      = "backup-rule"
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# Cross-Region Replication
resource "aws_s3_bucket_replication_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "backup-replication"
    status = "Enabled"

    destination {
      bucket = "arn:aws:s3:::${var.backup_region}-hpc-backup"
    }
  }
}
```

### System State Backup
```bash
# Backup System Configuration
#!/bin/bash
BACKUP_DIR="/backup/system"
DATE=$(date +%Y%m%d)

# Backup Slurm Configuration
cp /etc/slurm/slurm.conf $BACKUP_DIR/slurm.conf.$DATE
cp /etc/slurm/gres.conf $BACKUP_DIR/gres.conf.$DATE

# Backup User Data
tar -czf $BACKUP_DIR/home.$DATE.tar.gz /home

# Backup System Configuration
tar -czf $BACKUP_DIR/etc.$DATE.tar.gz /etc
```

## 2. Recovery Procedures

### Infrastructure Recovery
```hcl
# Recovery Module
module "recovery" {
  source = "./modules/recovery"

  environment     = "recovery"
  vpc_cidr       = "10.1.0.0/16"
  region         = var.recovery_region
  backup_bucket  = var.backup_bucket
  restore_point  = var.restore_point
}
```

### Data Recovery
```bash
# Data Recovery Script
#!/bin/bash
BACKUP_BUCKET="hpc-backup-bucket"
RESTORE_DIR="/restore"

# Restore from S3
aws s3 sync s3://$BACKUP_BUCKET/data $RESTORE_DIR/data

# Restore System Configuration
tar -xzf /backup/system/etc.$RESTORE_DATE.tar.gz -C /
tar -xzf /backup/system/home.$RESTORE_DATE.tar.gz -C /

# Restore Slurm Configuration
cp /backup/system/slurm.conf.$RESTORE_DATE /etc/slurm/slurm.conf
cp /backup/system/gres.conf.$RESTORE_DATE /etc/slurm/gres.conf
```

## 3. High Availability

### Multi-Region Setup
```hcl
# Primary Region
module "primary" {
  source = "./modules/hpc"

  environment = "primary"
  region     = "us-east-1"
  vpc_cidr   = "10.0.0.0/16"
}

# Secondary Region
module "secondary" {
  source = "./modules/hpc"

  environment = "secondary"
  region     = "us-west-2"
  vpc_cidr   = "10.1.0.0/16"
}
```

### Failover Configuration
```hcl
# Route53 Failover
resource "aws_route53_record" "hpc" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "hpc.example.com"
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "primary"
  ttl           = "300"
  records       = [aws_instance.primary.public_ip]
}

resource "aws_route53_record" "hpc_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "hpc.example.com"
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "secondary"
  ttl           = "300"
  records       = [aws_instance.secondary.public_ip]
}
```

## 4. Recovery Testing

### Test Procedures
```bash
# Recovery Test Script
#!/bin/bash
TEST_DATE=$(date +%Y%m%d)
LOG_FILE="/var/log/recovery_test.$TEST_DATE.log"

# Test Data Recovery
echo "Testing data recovery..." >> $LOG_FILE
aws s3 sync s3://$BACKUP_BUCKET/test_data $RESTORE_DIR/test_data

# Test System Recovery
echo "Testing system recovery..." >> $LOG_FILE
./recover_system.sh --test

# Test Application Recovery
echo "Testing application recovery..." >> $LOG_FILE
./recover_applications.sh --test

# Verify Recovery
echo "Verifying recovery..." >> $LOG_FILE
./verify_recovery.sh
```

### Health Checks
```bash
# Health Check Script
#!/bin/bash
HEALTH_FILE="/var/log/health_check.$DATE.log"

# Check System Health
check_system_health() {
    # Check CPU
    top -bn1 | grep "Cpu(s)" >> $HEALTH_FILE
    
    # Check Memory
    free -m >> $HEALTH_FILE
    
    # Check Disk Space
    df -h >> $HEALTH_FILE
}

# Check Application Health
check_application_health() {
    # Check Slurm
    sinfo >> $HEALTH_FILE
    
    # Check FSx
    lfs df >> $HEALTH_FILE
    
    # Check S3 Access
    aws s3 ls s3://$BACKUP_BUCKET >> $HEALTH_FILE
}
```

## 5. Business Continuity

### Service Level Objectives
- **Recovery Time Objective (RTO)**: 4 hours
- **Recovery Point Objective (RPO)**: 1 hour
- **Maximum Tolerable Downtime (MTD)**: 8 hours

### Communication Plan
```bash
# Notification Script
#!/bin/bash
NOTIFY_TOPIC="arn:aws:sns:region:account:hpc-notifications"

send_notification() {
    local message=$1
    local severity=$2
    
    aws sns publish \
        --topic-arn $NOTIFY_TOPIC \
        --message "$message" \
        --message-attributes "{\"Severity\":{\"DataType\":\"String\",\"StringValue\":\"$severity\"}}"
}
```

## 6. Documentation

### Recovery Documentation
- System architecture diagrams
- Network configurations
- Security settings
- Application dependencies

### Contact Information
- Primary contact
- Secondary contact
- Vendor contacts
- Emergency services

## 7. Regular Maintenance

### Backup Verification
```bash
# Backup Verification Script
#!/bin/bash
VERIFY_LOG="/var/log/backup_verify.$DATE.log"

verify_backup() {
    # Verify S3 Backups
    aws s3 ls s3://$BACKUP_BUCKET >> $VERIFY_LOG
    
    # Verify Local Backups
    ls -l /backup/system >> $VERIFY_LOG
    
    # Test Restore
    ./test_restore.sh >> $VERIFY_LOG
}
```

### Recovery Testing Schedule
- Weekly: Data backup verification
- Monthly: System recovery testing
- Quarterly: Full disaster recovery drill

## 8. Monitoring and Alerts

### Health Monitoring
```hcl
# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "health" {
  alarm_name          = "system-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Average"
  threshold          = "2"
  alarm_description  = "System health check failed"
  alarm_actions      = [aws_sns_topic.alerts.arn]
}
```

### Alert Configuration
```hcl
# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "hpc-alerts"
}

# SNS Topic Policy
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

## 9. Post-Recovery Procedures

### System Validation
```bash
# Validation Script
#!/bin/bash
VALIDATE_LOG="/var/log/validate.$DATE.log"

validate_system() {
    # Check System State
    systemctl status slurmctld >> $VALIDATE_LOG
    systemctl status slurmd >> $VALIDATE_LOG
    
    # Check Network
    ping -c 4 head-node >> $VALIDATE_LOG
    
    # Check Storage
    df -h >> $VALIDATE_LOG
}
```

### Performance Verification
```bash
# Performance Test Script
#!/bin/bash
PERF_LOG="/var/log/performance.$DATE.log"

test_performance() {
    # CPU Test
    stress-ng --cpu 4 --timeout 60 >> $PERF_LOG
    
    # Memory Test
    stress-ng --vm 2 --vm-bytes 1G --timeout 60 >> $PERF_LOG
    
    # I/O Test
    iozone -a -n 512M -g 4G -i 0 -i 1 -i 2 >> $PERF_LOG
}
``` 