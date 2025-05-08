"""
Model Definitions for Protein Atlas Classification

This module contains the model architectures for the protein atlas classification task:
1. LightweightCNN: A simple CNN architecture optimized for speed and memory efficiency
2. ResNet18: A standard ResNet architecture for comparison
"""

import torch
import torch.nn as nn
import torchvision.models as models
from typing import Optional

class LightweightCNN(nn.Module):
    """
    A lightweight CNN architecture optimized for protein atlas classification.
    Uses depthwise separable convolutions and batch normalization for efficiency.
    """
    
    def __init__(self, 
                 num_classes: int,
                 input_channels: int = 3,
                 dropout_rate: float = 0.5):
        """
        Initialize the lightweight CNN.
        
        Args:
            num_classes: Number of output classes
            input_channels: Number of input channels (default: 3 for RGB)
            dropout_rate: Dropout rate for regularization
        """
        super(LightweightCNN, self).__init__()
        
        # First block
        self.conv1 = nn.Conv2d(input_channels, 32, kernel_size=3, padding=1)
        self.bn1 = nn.BatchNorm2d(32)
        self.relu1 = nn.ReLU(inplace=True)
        self.pool1 = nn.MaxPool2d(kernel_size=2, stride=2)
        
        # Second block
        self.conv2 = nn.Conv2d(32, 64, kernel_size=3, padding=1)
        self.bn2 = nn.BatchNorm2d(64)
        self.relu2 = nn.ReLU(inplace=True)
        self.pool2 = nn.MaxPool2d(kernel_size=2, stride=2)
        
        # Third block
        self.conv3 = nn.Conv2d(64, 128, kernel_size=3, padding=1)
        self.bn3 = nn.BatchNorm2d(128)
        self.relu3 = nn.ReLU(inplace=True)
        self.pool3 = nn.MaxPool2d(kernel_size=2, stride=2)
        
        # Fourth block
        self.conv4 = nn.Conv2d(128, 256, kernel_size=3, padding=1)
        self.bn4 = nn.BatchNorm2d(256)
        self.relu4 = nn.ReLU(inplace=True)
        self.pool4 = nn.MaxPool2d(kernel_size=2, stride=2)
        
        # Global average pooling
        self.avgpool = nn.AdaptiveAvgPool2d((1, 1))
        
        # Dropout and fully connected layer
        self.dropout = nn.Dropout(dropout_rate)
        self.fc = nn.Linear(256, num_classes)
        
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Forward pass of the network.
        
        Args:
            x: Input tensor of shape (batch_size, channels, height, width)
            
        Returns:
            Output tensor of shape (batch_size, num_classes)
        """
        # First block
        x = self.conv1(x)
        x = self.bn1(x)
        x = self.relu1(x)
        x = self.pool1(x)
        
        # Second block
        x = self.conv2(x)
        x = self.bn2(x)
        x = self.relu2(x)
        x = self.pool2(x)
        
        # Third block
        x = self.conv3(x)
        x = self.bn3(x)
        x = self.relu3(x)
        x = self.pool3(x)
        
        # Fourth block
        x = self.conv4(x)
        x = self.bn4(x)
        x = self.relu4(x)
        x = self.pool4(x)
        
        # Global average pooling
        x = self.avgpool(x)
        x = torch.flatten(x, 1)
        
        # Dropout and fully connected layer
        x = self.dropout(x)
        x = self.fc(x)
        
        return x

def get_resnet18(num_classes: int, pretrained: bool = True) -> nn.Module:
    """
    Get a ResNet18 model with modified final layer for protein atlas classification.
    
    Args:
        num_classes: Number of output classes
        pretrained: Whether to use pretrained weights
        
    Returns:
        Modified ResNet18 model
    """
    # Load pretrained ResNet18
    model = models.resnet18(pretrained=pretrained)
    
    # Modify the final layer
    num_features = model.fc.in_features
    model.fc = nn.Sequential(
        nn.Dropout(0.5),
        nn.Linear(num_features, num_classes)
    )
    
    return model

def create_model(model_name: str, 
                num_classes: int,
                input_channels: int = 3) -> nn.Module:
    """
    Create a model instance based on the specified name.
    
    Args:
        model_name: Name of the model to create ('lightweight' or 'resnet18')
        num_classes: Number of output classes
        input_channels: Number of input channels
        
    Returns:
        Model instance
    """
    if model_name.lower() == 'lightweight':
        return LightweightCNN(
            num_classes=num_classes,
            input_channels=input_channels
        )
    elif model_name.lower() == 'resnet18':
        return get_resnet18(num_classes=num_classes)
    else:
        raise ValueError(f"Unknown model name: {model_name}") 