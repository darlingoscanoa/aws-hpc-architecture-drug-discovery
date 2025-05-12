# Use NVIDIA CUDA base image for GPU support
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.docker.txt .

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.docker.txt \
    && pip3 install --no-cache-dir boto3 awscli streamlit

# Copy only the source code (model will be downloaded from S3)
COPY src/ ./src/

# Set environment variables
ENV PYTHONPATH=/app
# These will be overridden by AWS Batch environment variables
ENV AWS_DEFAULT_REGION=us-east-1
ENV MLFLOW_TRACKING_URI=''
ENV S3_BUCKET=''
ENV MODEL_DIR='/app/models'
ENV PORT=8501

# Create model directory
RUN mkdir -p /app/models

# Copy entrypoint script
COPY docker/inference/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port for Streamlit
EXPOSE 8501

ENTRYPOINT ["/entrypoint.sh"]