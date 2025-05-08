import os
import subprocess
import pandas as pd
import boto3
from pathlib import Path
import kaggle
from kaggle.api.kaggle_api_extended import KaggleApi

def setup_kaggle():
    """Setup Kaggle API"""
    api = KaggleApi()
    api.authenticate()
    return api

def download_metadata(api, dataset_name='human-protein-atlas-image-classification'):
    """Download only the CSV files first"""
    print("Downloading metadata...")
    os.makedirs('data/raw', exist_ok=True)
    
    # First try competition data
    try:
        print("Attempting to download from competition...")
        subprocess.check_call([
            'kaggle', 'competitions', 'download',
            '-c', dataset_name,
            '-f', 'train.csv',
            '-p', 'data/raw'
        ])
    except subprocess.CalledProcessError:
        print("Competition download failed, trying dataset...")
        # If that fails, try the dataset
        subprocess.check_call([
            'kaggle', 'datasets', 'download',
            'mathilde-rousseau/' + dataset_name,
            '-f', 'train.csv',
            '-p', 'data/raw'
        ])
    
    print("Extracting train.csv...")
    # Unzip the downloaded file
    try:
        subprocess.check_call(['powershell', 'Expand-Archive', '-Path', 'data/raw/train.csv.zip', '-DestinationPath', 'data/raw', '-Force'])
    except subprocess.CalledProcessError:
        print("Note: train.csv might already be extracted")
        pass

def create_subset(fraction=0.01):
    """Create a balanced subset of the dataset ensuring representation from all classes"""
    print(f"Creating {fraction*100}% subset...")
    
    # Read the training data
    train_df = pd.read_csv('data/raw/train.csv')
    print(f"Total samples in dataset: {len(train_df)}")
    
    # Convert Target string to list of integers
    train_df['Target'] = train_df['Target'].apply(lambda x: [int(i) for i in x.split()])
    
    # Create a balanced subset ensuring we have samples from each class
    selected_ids = set()
    for class_id in range(28):  # 28 classes total
        # Get samples that have this class
        class_samples = train_df[train_df['Target'].apply(lambda x: class_id in x)]
        
        # Select a few samples from this class
        n_samples = max(1, int(len(class_samples) * fraction))
        selected = class_samples.sample(n=min(n_samples, len(class_samples)), random_state=42)
        selected_ids.update(selected['Id'].values)
    
    # Create final subset dataframe
    subset_train = train_df[train_df['Id'].isin(selected_ids)]
    print(f"Selected {len(subset_train)} samples covering all 28 classes")
    
    # Save the subset metadata
    os.makedirs('data/subset', exist_ok=True)
    subset_train.to_csv('data/subset/train_subset.csv', index=False)
    
    return list(selected_ids)

def download_subset_images(api, image_ids, dataset_name='mathilde-rousseau/human-protein-atlas-image-classification'):
    """Download only the images we need"""
    print("Downloading selected images...")
    os.makedirs('data/subset/train', exist_ok=True)
    
    for img_id in image_ids:
        for color in ['red', 'green', 'blue', 'yellow']:
            filename = f'{img_id}_{color}.png'
            try:
                api.dataset_download_file(
                    dataset_name,
                    f'train/{filename}',
                    path='data/subset/train'
                )
                print(f"Downloaded {filename}")
            except Exception as e:
                print(f"Error downloading {filename}: {e}")

def upload_to_s3(bucket_name='hpc-drug-discovery-data-2025'):
    """Upload the subset to S3"""
    s3 = boto3.client('s3')
    
    # Upload the CSV file
    s3.upload_file(
        'data/subset/train_subset.csv',
        bucket_name,
        'human_protein_atlas/train_subset.csv'
    )
    
    # Upload all images
    for img_file in Path('data/subset/train').glob('*.png'):
        s3.upload_file(
            str(img_file),
            bucket_name,
            f'human_protein_atlas/train/{img_file.name}'
        )

def main():
    print("Setting up Kaggle API...")
    api = setup_kaggle()
    
    print("Downloading metadata...")
    download_metadata(api)
    
    print("Creating subset selection...")
    selected_ids = create_subset(fraction=0.01)
    
    print("Downloading images for subset...")
    download_subset_images(api, selected_ids)
    
    print("Uploading to S3...")
    upload_to_s3()
    
    print("Done!")

if __name__ == "__main__":
    main()
