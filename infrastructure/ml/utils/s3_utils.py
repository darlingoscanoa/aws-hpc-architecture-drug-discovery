import boto3
import os
import torch
import matplotlib.pyplot as plt
import io
from PIL import Image
import numpy as np

s3_client = boto3.client('s3')
bucket_name = os.environ.get('S3_BUCKET')

def save_model_to_s3(model_state, optimizer_state, epoch, loss, model_name):
    """Save model checkpoint to S3"""
    checkpoint = {
        'epoch': epoch,
        'model_state_dict': model_state,
        'optimizer_state_dict': optimizer_state,
        'loss': loss,
    }
    
    buffer = io.BytesIO()
    torch.save(checkpoint, buffer)
    buffer.seek(0)
    
    s3_client.upload_fileobj(
        buffer,
        bucket_name,
        f'models/trained/{model_name}_epoch_{epoch}.pt'
    )

def load_model_from_s3(model_name):
    """Load latest model from S3"""
    response = s3_client.list_objects_v2(
        Bucket=bucket_name,
        Prefix=f'models/trained/{model_name}'
    )
    
    if 'Contents' not in response:
        raise FileNotFoundError("No trained models found in S3")
    
    # Get the latest model file
    latest_model = max(response['Contents'], key=lambda x: x['LastModified'])
    
    # Download the model file
    buffer = io.BytesIO()
    s3_client.download_fileobj(bucket_name, latest_model['Key'], buffer)
    buffer.seek(0)
    
    return torch.load(buffer)

def save_molecule_image(image_tensor, filename, folder='training_samples'):
    """Save molecule visualization to S3"""
    # Convert tensor to numpy and scale to 0-255
    image_np = image_tensor.detach().cpu().numpy()
    image_np = (image_np * 255).astype(np.uint8)
    
    # Create a figure and plot the molecule
    plt.figure(figsize=(10, 10))
    plt.imshow(image_np.reshape(32, 32), cmap='viridis')
    plt.axis('off')
    
    # Save to buffer
    buffer = io.BytesIO()
    plt.savefig(buffer, format='png', bbox_inches='tight', pad_inches=0)
    plt.close()
    buffer.seek(0)
    
    # Upload to S3
    s3_client.upload_fileobj(
        buffer,
        bucket_name,
        f'images/{folder}/{filename}.png'
    )

def save_training_sample_images(batch, epoch, num_samples=5):
    """Save multiple training samples"""
    for i in range(min(num_samples, len(batch))):
        save_molecule_image(
            batch[i],
            f'epoch_{epoch}_sample_{i}',
            'training_samples'
        )

def save_inference_images(predictions, num_samples=5):
    """Save multiple inference results"""
    for i in range(min(num_samples, len(predictions))):
        save_molecule_image(
            predictions[i],
            f'prediction_{i}',
            'inference_results'
        )
