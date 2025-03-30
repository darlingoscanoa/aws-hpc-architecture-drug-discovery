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
COPY models/ models/

# Set environment variables
ENV PYTHONPATH=/app
ENV MODEL_PATH=/app/models/best_model.pt
ENV MODEL_NAME=lightweight
ENV NUM_CLASSES=28

# Expose Streamlit port
EXPOSE 8501

# Run Streamlit app
CMD ["streamlit", "run", "src/inference/app.py", "--server.address=0.0.0.0"] 