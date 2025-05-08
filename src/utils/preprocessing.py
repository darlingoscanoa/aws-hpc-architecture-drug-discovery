"""
Data Preprocessing Module for Human Protein Atlas Dataset

This module handles the preprocessing of the Human Protein Atlas dataset,
including data sampling, image resizing, and feature extraction.
"""

import os
import numpy as np
import pandas as pd
import cv2
from typing import Tuple, List, Dict
from sklearn.model_selection import train_test_split
from imblearn.over_sampling import SMOTE
from sklearn.preprocessing import StandardScaler
import mlflow
from pathlib import Path
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ProteinAtlasPreprocessor:
    def __init__(self, 
                 data_dir: str,
                 image_size: int = 224,
                 sample_size: float = 0.1):
        """
        Initialize the preprocessor.
        
        Args:
            data_dir: Directory containing the dataset
            image_size: Target size for images
            sample_size: Fraction of data to use (0.0 to 1.0)
        """
        self.data_dir = Path(data_dir)
        self.image_size = image_size
        self.sample_size = sample_size
        self.scaler = StandardScaler()
        
    def load_metadata(self) -> pd.DataFrame:
        """Load and sample the metadata file."""
        metadata_path = self.data_dir / 'train.csv'
        df = pd.read_csv(metadata_path)
        
        if self.sample_size < 1.0:
            df = df.sample(frac=self.sample_size, random_state=42)
        
        return df
    
    def preprocess_image(self, image_path: str) -> np.ndarray:
        """
        Preprocess a single image.
        
        Args:
            image_path: Path to the image file
            
        Returns:
            Preprocessed image array
        """
        # Read image
        img = cv2.imread(image_path)
        if img is None:
            raise ValueError(f"Could not read image: {image_path}")
        
        # Resize image
        img = cv2.resize(img, (self.image_size, self.image_size))
        
        # Convert to RGB
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        
        # Normalize
        img = img.astype(np.float32) / 255.0
        
        return img
    
    def extract_features(self, image: np.ndarray) -> np.ndarray:
        """
        Extract features from preprocessed image.
        
        Args:
            image: Preprocessed image array
            
        Returns:
            Feature vector
        """
        # Flatten image
        features = image.reshape(-1)
        
        # Apply PCA (if needed)
        # features = self.pca.transform(features.reshape(1, -1))
        
        return features
    
    def prepare_dataset(self) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
        """
        Prepare the dataset for training.
        
        Returns:
            Tuple of (X_train, X_test, y_train, y_test)
        """
        logger.info("Loading metadata...")
        df = self.load_metadata()
        
        # Split data
        train_df, test_df = train_test_split(df, test_size=0.2, random_state=42)
        
        # Process training data
        logger.info("Processing training data...")
        X_train = []
        y_train = []
        
        for _, row in train_df.iterrows():
            try:
                image_path = self.data_dir / 'train' / row['Id']
                img = self.preprocess_image(str(image_path))
                features = self.extract_features(img)
                
                X_train.append(features)
                y_train.append(row['Target'])
            except Exception as e:
                logger.warning(f"Error processing {row['Id']}: {str(e)}")
                continue
        
        # Process test data
        logger.info("Processing test data...")
        X_test = []
        y_test = []
        
        for _, row in test_df.iterrows():
            try:
                image_path = self.data_dir / 'train' / row['Id']
                img = self.preprocess_image(str(image_path))
                features = self.extract_features(img)
                
                X_test.append(features)
                y_test.append(row['Target'])
            except Exception as e:
                logger.warning(f"Error processing {row['Id']}: {str(e)}")
                continue
        
        # Convert to numpy arrays
        X_train = np.array(X_train)
        X_test = np.array(X_test)
        y_train = np.array(y_train)
        y_test = np.array(y_test)
        
        # Apply SMOTE for class balancing
        logger.info("Applying SMOTE for class balancing...")
        smote = SMOTE(random_state=42)
        X_train, y_train = smote.fit_resample(X_train, y_train)
        
        # Scale features
        logger.info("Scaling features...")
        X_train = self.scaler.fit_transform(X_train)
        X_test = self.scaler.transform(X_test)
        
        # Log dataset statistics
        self._log_dataset_stats(X_train, X_test, y_train, y_test)
        
        return X_train, X_test, y_train, y_test
    
    def _log_dataset_stats(self, 
                          X_train: np.ndarray,
                          X_test: np.ndarray,
                          y_train: np.ndarray,
                          y_test: np.ndarray):
        """Log dataset statistics to MLflow."""
        stats = {
            'train_samples': len(X_train),
            'test_samples': len(X_test),
            'features': X_train.shape[1],
            'classes': len(np.unique(y_train)),
            'image_size': self.image_size,
            'sample_size': self.sample_size
        }
        
        mlflow.log_metrics(stats)
        
        # Log class distribution
        for split, y in [('train', y_train), ('test', y_test)]:
            unique, counts = np.unique(y, return_counts=True)
            for cls, count in zip(unique, counts):
                mlflow.log_metric(f'{split}_class_{cls}_count', count)

def main():
    """Main function to run preprocessing."""
    # Initialize preprocessor
    preprocessor = ProteinAtlasPreprocessor(
        data_dir=os.getenv('RAW_DATA_DIR', 'data/raw'),
        image_size=int(os.getenv('IMAGE_SIZE', '224')),
        sample_size=float(os.getenv('DATASET_SIZE', '0.1'))
    )
    
    # Start MLflow run
    with mlflow.start_run(run_name='data_preprocessing'):
        # Prepare dataset
        X_train, X_test, y_train, y_test = preprocessor.prepare_dataset()
        
        # Save preprocessed data
        output_dir = Path(os.getenv('PREPROCESSED_DATA_DIR', 'data/preprocessing'))
        output_dir.mkdir(parents=True, exist_ok=True)
        
        np.save(output_dir / 'X_train.npy', X_train)
        np.save(output_dir / 'X_test.npy', X_test)
        np.save(output_dir / 'y_train.npy', y_train)
        np.save(output_dir / 'y_test.npy', y_test)
        
        logger.info("Preprocessing completed successfully!")

if __name__ == "__main__":
    main() 