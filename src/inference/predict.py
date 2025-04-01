"""
Inference script for drug discovery pipeline.
This script demonstrates enterprise-grade ML inference with proper monitoring and error handling.
"""

import os
import time
import logging
import numpy as np
import pandas as pd
import joblib
from typing import Dict, Any, List
import mlflow

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class DrugDiscoveryPredictor:
    """
    Enterprise-grade predictor class with proper error handling and monitoring.
    """
    
    def __init__(self, model_path: str):
        """
        Initialize the predictor.
        Args:
            model_path: Path to the trained model
        """
        self.model_path = model_path
        self.model = None
        self.load_model()
        
    def load_model(self) -> None:
        """
        Load the trained model with error handling.
        """
        try:
            logger.info(f"Loading model from {self.model_path}")
            self.model = joblib.load(self.model_path)
            logger.info("Model loaded successfully")
        except Exception as e:
            logger.error(f"Error loading model: {str(e)}")
            raise
    
    def preprocess_input(self, input_data: np.ndarray) -> np.ndarray:
        """
        Preprocess input data with validation.
        Args:
            input_data: Input features
        Returns:
            Preprocessed features
        """
        try:
            # Ensure input is 2D array
            if len(input_data.shape) == 1:
                input_data = input_data.reshape(1, -1)
            
            # Validate input shape
            expected_features = 100  # Match training data
            if input_data.shape[1] != expected_features:
                raise ValueError(f"Expected {expected_features} features, got {input_data.shape[1]}")
            
            return input_data
            
        except Exception as e:
            logger.error(f"Error preprocessing input: {str(e)}")
            raise
    
    def predict(self, input_data: np.ndarray) -> Dict[str, Any]:
        """
        Make predictions with monitoring.
        Args:
            input_data: Input features
        Returns:
            Dictionary containing predictions and metadata
        """
        try:
            start_time = time.time()
            
            # Preprocess input
            processed_data = self.preprocess_input(input_data)
            
            # Make predictions
            predictions = self.model.predict(processed_data)
            probabilities = self.model.predict_proba(processed_data)
            
            # Calculate inference time
            inference_time = time.time() - start_time
            
            # Log metrics
            with mlflow.start_run(run_name="inference"):
                mlflow.log_metric("inference_time", inference_time)
                mlflow.log_metric("batch_size", len(predictions))
            
            return {
                "predictions": predictions.tolist(),
                "probabilities": probabilities.tolist(),
                "inference_time": inference_time,
                "batch_size": len(predictions)
            }
            
        except Exception as e:
            logger.error(f"Error during prediction: {str(e)}")
            raise
    
    def batch_predict(self, input_data: np.ndarray, batch_size: int = 100) -> List[Dict[str, Any]]:
        """
        Make batch predictions with monitoring.
        Args:
            input_data: Input features
            batch_size: Size of each batch
        Returns:
            List of prediction results
        """
        try:
            results = []
            n_samples = len(input_data)
            
            for i in range(0, n_samples, batch_size):
                batch = input_data[i:i + batch_size]
                batch_result = self.predict(batch)
                results.append(batch_result)
                
                logger.info(f"Processed batch {i//batch_size + 1}/{(n_samples + batch_size - 1)//batch_size}")
            
            return results
            
        except Exception as e:
            logger.error(f"Error during batch prediction: {str(e)}")
            raise

def main():
    """
    Main inference pipeline with proper error handling.
    """
    try:
        logger.info("Starting inference pipeline...")
        
        # Initialize predictor
        model_path = "models/model.joblib"
        predictor = DrugDiscoveryPredictor(model_path)
        
        # Generate sample data for demonstration
        n_samples = 100
        n_features = 100
        sample_data = np.random.randn(n_samples, n_features)
        
        # Make predictions
        results = predictor.batch_predict(sample_data)
        
        # Log summary
        total_time = sum(r["inference_time"] for r in results)
        total_samples = sum(r["batch_size"] for r in results)
        
        logger.info(f"Processed {total_samples} samples in {total_time:.2f} seconds")
        logger.info(f"Average inference time: {total_time/total_samples:.3f} seconds per sample")
        
    except Exception as e:
        logger.error(f"Inference pipeline failed: {str(e)}")
        raise

if __name__ == "__main__":
    main() 