# HPC Infrastructure Deployment Guide

This guide provides step-by-step instructions for deploying the HPC infrastructure for drug discovery.

## Prerequisites

### Required Tools
- Terraform >= 1.0.0
- AWS CLI >= 2.0.0
- Python >= 3.8
- Git

### AWS Account Setup
1. Create an AWS account if you don't have one
2. Configure AWS credentials:
   ```bash
   aws configure
   ```
3. Create an IAM user with appropriate permissions:
   - AdministratorAccess (for development)
   - Custom policy for production

### SSH Key Pair
1. Generate an SSH key pair:
   ```bash
   ssh-keygen -t rsa -b 2048 -f ~/.ssh/hpc_key
   ```
2. Import the public key to AWS:
   ```bash
   aws ec2 import-key-pair --key-name hpc_key --public-key-material fileb://~/.ssh/hpc_key.pub
   ```

## Infrastructure Deployment

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/aws_hpc_drug_discovery.git
cd aws_hpc_drug_discovery
```

### 2. Configure Environment Variables
Create a `terraform.tfvars` file:
```hcl
aws_region = "us-east-1"
project_name = "hpc-drug-discovery"
environment = "dev"
vpc_cidr = "10.0.0.0/16"
key_name = "hpc_key"
head_node_instance_type = "c5.xlarge"
compute_node_instance_type = "hpc6a.48xlarge"
min_compute_nodes = 1
max_compute_nodes = 10
desired_compute_nodes = 2
spot_price = 0.0
fsx_storage_capacity = 1200
shutdown_hour = 22
shutdown_threshold_hours = 4
```

### 3. Initialize Terraform
```bash
cd infrastructure/terraform
terraform init
```

### 4. Review the Plan
```bash
terraform plan
```

### 5. Apply the Configuration
```bash
terraform apply
```

### 6. Verify Deployment
1. Check CloudFormation stack status:
   ```bash
   aws cloudformation describe-stacks --stack-name hpc-drug-discovery
   ```

2. Verify cluster status:
   ```bash
   aws parallelcluster describe-cluster --cluster-name hpc-drug-discovery
   ```

3. Test SSH access:
   ```bash
   ssh -i ~/.ssh/hpc_key ec2-user@<head-node-public-ip>
   ```

## Post-Deployment Configuration

### 1. Configure Storage
1. Mount FSx filesystem:
   ```bash
   sudo mount -t lustre <fsx-dns-name>@tcp:/fsx /fsx
   ```

2. Set up S3 sync:
   ```bash
   aws s3 sync s3://<bucket-name>/data /fsx/data
   ```

### 2. Install Software
1. Update system packages:
   ```bash
   sudo yum update -y
   ```

2. Install required software:
   ```bash
   sudo yum install -y python3-pip git
   pip3 install torch torchvision torchaudio
   ```

### 3. Configure Monitoring
1. Set up CloudWatch agent:
   ```bash
   sudo yum install -y amazon-cloudwatch-agent
   sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
   ```

2. Configure alarms:
   ```bash
   aws cloudwatch put-metric-alarm --cli-input-json file://alarms/cpu-utilization.json
   ```

## Security Configuration

### 1. Network Security
1. Configure security groups:
   ```bash
   aws ec2 authorize-security-group-ingress --group-id <sg-id> --protocol tcp --port 22 --cidr <your-ip>/32
   ```

2. Set up VPC endpoints:
   ```bash
   aws ec2 create-vpc-endpoint --vpc-id <vpc-id> --service-name com.amazonaws.<region>.s3
   ```

### 2. Access Control
1. Create IAM roles:
   ```bash
   aws iam create-role --role-name hpc-compute-role --assume-role-policy-document file://policies/assume-role.json
   ```

2. Attach policies:
   ```bash
   aws iam attach-role-policy --role-name hpc-compute-role --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM
   ```

## Cost Optimization

### 1. Configure Auto-scaling
1. Set up scaling policies:
   ```bash
   aws autoscaling put-scaling-policy --cli-input-json file://scaling/cpu-scaling.json
   ```

2. Configure spot instances:
   ```bash
   aws ec2 request-spot-instances --cli-input-json file://spot/request.json
   ```

### 2. Storage Optimization
1. Set up lifecycle policies:
   ```bash
   aws s3api put-bucket-lifecycle-configuration --bucket <bucket-name> --lifecycle-configuration file://lifecycle/policy.json
   ```

2. Enable compression:
   ```bash
   sudo mount -o compress /fsx
   ```

## Maintenance Procedures

### 1. Regular Updates
1. Update system packages:
   ```bash
   sudo yum update -y
   ```

2. Update cluster software:
   ```bash
   aws parallelcluster update-cluster --cluster-name hpc-drug-discovery
   ```

### 2. Backup Procedures
1. Create FSx backup:
   ```bash
   aws fsx create-backup --file-system-id <fsx-id>
   ```

2. Sync data to S3:
   ```bash
   aws s3 sync /fsx/data s3://<bucket-name>/backup
   ```

## Troubleshooting

### Common Issues
1. SSH Access Issues:
   - Verify security group rules
   - Check key pair configuration
   - Test network connectivity

2. Storage Issues:
   - Check FSx status
   - Verify mount points
   - Monitor disk space

3. Performance Issues:
   - Check network bandwidth
   - Monitor CPU utilization
   - Verify storage IOPS

### Support Resources
- AWS ParallelCluster documentation
- AWS FSx documentation
- AWS CloudWatch documentation
- AWS Support

## Cleanup

### 1. Backup Data
```bash
aws s3 sync /fsx/data s3://<bucket-name>/final-backup
```

### 2. Destroy Infrastructure
```bash
terraform destroy
```

### 3. Clean Up Resources
```bash
aws ec2 delete-key-pair --key-name hpc_key
```

## Best Practices

### 1. Resource Management
- Use tags for resource tracking
- Implement proper IAM roles
- Follow least privilege principle

### 2. Cost Management
- Monitor resource usage
- Set up billing alerts
- Use spot instances when possible

### 3. Security
- Regular security updates
- Access control reviews
- Audit logging

### 4. Performance
- Monitor system metrics
- Optimize resource allocation
- Regular performance testing 