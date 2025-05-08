# Code Style Guide

This document outlines the coding standards and best practices for the AWS HPC Drug Discovery Platform.

## Python Code Style

### General Guidelines

1. **Indentation**
   - Use 4 spaces for indentation
   - No tabs
   - Maximum line length: 88 characters (Black)

2. **Imports**
   ```python
   # Standard library imports
   import os
   import sys
   
   # Third-party imports
   import boto3
   import pytest
   
   # Local imports
   from .utils import helper
   from .config import settings
   ```

3. **Naming Conventions**
   - Classes: `PascalCase`
   - Functions/Variables: `snake_case`
   - Constants: `UPPER_SNAKE_CASE`
   - Private members: `_leading_underscore`

### Function Definitions

```python
def calculate_resource_usage(
    cpu_percentage: float,
    memory_usage: int,
    disk_space: float
) -> Dict[str, float]:
    """
    Calculate resource usage metrics.
    
    Args:
        cpu_percentage: CPU utilization percentage
        memory_usage: Memory usage in bytes
        disk_space: Available disk space in GB
        
    Returns:
        Dict containing resource usage metrics
        
    Raises:
        ValueError: If input parameters are invalid
    """
    if cpu_percentage < 0 or cpu_percentage > 100:
        raise ValueError("CPU percentage must be between 0 and 100")
        
    return {
        "cpu": cpu_percentage,
        "memory": memory_usage / (1024 * 1024),  # Convert to MB
        "disk": disk_space
    }
```

### Class Definitions

```python
class ResourceMonitor:
    """Monitor system resources and generate alerts."""
    
    def __init__(self, threshold: float = 80.0):
        """
        Initialize resource monitor.
        
        Args:
            threshold: Alert threshold percentage
        """
        self.threshold = threshold
        self._metrics: Dict[str, float] = {}
        
    def update_metrics(self, metrics: Dict[str, float]) -> None:
        """
        Update resource metrics.
        
        Args:
            metrics: Dictionary of resource metrics
        """
        self._metrics.update(metrics)
        
    def check_alerts(self) -> List[str]:
        """
        Check for resource alerts.
        
        Returns:
            List of alert messages
        """
        alerts = []
        for resource, value in self._metrics.items():
            if value > self.threshold:
                alerts.append(f"{resource} usage above threshold")
        return alerts
```

## Terraform Code Style

### General Guidelines

1. **File Organization**
   ```
   infrastructure/
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
   ├── providers.tf
   └── modules/
       ├── vpc/
       ├── cluster/
       └── storage/
   ```

2. **Resource Naming**
   ```hcl
   resource "aws_vpc" "main" {
     cidr_block           = var.vpc_cidr
     enable_dns_hostnames = true
     enable_dns_support   = true
     
     tags = {
       Name        = "${var.environment}-vpc"
       Environment = var.environment
     }
   }
   ```

3. **Variable Definitions**
   ```hcl
   variable "environment" {
     description = "Environment name (e.g., dev, prod)"
     type        = string
     default     = "dev"
   }
   
   variable "vpc_cidr" {
     description = "CIDR block for VPC"
     type        = string
     default     = "10.0.0.0/16"
   }
   ```

### Module Structure

```hcl
# main.tf
module "vpc" {
  source = "./modules/vpc"
  
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

# variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

# outputs.tf
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}
```

## Documentation Style

### Docstrings

```python
def process_data(data: List[Dict[str, Any]]) -> pd.DataFrame:
    """
    Process input data into a pandas DataFrame.
    
    This function takes a list of dictionaries containing raw data
    and converts it into a structured DataFrame for analysis.
    
    Args:
        data: List of dictionaries containing raw data
        
    Returns:
        pandas DataFrame containing processed data
        
    Raises:
        ValueError: If input data is empty or invalid
        
    Example:
        >>> data = [{"id": 1, "value": 10}]
        >>> df = process_data(data)
        >>> print(df)
           id  value
        0   1     10
    """
    if not data:
        raise ValueError("Input data cannot be empty")
        
    return pd.DataFrame(data)
```

### Comments

```python
# Calculate resource utilization
def calculate_utilization(
    used: float,
    total: float
) -> float:
    """
    Calculate resource utilization percentage.
    
    Args:
        used: Used resource amount
        total: Total resource amount
        
    Returns:
        Utilization percentage
    """
    # Avoid division by zero
    if total == 0:
        return 0.0
        
    return (used / total) * 100
```

## Testing Style

### Test Functions

```python
def test_resource_monitor():
    """Test resource monitoring functionality."""
    # Arrange
    monitor = ResourceMonitor(threshold=80.0)
    test_metrics = {
        "cpu": 90.0,
        "memory": 85.0,
        "disk": 75.0
    }
    
    # Act
    monitor.update_metrics(test_metrics)
    alerts = monitor.check_alerts()
    
    # Assert
    assert len(alerts) == 2
    assert "cpu usage above threshold" in alerts
    assert "memory usage above threshold" in alerts
```

### Test Fixtures

```python
@pytest.fixture
def resource_monitor():
    """Fixture for resource monitor."""
    return ResourceMonitor(threshold=80.0)

@pytest.fixture
def test_metrics():
    """Fixture for test metrics."""
    return {
        "cpu": 90.0,
        "memory": 85.0,
        "disk": 75.0
    }
```

## Best Practices

1. **Code Organization**
   - Logical file structure
   - Clear module boundaries
   - Consistent naming

2. **Error Handling**
   - Use specific exceptions
   - Provide clear error messages
   - Log errors appropriately

3. **Performance**
   - Optimize resource usage
   - Use appropriate data structures
   - Cache when beneficial

4. **Security**
   - Follow least privilege
   - Validate inputs
   - Sanitize outputs

5. **Maintainability**
   - Write self-documenting code
   - Keep functions focused
   - Regular refactoring

## Tools

1. **Code Formatting**
   ```bash
   # Format Python code
   black .
   
   # Sort imports
   isort .
   
   # Format Terraform code
   terraform fmt
   ```

2. **Linting**
   ```bash
   # Python linting
   flake8
   pylint src/
   
   # Type checking
   mypy src/
   ```

3. **Testing**
   ```bash
   # Run tests
   pytest
   
   # Run with coverage
   pytest --cov=src/
   ```

## Review Process

1. **Code Review Checklist**
   - Follows style guide
   - Includes tests
   - Proper documentation
   - Security considerations

2. **Pull Request Template**
   ```markdown
   ## Description
   Brief description of changes
   
   ## Testing
   - [ ] Unit tests added
   - [ ] Integration tests added
   - [ ] Manual testing completed
   
   ## Documentation
   - [ ] Code comments added
   - [ ] Documentation updated
   ```

3. **Review Guidelines**
   - Be constructive
   - Focus on improvements
   - Consider maintainability
   - Check security 