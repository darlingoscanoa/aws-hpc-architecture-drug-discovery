#!/bin/bash
set -e

# Download data from S3 if S3_BUCKET is set
if [ ! -z "$S3_BUCKET" ]; then
    echo "Downloading data from S3 bucket: $S3_BUCKET"
    aws s3 sync s3://$S3_BUCKET/data/ $DATA_DIR/
fi

# Run the training script
echo "Starting training..."
python3 src/training/train.py
