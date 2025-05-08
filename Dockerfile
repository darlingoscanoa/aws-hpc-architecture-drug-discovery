# Use NVIDIA PyTorch image as base
FROM nvcr.io/nvidia/pytorch:23.12-py3

# Install additional dependencies
RUN pip install --no-cache-dir \
    boto3 \
    matplotlib \
    pillow

# Set working directory
WORKDIR /app

# Copy the application code
COPY infrastructure/ml /app/

# Set environment variables
ENV PYTHONPATH=/app

# Create entrypoint script
RUN echo '#!/bin/bash\n\
if [ "$1" = "train" ]; then\n\
    python train_model.py\n\
elif [ "$1" = "inference" ]; then\n\
    python inference.py\n\
else\n\
    echo "Invalid command. Use either train or inference"\n\
    exit 1\n\
fi' > /app/entrypoint.sh \
    && chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
