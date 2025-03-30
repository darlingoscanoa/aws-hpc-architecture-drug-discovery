# Use PyTorch base image for GPU support
FROM pytorch/pytorch:1.9.0-cuda11.1-cudnn8-runtime

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
COPY models/ models/

# Set environment variables
ENV PYTHONPATH=/app
ENV PREPROCESSED_DATA_DIR=/app/data/preprocessing
ENV MODEL_SAVE_DIR=/app/models
ENV MODEL_NAME=lightweight
ENV NUM_CLASSES=28
ENV BATCH_SIZE=32
ENV LEARNING_RATE=0.001
ENV NUM_EPOCHS=10

# Run training script
CMD ["python", "src/training/train.py"] 