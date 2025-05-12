#!/bin/bash
set -e

# Download model from S3 if S3_BUCKET is set
if [ ! -z "$S3_BUCKET" ]; then
    echo "Downloading model from S3 bucket: $S3_BUCKET"
    aws s3 sync s3://$S3_BUCKET/models/ $MODEL_DIR/
fi

# Run the inference service
echo "Starting inference service..."
streamlit run src/inference/predict.py
