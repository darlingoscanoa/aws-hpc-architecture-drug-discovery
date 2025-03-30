import pytest
import boto3
import json
from pathlib import Path

# AWS clients
ec2 = boto3.client('ec2')
fsx = boto3.client('fsx')
s3 = boto3.client('s3')
cloudwatch = boto3.client('cloudwatch')
lambda_client = boto3.client('lambda')

def load_terraform_output():
    """Load Terraform output from JSON file."""
    output_file = Path('infrastructure/terraform/terraform.tfstate')
    if not output_file.exists():
        pytest.skip("Terraform state file not found")
    with open(output_file) as f:
        return json.load(f)

@pytest.fixture
def terraform_output():
    """Fixture to provide Terraform output."""
    return load_terraform_output()

def test_vpc_exists(terraform_output):
    """Test that VPC exists and is properly configured."""
    vpc_id = terraform_output['outputs']['vpc_id']['value']
    response = ec2.describe_vpcs(VpcIds=[vpc_id])
    assert len(response['Vpcs']) == 1
    vpc = response['Vpcs'][0]
    assert vpc['CidrBlock'] == '10.0.0.0/16'
    assert vpc['EnableDnsHostnames'] is True
    assert vpc['EnableDnsSupport'] is True

def test_cluster_exists(terraform_output):
    """Test that AWS ParallelCluster exists."""
    cluster_id = terraform_output['outputs']['cluster_id']['value']
    response = boto3.client('pcluster').describe_cluster(ClusterId=cluster_id)
    assert response['cluster']['status'] == 'CREATE_COMPLETE'

def test_fsx_exists(terraform_output):
    """Test that FSx for Lustre exists."""
    fsx_dns = terraform_output['outputs']['fsx_dns_name']['value']
    response = fsx.describe_file_systems(Filters=[{'Name': 'DNSName', 'Values': [fsx_dns]}])
    assert len(response['FileSystems']) == 1
    assert response['FileSystems'][0]['Lifecycle'] == 'AVAILABLE'

def test_s3_bucket_exists(terraform_output):
    """Test that S3 bucket exists."""
    bucket_name = terraform_output['outputs']['s3_bucket_name']['value']
    response = s3.head_bucket(Bucket=bucket_name)
    assert response['ResponseMetadata']['HTTPStatusCode'] == 200

def test_cloudwatch_alarms_exist(terraform_output):
    """Test that CloudWatch alarms exist."""
    response = cloudwatch.describe_alarms()
    assert len(response['MetricAlarms']) > 0

def test_lambda_function_exists(terraform_output):
    """Test that Lambda function exists."""
    function_name = terraform_output['outputs']['auto_shutdown_lambda_name']['value']
    response = lambda_client.get_function(FunctionName=function_name)
    assert response['Configuration']['State'] == 'Active'

def test_vpc_endpoints_exist(terraform_output):
    """Test that VPC endpoints exist."""
    vpc_id = terraform_output['outputs']['vpc_id']['value']
    response = ec2.describe_vpc_endpoints(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
    assert len(response['VpcEndpoints']) >= 2

def test_security_groups_exist(terraform_output):
    """Test that security groups exist."""
    vpc_id = terraform_output['outputs']['vpc_id']['value']
    response = ec2.describe_security_groups(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
    assert len(response['SecurityGroups']) >= 2

def test_route_tables_exist(terraform_output):
    """Test that route tables exist."""
    vpc_id = terraform_output['outputs']['vpc_id']['value']
    response = ec2.describe_route_tables(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
    assert len(response['RouteTables']) >= 2

def test_subnets_exist(terraform_output):
    """Test that subnets exist."""
    vpc_id = terraform_output['outputs']['vpc_id']['value']
    response = ec2.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
    assert len(response['Subnets']) >= 2 