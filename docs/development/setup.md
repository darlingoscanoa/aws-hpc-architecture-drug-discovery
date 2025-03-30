# Development Setup Guide

This guide will help you set up your development environment for the AWS HPC Drug Discovery Platform.

## Prerequisites

- Python 3.8 or later
- AWS CLI
- Terraform 1.0.0 or later
- Git
- Docker (optional)

## Environment Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/aws_hpc_drug_discovery.git
   cd aws_hpc_drug_discovery
   ```

2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Configure AWS credentials:
   ```bash
   aws configure
   ```
   Enter your AWS access key ID, secret access key, and default region.

## Infrastructure Development

1. Navigate to the infrastructure directory:
   ```bash
   cd infrastructure/terraform
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Create a `terraform.tfvars` file:
   ```hcl
   cluster_name = "my-hpc-cluster"
   environment = "development"
   vpc_cidr = "10.0.0.0/16"
   ```

4. Plan the infrastructure:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Testing

1. Run unit tests:
   ```bash
   pytest tests/
   ```

2. Run with coverage:
   ```bash
   pytest tests/ --cov=src/
   ```

## Code Style

1. Format code:
   ```bash
   black .
   isort .
   ```

2. Run linters:
   ```bash
   flake8
   pylint src/
   ```

3. Type checking:
   ```bash
   mypy src/
   ```

## Documentation

1. Build documentation:
   ```bash
   mkdocs build
   ```

2. Serve documentation locally:
   ```bash
   mkdocs serve
   ```

## Usage

1. Access the cluster:
   ```bash
   ssh -i ~/.ssh/id_rsa ec2-user@<head-node-ip>
   ```

2. Submit a job:
   ```bash
   sbatch job.sh
   ```

3. Monitor jobs:
   ```bash
   squeue
   sinfo
   ```

4. Check storage:
   ```bash
   df -h /fsx
   ```

## Troubleshooting

### Common Issues

1. **Terraform State Lock**
   ```bash
   terraform force-unlock <lock-id>
   ```

2. **SSH Access**
   - Check security groups
   - Verify key pair
   - Check instance status

3. **Storage Issues**
   - Check FSx status
   - Verify mount points
   - Check permissions

### Support

- Check [GitHub Issues](https://github.com/yourusername/aws_hpc_drug_discovery/issues)
- Contact the development team
- Review AWS documentation

## Best Practices

1. **Version Control**
   - Use feature branches
   - Write descriptive commit messages
   - Review code before merging

2. **Infrastructure**
   - Use workspaces for different environments
   - Tag resources appropriately
   - Follow least privilege principle

3. **Testing**
   - Write unit tests for new features
   - Maintain test coverage
   - Use mocking for AWS services

4. **Documentation**
   - Update documentation with changes
   - Include examples
   - Document assumptions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details. 