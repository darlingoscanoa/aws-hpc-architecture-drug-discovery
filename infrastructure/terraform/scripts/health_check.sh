#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting HPC Infrastructure Health Check...${NC}"

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        exit 1
    fi
}

# Check required commands
check_command aws
check_command jq
check_command curl

# Get cluster information from Terraform output
echo -e "${YELLOW}Retrieving cluster information...${NC}"
CLUSTER_ID=$(terraform output -json | jq -r .cluster_id.value)
HEAD_NODE_IP=$(terraform output -json | jq -r .head_node_public_ip.value)
FSX_DNS=$(terraform output -json | jq -r .fsx_dns_name.value)

# Check AWS ParallelCluster status
echo -e "${YELLOW}Checking AWS ParallelCluster status...${NC}"
CLUSTER_STATUS=$(aws pcluster describe-cluster --cluster-id $CLUSTER_ID --query 'cluster.status' --output text)
if [ "$CLUSTER_STATUS" != "CREATE_COMPLETE" ]; then
    echo -e "${RED}Error: Cluster is not in CREATE_COMPLETE status. Current status: $CLUSTER_STATUS${NC}"
    exit 1
fi
echo -e "${GREEN}Cluster status: $CLUSTER_STATUS${NC}"

# Check head node connectivity
echo -e "${YELLOW}Checking head node connectivity...${NC}"
if ! curl -s -o /dev/null -w "%{http_code}" http://$HEAD_NODE_IP:8080 > /dev/null; then
    echo -e "${RED}Error: Cannot connect to head node${NC}"
    exit 1
fi
echo -e "${GREEN}Head node is accessible${NC}"

# Check FSx for Lustre status
echo -e "${YELLOW}Checking FSx for Lustre status...${NC}"
FSX_STATUS=$(aws fsx describe-file-systems --filters "Name=DNSName,Values=$FSX_DNS" --query 'FileSystems[0].Lifecycle' --output text)
if [ "$FSX_STATUS" != "AVAILABLE" ]; then
    echo -e "${RED}Error: FSx filesystem is not AVAILABLE. Current status: $FSX_STATUS${NC}"
    exit 1
fi
echo -e "${GREEN}FSx status: $FSX_STATUS${NC}"

# Check compute nodes
echo -e "${YELLOW}Checking compute nodes...${NC}"
COMPUTE_NODES=$(aws pcluster describe-cluster --cluster-id $CLUSTER_ID --query 'cluster.computeFleetStatus' --output text)
if [ "$COMPUTE_NODES" != "RUNNING" ]; then
    echo -e "${RED}Error: Compute nodes are not RUNNING. Current status: $COMPUTE_NODES${NC}"
    exit 1
fi
echo -e "${GREEN}Compute nodes status: $COMPUTE_NODES${NC}"

# Check S3 bucket
echo -e "${YELLOW}Checking S3 bucket...${NC}"
S3_BUCKET=$(terraform output -json | jq -r .s3_bucket_name.value)
if ! aws s3 ls s3://$S3_BUCKET > /dev/null; then
    echo -e "${RED}Error: Cannot access S3 bucket${NC}"
    exit 1
fi
echo -e "${GREEN}S3 bucket is accessible${NC}"

# Check CloudWatch alarms
echo -e "${YELLOW}Checking CloudWatch alarms...${NC}"
ALARM_COUNT=$(aws cloudwatch describe-alarms --query 'MetricAlarms[*].AlarmName' --output text | wc -w)
if [ "$ALARM_COUNT" -eq 0 ]; then
    echo -e "${RED}Error: No CloudWatch alarms found${NC}"
    exit 1
fi
echo -e "${GREEN}Found $ALARM_COUNT CloudWatch alarms${NC}"

# Check Lambda function
echo -e "${YELLOW}Checking Lambda function...${NC}"
LAMBDA_NAME=$(terraform output -json | jq -r .auto_shutdown_lambda_name.value)
LAMBDA_STATUS=$(aws lambda get-function --function-name $LAMBDA_NAME --query 'Configuration.State' --output text)
if [ "$LAMBDA_STATUS" != "Active" ]; then
    echo -e "${RED}Error: Lambda function is not Active. Current status: $LAMBDA_STATUS${NC}"
    exit 1
fi
echo -e "${GREEN}Lambda function status: $LAMBDA_STATUS${NC}"

# Check VPC endpoints
echo -e "${YELLOW}Checking VPC endpoints...${NC}"
VPC_ID=$(terraform output -json | jq -r .vpc_id.value)
ENDPOINT_COUNT=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --query 'VpcEndpoints[*].VpcEndpointId' --output text | wc -w)
if [ "$ENDPOINT_COUNT" -lt 2 ]; then
    echo -e "${RED}Error: Insufficient VPC endpoints found${NC}"
    exit 1
fi
echo -e "${GREEN}Found $ENDPOINT_COUNT VPC endpoints${NC}"

echo -e "${GREEN}Health check completed successfully!${NC}"
exit 0 