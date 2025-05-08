import os
import boto3
from pathlib import Path
from tqdm import tqdm

def upload_directory_to_s3(local_dir, bucket_name, s3_prefix):
    """Upload a directory to S3 directly"""
    # Initialize S3 client with credentials
    s3 = boto3.client(
        's3',
        aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
        aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
        region_name='us-east-1'
    )
    
    local_dir = Path(local_dir)
    
    # Get all files
    all_files = list(local_dir.rglob("*"))
    files_to_upload = [f for f in all_files if f.is_file()]
    
    print(f"Found {len(files_to_upload)} files to upload")
    
    # Upload each file
    for file_path in tqdm(files_to_upload):
        # Calculate S3 key
        relative_path = file_path.relative_to(local_dir)
        s3_key = f"{s3_prefix}/{relative_path}".replace("\\", "/")
        
        try:
            s3.upload_file(
                str(file_path),
                bucket_name,
                s3_key
            )
        except Exception as e:
            print(f"Error uploading {file_path}: {e}")

if __name__ == "__main__":
    # Upload the subset directory
    upload_directory_to_s3(
        local_dir="data/subset",
        bucket_name="hpc-drug-discovery-data-2025",
        s3_prefix="human_protein_atlas"
    )
