import torch
import torch.nn as nn
import logging
import time
from datetime import datetime
import os
import boto3
from utils.s3_utils import load_model_from_s3, save_inference_images

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

def load_model(device):
    model = DrugDiscoveryModel().to(device)
    checkpoint = load_model_from_s3('drug_discovery')
    model.load_state_dict(checkpoint['model_state_dict'])
    model.eval()
    return model

def run_inference(model, input_data, device):
    with torch.no_grad():
        input_data = input_data.to(device)
        output = model(input_data)
        
        # Log inference metrics to CloudWatch
        cw_client.put_metric_data(
            Namespace='DrugDiscovery',
            MetricData=[
                {
                    'MetricName': 'GPUMemoryUsed',
                    'Value': torch.cuda.memory_allocated()/1e9,
                    'Unit': 'Gigabytes',
                    'Timestamp': datetime.now()
                },
                {
                    'MetricName': 'InferenceBatchSize',
                    'Value': len(input_data),
                    'Unit': 'Count',
                    'Timestamp': datetime.now()
                }
            ]
        )
        
        return output

def main():
    # Set device
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    logger.info(f"Using device: {device}")
    
    # Load the latest model from S3
    logger.info("Loading latest model from S3")
    model = load_model(device)
    
    # Generate dummy inference data
    # In reality, this would be your actual molecule data
    test_data = torch.randn(100, 1024)
    
    # Run inference in batches
    batch_size = 10
    all_predictions = []
    
    for i in range(0, len(test_data), batch_size):
        batch = test_data[i:i+batch_size]
        predictions = run_inference(model, batch, device)
        all_predictions.append(predictions)
        logger.info(f"Processed batch {i//batch_size + 1}")
    
    # Combine all predictions
    all_predictions = torch.cat(all_predictions, dim=0)
    
    # Save inference results
    save_inference_images(all_predictions)
    logger.info("Saved inference results to S3")

if __name__ == "__main__":
    main()
