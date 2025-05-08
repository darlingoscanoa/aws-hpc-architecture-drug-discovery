# HPC Infrastructure Security Guide

This guide provides comprehensive security recommendations and best practices for the HPC infrastructure.

## 1. Network Security

### VPC Configuration
- **CIDR Block**: 10.0.0.0/16
- **Subnets**:
  - Public: For Internet Gateway and NAT
  - Private: For compute and storage
  - Isolated: For sensitive data

### Security Groups
```hcl
# Head Node Security Group
resource "aws_security_group" "head_node" {
  name = "head-node-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_IP/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Compute Node Security Group
resource "aws_security_group" "compute_nodes" {
  name = "compute-nodes-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.head_node.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Network ACLs
```hcl
# Network ACL for Private Subnet
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 0
    to_port    = 0
  }
}
```

## 2. Access Control

### IAM Roles and Policies
```hcl
# Compute Node IAM Role
resource "aws_iam_role" "compute_role" {
  name = "compute-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# S3 Access Policy
resource "aws_iam_role_policy" "s3_access" {
  name = "s3-access"
  role = aws_iam_role.compute_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      }
    ]
  })
}
```

### SSH Access
```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/hpc_key

# Configure SSH config
cat > ~/.ssh/config << EOF
Host hpc-head
    HostName <head-node-ip>
    User ec2-user
    IdentityFile ~/.ssh/hpc_key
    StrictHostKeyChecking no
EOF
```

## 3. Data Security

### Encryption at Rest
```hcl
# FSx Encryption
resource "aws_fsx_lustre_file_system" "fsx" {
  storage_capacity = 1200
  subnet_ids      = [aws_subnet.private.id]

  encryption_key {
    kms_key_id = aws_kms_key.fsx.arn
  }
}

# S3 Encryption
resource "aws_s3_bucket" "data" {
  bucket = "hpc-data-bucket"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
```

### Encryption in Transit
```hcl
# SSL/TLS Configuration
resource "aws_acm_certificate" "cert" {
  domain_name       = "hpc.example.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# VPC Endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
}
```

## 4. Monitoring and Logging

### CloudWatch Logs
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
```

### Security Monitoring
```hcl
# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "security" {
  alarm_name          = "security-violation"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecurityViolations"
  namespace           = "HPC/Security"
  period             = "300"
  statistic          = "Sum"
  threshold          = "1"
  alarm_description  = "Security violation detected"
  alarm_actions      = [aws_sns_topic.security.arn]
}
```

## 5. Compliance and Auditing

### AWS Config
```hcl
# AWS Config Rule
resource "aws_config_rule" "security" {
  name = "security-compliance"

  source {
    owner             = "AWS"
    source_identifier = "EC2_SECURITY_GROUP_OPEN_TO_WORLD"
  }

  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }
}
```

### Audit Logging
```hcl
# CloudTrail
resource "aws_cloudtrail" "main" {
  name                          = "hpc-trail"
  s3_bucket_name               = aws_s3_bucket.audit.id
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true
}
```

## 6. Incident Response

### Security Incident Playbook
1. **Detection**:
   ```bash
   # Monitor security events
   aws cloudwatch get-metric-statistics \
     --namespace HPC/Security \
     --metric-name SecurityViolations \
     --dimensions Name=Environment,Value=${var.environment}
   ```

2. **Containment**:
   ```bash
   # Isolate affected resources
   aws ec2 stop-instances --instance-ids <instance-id>
   ```

3. **Investigation**:
   ```bash
   # Collect logs
   aws cloudtrail lookup-events \
     --lookup-attributes AttributeKey=ResourceName,AttributeValue=<resource-id>
   ```

4. **Remediation**:
   ```bash
   # Apply security patches
   yum update -y
   ```

## 7. Security Best Practices

### System Hardening
```bash
# Disable unnecessary services
systemctl disable telnet
systemctl disable rsh
systemctl disable tftp

# Configure firewall
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload
```

### Access Management
```bash
# Configure sudo access
cat > /etc/sudoers.d/hpc-users << EOF
%hpc-users ALL=(ALL) NOPASSWD: /usr/bin/slurm
%hpc-users ALL=(ALL) NOPASSWD: /usr/bin/sinfo
%hpc-users ALL=(ALL) NOPASSWD: /usr/bin/squeue
EOF
```

## 8. Regular Security Tasks

### Vulnerability Scanning
```bash
# Install security scanner
yum install -y lynis

# Run security audit
lynis audit system
```

### Security Updates
```bash
# Configure automatic updates
yum install -y yum-cron
systemctl enable yum-cron
systemctl start yum-cron
```

## 9. Documentation and Training

### Security Documentation
- Access control procedures
- Incident response plans
- Security configurations
- Compliance requirements

### Security Training
- Regular security awareness training
- Incident response drills
- Access management reviews
- Security policy updates 