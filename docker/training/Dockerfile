# Use an official Python runtime as a parent image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the project code
COPY src/ ./src/
COPY data/ ./data/

# Set environment variables
ENV PYTHONPATH=/app
ENV MLFLOW_TRACKING_URI=http://mlflow:5000

# Command to run the training script
CMD ["python", "src/training/train.py"] 