# HPC Infrastructure for Drug Discovery

This directory contains the infrastructure code for the HPC-based drug discovery platform using AWS services.

## Architecture Overview

The infrastructure consists of the following components:

1. **AWS ParallelCluster**
   - HPC6a instances for compute nodes
   - C5.xlarge for head node
   - EFA networking for high-performance inter-node communication

2. **FSx for Lustre**
   - High-performance parallel filesystem
   - Integrated with S3 for data persistence
   - Optimized for HPC workloads

3. **S3 Storage**
   - Data lake for raw and processed data
   - Lifecycle policies for cost optimization
   - Versioning enabled for data protection

4. **CloudWatch Monitoring**
   - Real-time cluster metrics
   - Custom dashboards
   - Automated alerts

5. **Auto-shutdown Lambda**
   - Cost optimization through automatic shutdown
   - Configurable inactivity thresholds
   - Scheduled shutdown during off-hours

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- SSH key pair for cluster access

## Directory Structure

```
infrastructure/
├── terraform/
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   └── modules/
│       ├── vpc/            # VPC and networking
│       ├── parallelcluster/ # HPC cluster configuration
│       ├── fsx/            # Lustre filesystem
│       ├── s3/             # S3 storage
│       ├── cloudwatch/     # Monitoring and alerts
│       └── auto_shutdown/  # Cost optimization
└── README.md
```

## Usage

1. Configure AWS credentials:
   ```bash
   aws configure
   ```

2. Initialize Terraform:
   ```bash
   cd infrastructure/terraform
   terraform init
   ```

3. Create a `terraform.tfvars` file with your configuration:
   ```hcl
   aws_region = "us-east-1"
   project_name = "hpc-drug-discovery"
   environment = "dev"
   key_name = "your-key-pair"
   ami_id = "ami-xxxxxxxx"
   ```

4. Apply the configuration:
   ```bash
   terraform plan
   terraform apply
   ```

5. Access the cluster:
   ```bash
   ssh -i your-key.pem ec2-user@<head_node_public_ip>
   ```

## Cost Estimation

The infrastructure is designed to be cost-effective while maintaining high performance:

- **Compute Nodes**: HPC6a.48xlarge spot instances
- **Head Node**: C5.xlarge on-demand
- **Storage**: FSx for Lustre with S3 backend
- **Auto-shutdown**: Reduces costs during inactivity

Estimated monthly costs (with auto-shutdown):
- Development: $100-200
- Production: $500-1000

## Security

- VPC with private subnets
- Security groups with minimal access
- S3 bucket encryption
- IAM roles with least privilege
- CloudWatch monitoring and alerts

## Maintenance

1. **Regular Updates**
   - Keep AMIs updated
   - Monitor security patches
   - Review cost optimization settings

2. **Backup Strategy**
   - S3 versioning enabled
   - Regular snapshots of critical data
   - Cross-region replication for disaster recovery

3. **Monitoring**
   - CloudWatch dashboards
   - SNS notifications for alerts
   - Cost and usage reports

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Note**: This will delete all resources. Ensure all data is backed up before proceeding.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 