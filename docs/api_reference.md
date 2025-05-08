# API Reference

This document provides detailed API documentation for the AWS HPC Drug Discovery Platform.

## Infrastructure API

### VPC Module

#### Input Variables

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `environment` | string | Environment name (e.g., dev, prod) | "dev" |
| `vpc_cidr` | string | CIDR block for VPC | "10.0.0.0/16" |
| `availability_zones` | list(string) | List of availability zones | [] |
| `enable_nat_gateway` | bool | Enable NAT Gateway | true |
| `single_nat_gateway` | bool | Use single NAT Gateway | false |

#### Outputs

| Name | Type | Description |
|------|------|-------------|
| `vpc_id` | string | ID of the created VPC |
| `public_subnet_ids` | list(string) | IDs of public subnets |
| `private_subnet_ids` | list(string) | IDs of private subnets |
| `nat_gateway_ips` | list(string) | Public IPs of NAT Gateways |

### Cluster Module

#### Input Variables

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `cluster_name` | string | Name of the HPC cluster | "" |
| `environment` | string | Environment name | "dev" |
| `vpc_id` | string | ID of the VPC | "" |
| `subnet_ids` | list(string) | IDs of subnets | [] |
| `instance_type` | string | Instance type for head node | "c5.xlarge" |
| `compute_instance_type` | string | Instance type for compute nodes | "hpc6a.48xlarge" |
| `min_compute_nodes` | number | Minimum number of compute nodes | 0 |
| `max_compute_nodes` | number | Maximum number of compute nodes | 10 |
| `desired_compute_nodes` | number | Desired number of compute nodes | 0 |

#### Outputs

| Name | Type | Description |
|------|------|-------------|
| `cluster_id` | string | ID of the created cluster |
| `head_node_public_ip` | string | Public IP of head node |
| `head_node_private_ip` | string | Private IP of head node |

### Storage Module

#### Input Variables

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `environment` | string | Environment name | "dev" |
| `fsx_storage_capacity` | number | Storage capacity in GB | 1200 |
| `fsx_deployment_type` | string | FSx deployment type | "SCRATCH_2" |
| `fsx_throughput_capacity` | number | FSx throughput capacity | 125 |
| `s3_bucket_name` | string | Name of S3 bucket | "" |
| `s3_lifecycle_days` | number | Days for S3 lifecycle | 30 |

#### Outputs

| Name | Type | Description |
|------|------|-------------|
| `fsx_id` | string | ID of FSx filesystem |
| `fsx_dns_name` | string | DNS name of FSx filesystem |
| `s3_bucket_name` | string | Name of S3 bucket |
| `s3_bucket_arn` | string | ARN of S3 bucket |

## Python API

### Resource Monitor

```python
class ResourceMonitor:
    """Monitor system resources and generate alerts."""
    
    def __init__(self, threshold: float = 80.0) -> None:
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

### Job Manager

```python
class JobManager:
    """Manage HPC jobs and scheduling."""
    
    def __init__(self, cluster_id: str) -> None:
        """
        Initialize job manager.
        
        Args:
            cluster_id: ID of the HPC cluster
        """
        self.cluster_id = cluster_id
        self._jobs: Dict[str, Dict] = {}
    
    def submit_job(
        self,
        script_path: str,
        nodes: int = 1,
        cores_per_node: int = 1,
        memory_per_node: int = 4
    ) -> str:
        """
        Submit a job to the cluster.
        
        Args:
            script_path: Path to job script
            nodes: Number of nodes
            cores_per_node: Cores per node
            memory_per_node: Memory per node in GB
            
        Returns:
            Job ID
        """
        job_id = str(uuid.uuid4())
        self._jobs[job_id] = {
            "script": script_path,
            "nodes": nodes,
            "cores": cores_per_node,
            "memory": memory_per_node,
            "status": "PENDING"
        }
        return job_id
    
    def get_job_status(self, job_id: str) -> str:
        """
        Get job status.
        
        Args:
            job_id: ID of the job
            
        Returns:
            Job status
        """
        return self._jobs.get(job_id, {}).get("status", "UNKNOWN")
