#!/bin/bash
set -e

# Configuration
AWS_REGION="us-east-1"

# Function to test an image locally
test_image() {
    local image_name=$1
    local test_cmd=$2
    local test_args=${3:-""}
    
    echo "Testing $image_name..."
    if docker run --rm $image_name:latest $test_cmd $test_args; then
        echo "✅ $image_name test passed"
        return 0
    else
        echo "❌ $image_name test failed"
        return 1
    fi
}

# Function to build and test an image locally
build_and_test() {
    local image_name=$1
    local dockerfile=$2
    local test_cmd=$3
    local test_args=${4:-""}

    echo "Building $image_name..."
    docker build -t $image_name:latest -f $dockerfile .
    
    test_image $image_name "$test_cmd" "$test_args"
}

# Function to push image to ECR
push_to_ecr() {
    local image_name=$1
    local aws_account_id=$2
    
    echo "Pushing $image_name to ECR..."
    docker tag $image_name:latest $aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com/$image_name:latest
    docker push $aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com/$image_name:latest
}

# Build and test images locally first
echo "Building and testing images locally..."

echo "Processing training image..."
build_and_test "hpc-drug-discovery-repo" "docker/training/Dockerfile" "python" "-c 'import tensorflow; print(\"TensorFlow available\")'"

echo "Processing inference image..."
build_and_test "hpc-drug-discovery-inference" "docker/inference/Dockerfile" "python" "-c 'import streamlit; print(\"Streamlit available\")'"

# If AWS account ID is provided, push to ECR
if [ ! -z "$1" ]; then
    AWS_ACCOUNT_ID=$1
    
    # Login to ECR
    echo "Logging into ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    
    # Push images to ECR
    push_to_ecr "hpc-drug-discovery-repo" $AWS_ACCOUNT_ID
    push_to_ecr "hpc-drug-discovery-inference" $AWS_ACCOUNT_ID
    
    echo "Done! Images pushed to ECR successfully."
else
    echo "No AWS account ID provided. Images built and tested locally only."
    echo "To push to ECR, run: $0 <aws-account-id>"
fi

