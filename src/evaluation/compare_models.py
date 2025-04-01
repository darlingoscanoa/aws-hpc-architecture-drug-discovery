"""
Model comparison script for drug discovery pipeline using Human Protein Atlas dataset.
This script demonstrates enterprise-grade deep learning model evaluation with comprehensive metrics and visualization.
"""

import os
import time
import logging
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from sklearn.metrics import f1_score, accuracy_score, precision_score, recall_score, confusion_matrix
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
import mlflow
from typing import Dict, Any, List, Tuple
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ProteinDataset(Dataset):
    """
    Custom dataset for protein data.
    """
    def __init__(self, features, labels):
        self.features = torch.FloatTensor(features)
        self.labels = torch.LongTensor(labels)
    
    def __len__(self):
        return len(self.labels)
    
    def __getitem__(self, idx):
        return self.features[idx], self.labels[idx]

class ResBlock(nn.Module):
    """
    Residual block for ResNet architecture.
    """
    def __init__(self, in_channels, out_channels, stride=1):
        super(ResBlock, self).__init__()
        self.conv1 = nn.Conv1d(in_channels, out_channels, kernel_size=3, stride=stride, padding=1)
        self.bn1 = nn.BatchNorm1d(out_channels)
        self.conv2 = nn.Conv1d(out_channels, out_channels, kernel_size=3, padding=1)
        self.bn2 = nn.BatchNorm1d(out_channels)
        
        # Shortcut connection
        self.shortcut = nn.Sequential()
        if stride != 1 or in_channels != out_channels:
            self.shortcut = nn.Sequential(
                nn.Conv1d(in_channels, out_channels, kernel_size=1, stride=stride),
                nn.BatchNorm1d(out_channels)
            )
    
    def forward(self, x):
        out = torch.relu(self.bn1(self.conv1(x)))
        out = self.bn2(self.conv2(out))
        out += self.shortcut(x)
        out = torch.relu(out)
        return out

