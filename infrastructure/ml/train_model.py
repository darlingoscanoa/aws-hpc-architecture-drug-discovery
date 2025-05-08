import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
import numpy as np
import os
import logging
import time
from datetime import datetime
import boto3
from utils.s3_utils import save_model_to_s3, save_training_sample_images

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configure CloudWatch metrics
cw_client = boto3.client('cloudwatch')

class DrugDiscoveryModel(nn.Module):
    def __init__(self):
        super(DrugDiscoveryModel, self).__init__()
        self.encoder = nn.Sequential(
            nn.Linear(1024, 512),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(512, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, 128)
        )
        
        self.decoder = nn.Sequential(
            nn.Linear(128, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, 512),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(512, 1024),
            nn.Sigmoid()
        )

    def forward(self, x):
        x = self.encoder(x)
        x = self.decoder(x)
        return x

def train_model(model, train_loader, optimizer, criterion, device, epoch):
    model.train()
    running_loss = 0.0
    for i, (inputs, _) in enumerate(train_loader):
        inputs = inputs.to(device)
        
        # Forward pass
        outputs = model(inputs)
        loss = criterion(outputs, inputs)
        
        # Backward pass and optimize
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        
        running_loss += loss.item()
        
        if i % 10 == 0:
            logger.info(f'Epoch [{epoch}], Step [{i}], Loss: {loss.item():.4f}')
            
            # Log metrics to CloudWatch
            cw_client.put_metric_data(
                Namespace='DrugDiscovery',
                MetricData=[
                    {
                        'MetricName': 'TrainingLoss',
                        'Value': loss.item(),
                        'Unit': 'None',
                        'Timestamp': datetime.now()
                    },
                    {
                        'MetricName': 'GPUMemoryUsed',
                        'Value': torch.cuda.memory_allocated()/1e9,
                        'Unit': 'Gigabytes',
                        'Timestamp': datetime.now()
                    }
                ]
            )
            
            # Save sample images every 50 batches
            if i % 50 == 0:
                save_training_sample_images(inputs, epoch)
    
    return running_loss / len(train_loader)

def main():
    # Set device
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    logger.info(f"Using device: {device}")
    
    # Create model
    model = DrugDiscoveryModel().to(device)
    
    # Generate dummy data for demonstration
    # In reality, this would be loaded from your dataset
    dummy_data = torch.randn(1000, 1024)
    dataset = torch.utils.data.TensorDataset(dummy_data, dummy_data)
    train_loader = DataLoader(dataset, batch_size=32, shuffle=True)
    
    # Training parameters
    criterion = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=0.001)
    num_epochs = 10
    
    # Training loop
    for epoch in range(num_epochs):
        loss = train_model(model, train_loader, optimizer, criterion, device, epoch)
        logger.info(f'Epoch [{epoch}/{num_epochs}], Loss: {loss:.4f}')
        
        # Save checkpoint to S3
        if (epoch + 1) % 5 == 0:
            save_model_to_s3(
                model.state_dict(),
                optimizer.state_dict(),
                epoch,
                loss,
                'drug_discovery'
            )
            logger.info(f"Checkpoint saved to S3: epoch {epoch+1}")

if __name__ == "__main__":
    main()
