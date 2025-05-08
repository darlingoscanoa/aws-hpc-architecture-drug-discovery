import os
import boto3

def list_s3_files():
    s3 = boto3.client(
        's3',
        aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
        aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
        region_name='us-east-1'
    )
    
    # List objects in the bucket
    response = s3.list_objects_v2(
        Bucket='hpc-drug-discovery-data-2025',
        Prefix='human_protein_atlas/',
        MaxKeys=5
    )
    
    print("First 5 files in the bucket:")
    for obj in response.get('Contents', []):
        print(f"- {obj['Key']}")
    
    # Get total count
    total = s3.list_objects_v2(
        Bucket='hpc-drug-discovery-data-2025',
        Prefix='human_protein_atlas/'
    )['KeyCount']
    
    print(f"\nTotal files in bucket: {total}")

if __name__ == "__main__":
    list_s3_files()
