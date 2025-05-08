# Use a lightweight Python base image
FROM python:3.8-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/ src/
COPY data/ data/

# Set environment variables
ENV PYTHONPATH=/app
ENV RAW_DATA_DIR=/app/data/raw
ENV PREPROCESSED_DATA_DIR=/app/data/preprocessing
ENV DATASET_SIZE=0.1
ENV IMAGE_SIZE=224

# Run preprocessing script
CMD ["python", "src/utils/preprocessing.py"] 