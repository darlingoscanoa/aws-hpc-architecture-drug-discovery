# Testing Guide

This document outlines the testing strategy and procedures for the AWS HPC Drug Discovery Platform.

## Testing Strategy

Our testing strategy includes:

1. **Unit Tests**
   - Individual component testing
   - Mock AWS services
   - Fast execution

2. **Integration Tests**
   - Component interaction testing
   - AWS service integration
   - End-to-end workflows

3. **Infrastructure Tests**
   - Terraform validation
   - Resource verification
   - Security compliance

## Test Structure

```
tests/
├── unit/
│   ├── test_infrastructure.py
│   ├── test_monitoring.py
│   └── test_security.py
├── integration/
│   ├── test_deployment.py
│   └── test_workflows.py
└── infrastructure/
    ├── test_terraform.py
    └── test_aws.py
```

## Unit Testing

### Infrastructure Tests

```python
def test_vpc_exists(terraform_output):
    """Test that VPC exists and is properly configured."""
    vpc_id = terraform_output['outputs']['vpc_id']['value']
    response = ec2.describe_vpcs(VpcIds=[vpc_id])
    assert len(response['Vpcs']) == 1
```

### Monitoring Tests

```python
def test_cloudwatch_alarms(terraform_output):
    """Test that CloudWatch alarms are configured."""
    response = cloudwatch.describe_alarms()
    assert len(response['MetricAlarms']) > 0
```

### Security Tests

```python
def test_security_groups(terraform_output):
    """Test that security groups are properly configured."""
    vpc_id = terraform_output['outputs']['vpc_id']['value']
    response = ec2.describe_security_groups(
        Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}]
    )
    assert len(response['SecurityGroups']) >= 2
```

## Integration Testing

### Deployment Tests

```python
def test_cluster_deployment(terraform_output):
    """Test that cluster is deployed correctly."""
    cluster_id = terraform_output['outputs']['cluster_id']['value']
    response = pcluster.describe_cluster(ClusterId=cluster_id)
    assert response['cluster']['status'] == 'CREATE_COMPLETE'
```

### Workflow Tests

```python
def test_job_submission():
    """Test job submission workflow."""
    # Submit test job
    job_id = submit_test_job()
    # Verify job status
    assert get_job_status(job_id) == 'COMPLETED'
```

## Infrastructure Testing

### Terraform Tests

```python
def test_terraform_validation():
    """Test Terraform configuration."""
    result = subprocess.run(
        ['terraform', 'validate'],
        capture_output=True,
        text=True
    )
    assert result.returncode == 0
```

### AWS Resource Tests

```python
def test_aws_resources():
    """Test AWS resource configuration."""
    # Test VPC
    test_vpc_configuration()
    # Test Security Groups
    test_security_groups()
    # Test IAM Roles
    test_iam_roles()
```

## Test Execution

### Local Testing

1. Run all tests:
   ```bash
   pytest
   ```

2. Run specific test file:
   ```bash
   pytest tests/unit/test_infrastructure.py
   ```

3. Run with coverage:
   ```bash
   pytest --cov=src/
   ```

### CI/CD Testing

1. Automated test execution
2. Coverage reporting
3. Test results storage

## Mocking

### AWS Service Mocking

```python
@mock_ec2
def test_vpc_creation():
    """Test VPC creation with mocked EC2."""
    ec2 = boto3.client('ec2')
    response = ec2.create_vpc(CidrBlock='10.0.0.0/16')
    assert response['Vpc']['CidrBlock'] == '10.0.0.0/16'
```

### Terraform Mocking

```python
def test_terraform_output():
    """Test Terraform output with mocked state."""
    mock_state = {
        'outputs': {
            'vpc_id': {'value': 'vpc-123456'}
        }
    }
    with patch('builtins.open', mock_open(read_data=json.dumps(mock_state))):
        output = load_terraform_output()
        assert output['outputs']['vpc_id']['value'] == 'vpc-123456'
```

## Test Data

### Test Fixtures

```python
@pytest.fixture
def terraform_output():
    """Fixture for Terraform output."""
    return {
        'outputs': {
            'vpc_id': {'value': 'vpc-123456'},
            'cluster_id': {'value': 'cluster-123456'}
        }
    }
```

### Test Configuration

```python
@pytest.fixture
def aws_credentials():
    """Fixture for AWS credentials."""
    return {
        'aws_access_key_id': 'test-key',
        'aws_secret_access_key': 'test-secret',
        'region_name': 'us-east-1'
    }
```

## Coverage Requirements

1. **Minimum Coverage**
   - Overall: 90%
   - Critical paths: 100%

2. **Coverage Reports**
   - HTML report
   - XML report for CI/CD
   - Coverage badges

## Best Practices

1. **Test Organization**
   - Clear test names
   - Logical grouping
   - Proper documentation

2. **Test Independence**
   - No test dependencies
   - Clean test environment
   - Proper cleanup

3. **Performance**
   - Fast execution
   - Efficient mocking
   - Resource cleanup

4. **Maintenance**
   - Regular updates
   - Dependency updates
   - Code review

## Troubleshooting

### Common Issues

1. **Test Failures**
   - Check error messages
   - Verify test data
   - Review dependencies

2. **Coverage Issues**
   - Review uncovered code
   - Add missing tests
   - Update coverage config

3. **Mocking Issues**
   - Verify mock setup
   - Check mock responses
   - Review mock scope

### Support

- GitHub Issues
- Development team
- Documentation

## Future Improvements

1. **Test Coverage**
   - Add more test cases
   - Improve coverage
   - Add performance tests

2. **Test Automation**
   - Automated test generation
   - Better mocking
   - Faster execution

3. **Test Infrastructure**
   - Better test organization
   - Improved fixtures
   - Enhanced reporting 