```

### Data Manager

```python
class DataManager:
    """Manage data storage and transfer."""
    
    def __init__(
        self,
        s3_bucket: str,
        fsx_mount: str
    ) -> None:
        """
        Initialize data manager.
        
        Args:
            s3_bucket: Name of S3 bucket
            fsx_mount: FSx mount point
        """
        self.s3_bucket = s3_bucket
        self.fsx_mount = fsx_mount
        self.s3_client = boto3.client("s3")
    
    def upload_to_s3(
        self,
        local_path: str,
        s3_key: str
    ) -> None:
        """
        Upload file to S3.
        
        Args:
            local_path: Local file path
            s3_key: S3 object key
        """
        self.s3_client.upload_file(
            local_path,
            self.s3_bucket,
            s3_key
        )
    
    def download_from_s3(
        self,
        s3_key: str,
        local_path: str
    ) -> None:
        """
        Download file from S3.
        
        Args:
            s3_key: S3 object key
            local_path: Local file path
        """
        self.s3_client.download_file(
            self.s3_bucket,
            s3_key,
            local_path
        )
```

## CLI API

### Resource Management

```bash
# List resources
hpc-cli list-resources [--type TYPE] [--environment ENV]

# Get resource details
hpc-cli get-resource ID [--format FORMAT]

# Create resource
hpc-cli create-resource TYPE [OPTIONS]

# Delete resource
hpc-cli delete-resource ID [--force]
```

### Job Management

```bash
# Submit job
hpc-cli submit-job SCRIPT [OPTIONS]

# List jobs
hpc-cli list-jobs [--status STATUS]

# Get job status
hpc-cli get-job-status JOB_ID

# Cancel job
hpc-cli cancel-job JOB_ID
```

### Data Management

```bash
# Upload data
hpc-cli upload-data LOCAL_PATH S3_KEY [OPTIONS]

# Download data
hpc-cli download-data S3_KEY LOCAL_PATH [OPTIONS]

# List data
hpc-cli list-data [--prefix PREFIX]
```

## Error Handling

### Common Errors

| Error Code | Description | Resolution |
|------------|-------------|------------|
| `ResourceNotFound` | Resource does not exist | Check resource ID |
| `InvalidParameter` | Invalid parameter value | Check parameter format |
| `AccessDenied` | Insufficient permissions | Check IAM roles |
| `ResourceConflict` | Resource already exists | Use unique identifiers |

### Error Response Format

```json
{
    "error": {
        "code": "ErrorCode",
        "message": "Error message",
        "details": {
            "field": "Additional details"
        }
    }
}
```

## Rate Limits

### API Limits

| Operation | Rate Limit |
|-----------|------------|
| List Resources | 100 requests/minute |
| Create Resource | 10 requests/minute |
| Delete Resource | 10 requests/minute |
| Submit Job | 50 requests/minute |
| Upload Data | 100 requests/minute |

### Throttling

When rate limits are exceeded, the API returns a 429 status code with a retry-after header.

## Authentication

### Required Headers

```http
Authorization: Bearer <token>
X-API-Key: <api-key>
```

### Token Format

```json
{
    "access_token": "jwt-token",
    "expires_in": 3600,
    "token_type": "Bearer"
}
```

## Versioning

### API Version Header

```http
X-API-Version: v1
```

### Version Support

| Version | Status | Deprecation Date |
|---------|--------|------------------|
| v1 | Current | - |
| v0 | Deprecated | 2024-01-01 |

## Examples

### Python Example

```python
from hpc_platform import ResourceMonitor, JobManager, DataManager

# Initialize components
monitor = ResourceMonitor(threshold=80.0)
job_manager = JobManager(cluster_id="cluster-123")
data_manager = DataManager(
    s3_bucket="my-bucket",
    fsx_mount="/fsx"
)

# Monitor resources
monitor.update_metrics({
    "cpu": 75.0,
    "memory": 85.0
})
alerts = monitor.check_alerts()

# Submit job
job_id = job_manager.submit_job(
    script_path="job.sh",
    nodes=2,
    cores_per_node=4
)

# Upload data
data_manager.upload_to_s3(
    local_path="data.csv",
    s3_key="input/data.csv"
)
```

### CLI Example

```bash
# List resources
hpc-cli list-resources --type cluster

# Submit job
hpc-cli submit-job job.sh \
    --nodes 2 \
    --cores-per-node 4 \
    --memory-per-node 8

# Upload data
hpc-cli upload-data data.csv input/data.csv
```

## Support

### Getting Help

- Documentation: https://docs.example.com
- API Reference: https://api.example.com/docs
- Support Email: support@example.com

### Reporting Issues

1. Check existing issues
2. Provide detailed information
3. Include error messages
4. Share reproduction steps 