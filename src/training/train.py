"""
Training Script for Protein Atlas Classification

This script handles the training of both the lightweight CNN and ResNet18 models
for protein atlas classification, with MLflow integration for experiment tracking.
"""

import os
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
import numpy as np
from typing import Dict, Tuple, Optional
import mlflow
import logging
from pathlib import Path
from datetime import datetime

from src.models.models import create_model

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ModelTrainer:
    def __init__(self,
                 model_name: str,
                 num_classes: int,
                 batch_size: int = 32,
                 learning_rate: float = 0.001,
                 num_epochs: int = 10,
                 device: Optional[str] = None):
        """
        Initialize the model trainer.
        
        Args:
            model_name: Name of the model to train ('lightweight' or 'resnet18')
            num_classes: Number of output classes
            batch_size: Batch size for training
            learning_rate: Learning rate for optimization
            num_epochs: Number of training epochs
            device: Device to use for training ('cuda' or 'cpu')
        """
        self.model_name = model_name
        self.num_classes = num_classes
        self.batch_size = batch_size
        self.learning_rate = learning_rate
        self.num_epochs = num_epochs
        
        # Set device
        self.device = device or ('cuda' if torch.cuda.is_available() else 'cpu')
        logger.info(f"Using device: {self.device}")
        
        # Create model
        self.model = create_model(model_name, num_classes)
        self.model.to(self.device)
        
        # Set up loss function and optimizer for multi-label classification
        self.criterion = nn.BCEWithLogitsLoss()
        self.optimizer = optim.Adam(self.model.parameters(), lr=learning_rate)
        
        # Initialize best model tracking
        self.best_val_loss = float('inf')
        self.best_model_path = None
        
    def load_data(self, data_dir: str) -> Tuple[DataLoader, DataLoader]:
        """
        Load and prepare the dataset.
        
        Args:
            data_dir: Directory containing the preprocessed data
            
        Returns:
            Tuple of (train_loader, val_loader)
        """
        # Load preprocessed data
        X_train = np.load(os.path.join(data_dir, 'X_train.npy'))
        X_test = np.load(os.path.join(data_dir, 'X_test.npy'))
        y_train = np.load(os.path.join(data_dir, 'y_train.npy'))
        y_test = np.load(os.path.join(data_dir, 'y_test.npy'))
        
        # Convert to PyTorch tensors (using float for multi-label)
        X_train = torch.FloatTensor(X_train)
        X_test = torch.FloatTensor(X_test)
        y_train = torch.FloatTensor(y_train)
        y_test = torch.FloatTensor(y_test)
        
        # Create datasets
        train_dataset = TensorDataset(X_train, y_train)
        test_dataset = TensorDataset(X_test, y_test)
        
        # Create data loaders
        train_loader = DataLoader(
            train_dataset,
            batch_size=self.batch_size,
            shuffle=True,
            num_workers=4
        )
        
        test_loader = DataLoader(
            test_dataset,
            batch_size=self.batch_size,
            shuffle=False,
            num_workers=4
        )
        
        return train_loader, test_loader
    
    def train_epoch(self, train_loader: DataLoader) -> Dict[str, float]:
        """
        Train for one epoch.
        
        Args:
            train_loader: DataLoader for training data
            
        Returns:
            Dictionary of training metrics
        """
        self.model.train()
        total_loss = 0
        correct = 0
        total = 0
        
        for batch_idx, (data, target) in enumerate(train_loader):
            data, target = data.to(self.device), target.to(self.device)
            
            self.optimizer.zero_grad()
            output = self.model(data)
            loss = self.criterion(output, target)
            
            loss.backward()
            self.optimizer.step()
            
            total_loss += loss.item()
            # Multi-label prediction (threshold at 0.5)
            predicted = (output > 0.0).float()
            correct += (predicted == target).all(dim=1).sum().item()
            total += target.size(0)
            
            if batch_idx % 10 == 0:
                logger.info(f'Train Batch: {batch_idx}/{len(train_loader)} '
                          f'Loss: {loss.item():.4f} '
                          f'Acc: {100.*correct/total:.2f}%')
        
        return {
            'train_loss': total_loss / len(train_loader),
            'train_acc': 100. * correct / total
        }
    
    def validate(self, val_loader: DataLoader) -> Dict[str, float]:
        """
        Validate the model.
        
        Args:
            val_loader: DataLoader for validation data
            
        Returns:
            Dictionary of validation metrics
        """
        self.model.eval()
        total_loss = 0
        correct = 0
        total = 0
        
        with torch.no_grad():
            for data, target in val_loader:
                data, target = data.to(self.device), target.to(self.device)
                output = self.model(data)
                loss = self.criterion(output, target)
                
                total_loss += loss.item()
                _, predicted = output.max(1)
                total += target.size(0)
                correct += predicted.eq(target).sum().item()
        
        return {
            'val_loss': total_loss / len(val_loader),
            'val_acc': 100. * correct / total
        }
    
    def save_model(self, epoch: int, metrics: Dict[str, float]):
        """
        Save the best model based on validation loss.
        
        Args:
            epoch: Current epoch number
            metrics: Dictionary of current metrics
        """
        if metrics['val_loss'] < self.best_val_loss:
            self.best_val_loss = metrics['val_loss']
            
            # Create models directory if it doesn't exist
            models_dir = Path(os.getenv('MODEL_SAVE_DIR', 'models'))
            models_dir.mkdir(parents=True, exist_ok=True)
            
            # Save model
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            self.best_model_path = models_dir / f'{self.model_name}_{timestamp}.pt'
            torch.save({
                'epoch': epoch,
                'model_state_dict': self.model.state_dict(),
                'optimizer_state_dict': self.optimizer.state_dict(),
                'metrics': metrics,
            }, self.best_model_path)
            
            logger.info(f"Saved best model to {self.best_model_path}")
    
    def train(self, data_dir: str):
        """
        Train the model.
        
        Args:
            data_dir: Directory containing the preprocessed data
        """
        # Load data
        train_loader, val_loader = self.load_data(data_dir)
        
        # Start MLflow run
        with mlflow.start_run(run_name=f'{self.model_name}_training'):
            # Log parameters
            mlflow.log_params({
                'model_name': self.model_name,
                'num_classes': self.num_classes,
                'batch_size': self.batch_size,
                'learning_rate': self.learning_rate,
                'num_epochs': self.num_epochs,
                'device': self.device
            })
            
            # Training loop
            for epoch in range(1, self.num_epochs + 1):
                logger.info(f"\nEpoch {epoch}/{self.num_epochs}")
                
                # Train
                train_metrics = self.train_epoch(train_loader)
                
                # Validate
                val_metrics = self.validate(val_loader)
                
                # Combine metrics
                metrics = {**train_metrics, **val_metrics}
                
                # Log metrics
                mlflow.log_metrics(metrics, step=epoch)
                
                # Save best model
                self.save_model(epoch, metrics)
                
                # Log progress
                logger.info(f"Epoch {epoch} - "
                          f"Train Loss: {metrics['train_loss']:.4f}, "
                          f"Train Acc: {metrics['train_acc']:.2f}%, "
                          f"Val Loss: {metrics['val_loss']:.4f}, "
                          f"Val Acc: {metrics['val_acc']:.2f}%")
            
            # Log best model
            if self.best_model_path:
                mlflow.log_artifact(str(self.best_model_path))

def main():
    """Main function to run training."""
    # Load configuration
    model_name = os.getenv('MODEL_NAME', 'lightweight')
    num_classes = int(os.getenv('NUM_CLASSES', '28'))  # Default for Human Protein Atlas
    batch_size = int(os.getenv('BATCH_SIZE', '32'))
    learning_rate = float(os.getenv('LEARNING_RATE', '0.001'))
    num_epochs = int(os.getenv('NUM_EPOCHS', '10'))
    
    # Create trainer
    trainer = ModelTrainer(
        model_name=model_name,
        num_classes=num_classes,
        batch_size=batch_size,
        learning_rate=learning_rate,
        num_epochs=num_epochs
    )
    
    # Train model
    trainer.train(os.getenv('PREPROCESSED_DATA_DIR', 'data/preprocessing'))

if __name__ == "__main__":
    main() 