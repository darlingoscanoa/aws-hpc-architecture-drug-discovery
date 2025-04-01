"""
Script to visualize protein samples from the Human Protein Atlas dataset.
This script generates and saves sample images for the newsletter.
"""

import os
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import logging
from typing import Tuple, List
import pandas as pd
from Bio.PDB import *
import requests
from io import StringIO

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def load_protein_atlas_data(data_dir: str = "data/human_protein_atlas") -> Tuple[pd.DataFrame, pd.DataFrame]:
    """
    Load data from the Human Protein Atlas dataset.
    
    Args:
        data_dir: Directory containing the Human Protein Atlas data files
        
    Returns:
        Tuple of (training_data, testing_data)
    """
    try:
        # Load protein expression data
        expression_data = pd.read_csv(os.path.join(data_dir, "protein_atlas_expression.csv"))
        
        # Load subcellular location data
        location_data = pd.read_csv(os.path.join(data_dir, "subcellular_location.csv"))
        
        # Merge expression and location data
        data = pd.merge(expression_data, location_data, on="Gene")
        
        # Process features (expression levels across different tissues)
        feature_cols = [col for col in data.columns if 'level' in col.lower()]
        
        # Convert expression levels to numeric values
        expression_map = {'Not detected': 0, 'Low': 1, 'Medium': 2, 'High': 3}
        for col in feature_cols:
            data[col] = data[col].map(expression_map)
        
        # Split into training and testing (80-20 split)
        train_size = int(0.8 * len(data))
        train_data = data[:train_size]
        test_data = data[train_size:]
        
        return train_data, test_data
    except Exception as e:
        logger.error(f"Error loading Human Protein Atlas data: {str(e)}")
        raise

def create_protein_visualization(data: pd.DataFrame, title: str, output_path: str):
    """
    Create and save visualizations of protein data from Human Protein Atlas.
    
    Args:
        data: DataFrame containing protein data
        title: Title for the visualization
        output_path: Path to save the visualization
    """
    try:
        # Create figure with subplots
        fig, axes = plt.subplots(2, 2, figsize=(15, 15))
        fig.suptitle(title, fontsize=16, y=0.95)
        
        # Plot 1: Expression levels distribution
        feature_cols = [col for col in data.columns if 'level' in col.lower()]
        sns.boxplot(data=data[feature_cols], ax=axes[0, 0])
        axes[0, 0].set_title("Expression Levels Distribution")
        axes[0, 0].tick_params(axis='x', rotation=45)
        
        # Plot 2: Subcellular location distribution
        location_counts = data['Main location'].value_counts()
        sns.barplot(x=location_counts.values, y=location_counts.index, ax=axes[0, 1])
        axes[0, 1].set_title("Subcellular Location Distribution")
        
        # Plot 3: Expression correlation heatmap
        correlation = data[feature_cols].corr()
        sns.heatmap(correlation, annot=True, cmap='coolwarm', ax=axes[1, 0])
        axes[1, 0].set_title("Expression Level Correlation")
        
        # Plot 4: Sample protein expression profile
        sample_protein = data.iloc[0][feature_cols].values
        axes[1, 1].bar(range(len(sample_protein)), sample_protein)
        axes[1, 1].set_title(f"Expression Profile: {data.iloc[0]['Gene']}")
        axes[1, 1].set_xlabel("Tissue Type")
        axes[1, 1].set_ylabel("Expression Level")
        
        # Adjust layout and save
        plt.tight_layout()
        plt.savefig(output_path, dpi=300, bbox_inches='tight')
        logger.info(f"Saved visualization to {output_path}")
        
    except Exception as e:
        logger.error(f"Error creating visualization: {str(e)}")
        raise

def main():
    """Main function to generate visualizations."""
    try:
        # Create output directory if it doesn't exist
        output_dir = Path("docs/newsletter/images")
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Load Human Protein Atlas data
        logger.info("Loading Human Protein Atlas data...")
        train_data, test_data = load_protein_atlas_data()
        
        # Generate visualizations
        logger.info("Generating training data visualization...")
        create_protein_visualization(
            train_data,
            "Human Protein Atlas - Training Dataset Analysis",
            output_dir / "training_samples.png"
        )
        
        logger.info("Generating testing data visualization...")
        create_protein_visualization(
            test_data,
            "Human Protein Atlas - Testing Dataset Analysis",
            output_dir / "testing_samples.png"
        )
        
        logger.info("Visualization generation completed successfully!")
        
    except Exception as e:
        logger.error(f"Error in main execution: {str(e)}")
        raise

if __name__ == "__main__":
    main() 