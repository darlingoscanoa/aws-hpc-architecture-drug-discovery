import os
import subprocess
import boto3

def save_docker_image(image_name: str, output_file: str) -> bool:
    """Save Docker image to a tar file."""
    try:
        subprocess.run(['docker', 'save', '-o', output_file, image_name], check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error saving Docker image: {e}")
        return False

def upload_to_s3(file_path: str, bucket: str, s3_key: str) -> bool:
    """Upload file to S3."""
    try:
        s3_client = boto3.client('s3')
        s3_client.upload_file(file_path, bucket, s3_key)
        return True
    except Exception as e:
        print(f"Error uploading to S3: {e}")
        return False

def main():
    # Configuration
    image_name = "drug-discovery-training:latest"
    tar_file = "drug-discovery-training.tar"
    bucket_name = "hpc-drug-discovery-data-2025"
    s3_key = "docker/drug-discovery-training.tar"
    
    print(f"Saving Docker image {image_name} to {tar_file}...")
    if not save_docker_image(image_name, tar_file):
        return
    
    print(f"Uploading {tar_file} to s3://{bucket_name}/{s3_key}...")
    if not upload_to_s3(tar_file, bucket_name, s3_key):
        return
    
    print("Successfully uploaded Docker image to S3!")
    
    # Clean up local tar file
    os.remove(tar_file)
    print(f"Cleaned up local file: {tar_file}")

if __name__ == "__main__":
    main()
