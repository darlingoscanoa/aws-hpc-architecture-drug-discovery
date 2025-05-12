# Configuration
$AWS_REGION = "us-east-1"

# Function to test an image locally
function Test-Image {
    param(
        [string]$ImageName,
        [string]$TestCmd,
        [string]$TestArgs = ""
    )
    
    Write-Host "Testing $ImageName..."
    try {
        docker run --rm ${ImageName}:latest $TestCmd $TestArgs
        Write-Host "✅ $ImageName test passed"
        return $true
    } catch {
        Write-Host "❌ $ImageName test failed"
        Write-Host $_.Exception.Message
        return $false
    }
}

# Function to build and test an image locally
function Build-And-Test {
    param(
        [string]$ImageName,
        [string]$Dockerfile,
        [string]$TestCmd,
        [string]$TestArgs = ""
    )

    Write-Host "Building $ImageName..."
    docker build -t ${ImageName}:latest -f $Dockerfile .
    
    Test-Image -ImageName $ImageName -TestCmd $TestCmd -TestArgs $TestArgs
}

# Function to push image to ECR
function Push-To-ECR {
    param(
        [string]$ImageName,
        [string]$AwsAccountId
    )
    
    Write-Host "Pushing $ImageName to ECR..."
    docker tag ${ImageName}:latest ${AwsAccountId}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ImageName}:latest
    docker push ${AwsAccountId}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ImageName}:latest
}

# Build and test images locally first
Write-Host "Building and testing images locally..."

Write-Host "Processing training image..."
Build-And-Test -ImageName "hpc-drug-discovery-repo" -Dockerfile "docker/training/Dockerfile" -TestCmd "python" -TestArgs "-c 'import tensorflow; print(\"TensorFlow available\")'"

Write-Host "Processing inference image..."
Build-And-Test -ImageName "hpc-drug-discovery-inference" -Dockerfile "docker/inference/Dockerfile" -TestCmd "python" -TestArgs "-c 'import streamlit; print(\"Streamlit available\")'"

# If AWS account ID is provided, push to ECR
if ($args.Count -gt 0) {
    $AWS_ACCOUNT_ID = $args[0]
    
    # Login to ECR
    Write-Host "Logging into ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    
    # Push images to ECR
    Push-To-ECR -ImageName "hpc-drug-discovery-repo" -AwsAccountId $AWS_ACCOUNT_ID
    Push-To-ECR -ImageName "hpc-drug-discovery-inference" -AwsAccountId $AWS_ACCOUNT_ID
    
    Write-Host "Done! Images pushed to ECR successfully."
} else {
    Write-Host "No AWS account ID provided. Images built and tested locally only."
    Write-Host "To push to ECR, run: $($MyInvocation.MyCommand.Name) <aws-account-id>"
}