class ResNet(nn.Module):
    """
    ResNet architecture for protein classification.
    """
    def __init__(self, input_size, num_classes):
        super(ResNet, self).__init__()
        self.in_channels = 64
        
        # Initial convolution
        self.conv1 = nn.Conv1d(1, 64, kernel_size=7, stride=2, padding=3)
        self.bn1 = nn.BatchNorm1d(64)
        self.maxpool = nn.MaxPool1d(kernel_size=3, stride=2, padding=1)
        
        # Residual blocks
        self.layer1 = self.make_layer(64, 2, stride=1)
        self.layer2 = self.make_layer(128, 2, stride=2)
        self.layer3 = self.make_layer(256, 2, stride=2)
        self.layer4 = self.make_layer(512, 2, stride=2)
        
        # Calculate the size of flattened features
        self.flat_size = 512 * (input_size // 32)
        
        # Fully connected layers
        self.fc = nn.Linear(self.flat_size, num_classes)
        self.dropout = nn.Dropout(0.5)
    
    def make_layer(self, out_channels, num_blocks, stride):
        strides = [stride] + [1] * (num_blocks - 1)
        layers = []
        for stride in strides:
            layers.append(ResBlock(self.in_channels, out_channels, stride))
            self.in_channels = out_channels
        return nn.Sequential(*layers)
    
    def forward(self, x):
        # Add channel dimension
        x = x.unsqueeze(1)
        
        # Initial layers
        out = self.conv1(x)
        out = self.bn1(out)
        out = torch.relu(out)
        out = self.maxpool(out)
        
        # Residual blocks
        out = self.layer1(out)
        out = self.layer2(out)
        out = self.layer3(out)
        out = self.layer4(out)
        
        # Flatten
        out = out.view(-1, self.flat_size)
        
        # Fully connected layer
        out = self.dropout(out)
        out = self.fc(out)
        
        return out

class ModelEvaluator:
    """
    Enterprise-grade model evaluator with comprehensive metrics and visualization.
    """
    
    def __init__(self, input_size: int, num_classes: int, device: torch.device):
        """
        Initialize the evaluator with models to compare.
        Args:
            input_size: Size of input features
            num_classes: Number of classes
            device: PyTorch device (CPU/GPU)
        """
        self.device = device
        self.models = {
            "Lightweight CNN": LightweightCNN(input_size, num_classes).to(device),
            "ResNet": ResNet(input_size, num_classes).to(device)
        }
        self.scaler = StandardScaler()
        self.results = {}
    
    def load_data(self, data_dir: str = "data/raw") -> Tuple[np.ndarray, np.ndarray]:
        """
        Load the Human Protein Atlas dataset.
        Args:
            data_dir: Directory containing the dataset
        Returns:
            Tuple of (X, y)
        """
        try:
            logger.info(f"Loading data from {data_dir}")
            
            # Load protein data
            protein_data = pd.read_csv(os.path.join(data_dir, "protein_data.csv"))
            
            # Load labels
            labels = pd.read_csv(os.path.join(data_dir, "labels.csv"))
            
            # Merge data and labels
            data = protein_data.merge(labels, on="protein_id")
            
            # Prepare features and target
            X = data.drop(["protein_id", "target"], axis=1)
            y = data["target"]
            
            # Scale features
            X = self.scaler.fit_transform(X)
            
            logger.info(f"Loaded {len(X)} samples with {X.shape[1]} features")
            
            return X, y
            
        except Exception as e:
            logger.error(f"Error loading data: {str(e)}")
            raise
    
    def train_and_evaluate(self, X_train: np.ndarray, X_test: np.ndarray, 
                          y_train: np.ndarray, y_test: np.ndarray) -> Dict[str, Any]:
        """
        Train and evaluate all models.
        Args:
            X_train: Training features
            X_test: Test features
            y_train: Training labels
            y_test: Test labels
        Returns:
            Dictionary of results
        """
        results = {}
        
        # Create data loaders
        train_dataset = ProteinDataset(X_train, y_train)
        test_dataset = ProteinDataset(X_test, y_test)
        train_loader = DataLoader(train_dataset, batch_size=32, shuffle=True)
        test_loader = DataLoader(test_dataset, batch_size=32)
        
        for name, model in self.models.items():
            logger.info(f"Training {name}...")
            
            # Initialize optimizer and criterion
            optimizer = optim.Adam(model.parameters(), lr=0.001)
            criterion = nn.CrossEntropyLoss()
            
            # Training loop
            best_f1 = 0
            training_time = 0
            for epoch in range(50):
                epoch_start = time.time()
                
                # Training phase
                model.train()
                for batch_features, batch_labels in train_loader:
                    batch_features, batch_labels = batch_features.to(self.device), batch_labels.to(self.device)
                    
                    optimizer.zero_grad()
                    outputs = model(batch_features)
                    loss = criterion(outputs, batch_labels)
                    loss.backward()
                    optimizer.step()
                
                # Evaluation phase
                model.eval()
                all_preds = []
                all_labels = []
                with torch.no_grad():
                    for batch_features, batch_labels in test_loader:
                        batch_features = batch_features.to(self.device)
                        outputs = model(batch_features)
                        _, preds = torch.max(outputs, 1)
                        all_preds.extend(preds.cpu().numpy())
                        all_labels.extend(batch_labels.numpy())
                
                # Calculate metrics
                metrics = {
                    "f1_score": f1_score(all_labels, all_preds, average='weighted'),
                    "accuracy": accuracy_score(all_labels, all_preds),
                    "precision": precision_score(all_labels, all_preds, average='weighted'),
                    "recall": recall_score(all_labels, all_preds, average='weighted'),
                    "confusion_matrix": confusion_matrix(all_labels, all_preds)
                }
                
                epoch_time = time.time() - epoch_start
                training_time += epoch_time
                
                # Log metrics to MLflow
                with mlflow.start_run(run_name=f"model_comparison_{name}_epoch_{epoch}"):
                    for metric_name, value in metrics.items():
                        if metric_name != "confusion_matrix":
                            mlflow.log_metric(metric_name, value)
                    mlflow.log_metric("loss", loss.item())
                    mlflow.log_param("model_type", name)
                    mlflow.log_param("epoch", epoch)
                
                logger.info(f"Epoch {epoch+1}/50 - F1: {metrics['f1_score']:.4f} - Accuracy: {metrics['accuracy']:.4f} - Time: {epoch_time:.2f}s")
                
                # Save best model
                if metrics['f1_score'] > best_f1:
                    best_f1 = metrics['f1_score']
                    torch.save(model.state_dict(), f"best_model_{name.lower().replace(' ', '_')}.pth")
            
            # Load best model
            model.load_state_dict(torch.load(f"best_model_{name.lower().replace(' ', '_')}.pth"))
            
            # Final evaluation
            model.eval()
            all_preds = []
            all_labels = []
            with torch.no_grad():
                for batch_features, batch_labels in test_loader:
                    batch_features = batch_features.to(self.device)
                    outputs = model(batch_features)
                    _, preds = torch.max(outputs, 1)
                    all_preds.extend(preds.cpu().numpy())
                    all_labels.extend(batch_labels.numpy())
            
            final_metrics = {
                "f1_score": f1_score(all_labels, all_preds, average='weighted'),
                "accuracy": accuracy_score(all_labels, all_preds),
                "precision": precision_score(all_labels, all_preds, average='weighted'),
                "recall": recall_score(all_labels, all_preds, average='weighted'),
                "training_time": training_time,
                "confusion_matrix": confusion_matrix(all_labels, all_preds)
            }
            
            results[name] = final_metrics
        
        return results
    
    def plot_results(self, results: Dict[str, Any], output_dir: str = "evaluation") -> None:
        """
        Create comprehensive visualizations of results.
        Args:
            results: Dictionary of results
            output_dir: Directory to save plots
        """
        os.makedirs(output_dir, exist_ok=True)
        
        # Create metrics DataFrame
        metrics_df = pd.DataFrame({
            name: {k: v for k, v in metrics.items() if k != "confusion_matrix"}
            for name, metrics in results.items()
        }).T
        
        # Plot metrics
        plt.figure(figsize=(12, 6))
        metrics_df[['f1_score', 'accuracy', 'precision', 'recall']].plot(kind='bar')
        plt.title('Model Performance Comparison')
        plt.ylabel('Score')
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, 'metrics_comparison.png'))
        plt.close()
        
        # Plot training time
        plt.figure(figsize=(8, 6))
        metrics_df['training_time'].plot(kind='bar')
        plt.title('Model Training Time Comparison')
        plt.ylabel('Time (seconds)')
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, 'training_time_comparison.png'))
        plt.close()
        
        # Plot confusion matrices
        for name, metrics in results.items():
            plt.figure(figsize=(8, 6))
            sns.heatmap(metrics['confusion_matrix'], annot=True, fmt='d', cmap='Blues')
            plt.title(f'Confusion Matrix - {name}')
            plt.ylabel('True Label')
            plt.xlabel('Predicted Label')
            plt.tight_layout()
            plt.savefig(os.path.join(output_dir, f'confusion_matrix_{name.lower().replace(" ", "_")}.png'))
            plt.close()
        
        # Save metrics to CSV
        metrics_df.to_csv(os.path.join(output_dir, 'metrics.csv'))
    
    def generate_report(self, results: Dict[str, Any], output_dir: str = "evaluation") -> None:
        """
        Generate a comprehensive evaluation report.
        Args:
            results: Dictionary of results
            output_dir: Directory to save report
        """
        report = []
        report.append("# Deep Learning Model Evaluation Report\n")
        
        # Add summary statistics
        report.append("## Summary Statistics\n")
        metrics_df = pd.DataFrame({
            name: {k: v for k, v in metrics.items() if k != "confusion_matrix"}
            for name, metrics in results.items()
        }).T
        report.append(metrics_df.to_markdown())
        
        # Add recommendations
        report.append("\n## Recommendations\n")
        best_model = max(results.items(), key=lambda x: x[1]['f1_score'])[0]
        report.append(f"- **Best Performing Model**: {best_model}")
        report.append(f"- **F1 Score**: {results[best_model]['f1_score']:.4f}")
        report.append(f"- **Training Time**: {results[best_model]['training_time']:.2f} seconds")
        
        # Add model-specific insights
        report.append("\n## Model-Specific Insights\n")
        for name, metrics in results.items():
            report.append(f"\n### {name}\n")
            report.append(f"- F1 Score: {metrics['f1_score']:.4f}")
            report.append(f"- Training Time: {metrics['training_time']:.2f} seconds")
            report.append(f"- Confusion Matrix: See visualization in `confusion_matrix_{name.lower().replace(' ', '_')}.png`")
        
        # Save report
        with open(os.path.join(output_dir, 'evaluation_report.md'), 'w') as f:
            f.write('\n'.join(report))

def main():
    """
    Main evaluation pipeline with proper error handling.
    """
    try:
        logger.info("Starting model evaluation pipeline...")
        
        # Set device
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        logger.info(f"Using device: {device}")
        
        # Load data
        X, y = evaluator.load_data()
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        
        # Get number of classes
        num_classes = len(np.unique(y_train))
        logger.info(f"Number of classes: {num_classes}")
        
        # Initialize evaluator
        evaluator = ModelEvaluator(X_train.shape[1], num_classes, device)
        
        # Train and evaluate models
        results = evaluator.train_and_evaluate(X_train, X_test, y_train, y_test)
        
        # Generate visualizations and report
        evaluator.plot_results(results)
        evaluator.generate_report(results)
        
        logger.info("Evaluation pipeline completed successfully")
        
    except Exception as e:
        logger.error(f"Evaluation pipeline failed: {str(e)}")
        raise

if __name__ == "__main__":
    main() 