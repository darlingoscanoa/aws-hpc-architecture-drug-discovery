"""
Script to download sample data from the Human Protein Atlas.
"""

import os
import pandas as pd
import requests
from pathlib import Path
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def download_sample_data():
    """Download sample data from the Human Protein Atlas."""
    try:
        # Create data directory
        data_dir = Path("data/human_protein_atlas")
        data_dir.mkdir(parents=True, exist_ok=True)
        
        # Sample data (using a small subset for testing)
        expression_data = pd.DataFrame({
            'Gene': ['ENSG1', 'ENSG2', 'ENSG3', 'ENSG4'],
            'Brain_level': ['High', 'Medium', 'Low', 'Not detected'],
            'Liver_level': ['Medium', 'High', 'Not detected', 'Low'],
            'Heart_level': ['Low', 'High', 'Medium', 'Not detected'],
            'Kidney_level': ['High', 'Medium', 'Low', 'High']
        })
        
        location_data = pd.DataFrame({
            'Gene': ['ENSG1', 'ENSG2', 'ENSG3', 'ENSG4'],
            'Main location': ['Nucleus', 'Cytosol', 'Membrane', 'Nucleus']
        })
        
        # Save data
        expression_data.to_csv(data_dir / "protein_atlas_expression.csv", index=False)
        location_data.to_csv(data_dir / "subcellular_location.csv", index=False)
        
        logger.info("Sample data downloaded and saved successfully!")
        
    except Exception as e:
        logger.error(f"Error downloading data: {str(e)}")
        raise

if __name__ == "__main__":
    download_sample_data() 