import os
import shutil
import pandas as pd
import boto3
from pathlib import Path
from tqdm import tqdm

# Configuration
SOURCE_DIR = r"C:\Users\darli\Downloads\human-protein-atlas-image-classification"
SUBSET_DIR = "data/subset"
S3_BUCKET = "hpc-drug-discovery-data-2025"

def create_balanced_subset(fraction=0.01):
    """Create a balanced subset ensuring representation from all classes"""
    print("Reading train.csv...")
    train_df = pd.read_csv(os.path.join(SOURCE_DIR, "train.csv"))
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
    
    # Create directories
    os.makedirs(SUBSET_DIR, exist_ok=True)
    os.makedirs(os.path.join(SUBSET_DIR, "train"), exist_ok=True)
    
    # Save subset metadata
    subset_train.to_csv(os.path.join(SUBSET_DIR, "train_subset.csv"), index=False)
    
    # Copy selected images
    print("\nCopying selected images...")
    for img_id in tqdm(selected_ids):
        for color in ['red', 'green', 'blue', 'yellow']:
            src = os.path.join(SOURCE_DIR, "train", f"{img_id}_{color}.png")
            dst = os.path.join(SUBSET_DIR, "train", f"{img_id}_{color}.png")
            if os.path.exists(src):
                shutil.copy2(src, dst)
            else:
                print(f"Warning: Missing {src}")
    
    return subset_train

def upload_to_s3():
    """Upload the subset to S3"""
    print("\nUploading to S3...")
    s3 = boto3.client('s3')
    
    # Upload the CSV file
    print("Uploading metadata...")
    s3.upload_file(
        os.path.join(SUBSET_DIR, "train_subset.csv"),
        S3_BUCKET,
        'human_protein_atlas/train_subset.csv'
    )
    
    # Upload all images
    print("Uploading images...")
    image_files = list(Path(os.path.join(SUBSET_DIR, "train")).glob("*.png"))
    for img_file in tqdm(image_files):
        s3.upload_file(
            str(img_file),
            S3_BUCKET,
            f'human_protein_atlas/train/{img_file.name}'
        )

def main():
    # Install tqdm if not present
    try:
        import tqdm
    except ImportError:
        import subprocess
        subprocess.check_call(['pip', 'install', 'tqdm'])
    
    print("Creating balanced subset...")
    subset_df = create_balanced_subset(fraction=0.01)
    
    print("\nSubset Statistics:")
    print(f"Total samples: {len(subset_df)}")
    
    # Count and display samples per class
    class_counts = {}
    for class_id in range(28):
        count = sum(1 for targets in subset_df['Target'] if class_id in targets)
        class_counts[class_id] = count
        print(f"Class {class_id}: {count} samples")
    
    # Save statistics to a file
    with open(os.path.join(SUBSET_DIR, 'subset_statistics.txt'), 'w') as f:
        f.write(f"Total samples in subset: {len(subset_df)}\n\n")
        f.write("Samples per class:\n")
        for class_id, count in class_counts.items():
            f.write(f"Class {class_id}: {count} samples\n")
    
    print(f"\nSubset has been created in: {os.path.abspath(SUBSET_DIR)}")
    print("To upload to S3, please configure AWS credentials and run:")
    print(f"aws s3 sync {os.path.abspath(SUBSET_DIR)} s3://{S3_BUCKET}/human_protein_atlas/")

if __name__ == "__main__":
    main()
