"""
Streamlit Interface for Protein Atlas Classification

This module provides a web interface for model inference using Streamlit.
"""

import os
import streamlit as st
import numpy as np
import cv2
from PIL import Image
import plotly.express as px
from typing import Tuple, List
import mlflow
from pathlib import Path

from src.inference.inference import ModelInference

# Set page config
st.set_page_config(
    page_title="Protein Atlas Classifier",
    page_icon="🧬",
    layout="wide"
)

# Initialize session state
if 'model' not in st.session_state:
    st.session_state.model = None
if 'predictions' not in st.session_state:
    st.session_state.predictions = None

def load_model() -> ModelInference:
    """Load the model for inference."""
    if st.session_state.model is None:
        model_name = os.getenv('MODEL_NAME', 'lightweight')
        num_classes = int(os.getenv('NUM_CLASSES', '28'))
        model_path = os.getenv('MODEL_PATH')
        
        st.session_state.model = ModelInference(
            model_name=model_name,
            num_classes=num_classes,
            model_path=model_path
        )
    
    return st.session_state.model

def process_image(image: Image.Image) -> np.ndarray:
    """
    Process uploaded image for inference.
    
    Args:
        image: PIL Image object
        
    Returns:
        Processed image array
    """
    # Convert PIL Image to numpy array
    image_array = np.array(image)
    
    # Convert to RGB if needed
    if len(image_array.shape) == 2:
        image_array = cv2.cvtColor(image_array, cv2.COLOR_GRAY2RGB)
    elif image_array.shape[2] == 4:
        image_array = cv2.cvtColor(image_array, cv2.COLOR_RGBA2RGB)
    
    return image_array

def plot_confidence_scores(probabilities: np.ndarray) -> None:
    """
    Plot confidence scores using Plotly.
    
    Args:
        probabilities: Array of confidence scores
    """
    # Create bar chart
    fig = px.bar(
        x=range(len(probabilities[0])),
        y=probabilities[0],
        title="Class Confidence Scores",
        labels={'x': 'Class', 'y': 'Confidence'},
        template="plotly_dark"
    )
    
    # Update layout
    fig.update_layout(
        showlegend=False,
        xaxis_title="Protein Class",
        yaxis_title="Confidence Score",
        height=400
    )
    
    st.plotly_chart(fig, use_container_width=True)

def main():
    """Main function to run the Streamlit app."""
    # Title and description
    st.title("🧬 Protein Atlas Classifier")
    st.markdown("""
    This application classifies protein localization patterns in cell images.
    Upload an image to get started!
    """)
    
    # Sidebar
    with st.sidebar:
        st.header("Model Information")
        model = load_model()
        st.write(f"Model: {model.model_name}")
        st.write(f"Number of classes: {model.num_classes}")
        st.write(f"Device: {model.device}")
        
        # MLflow experiment viewer
        st.header("MLflow Experiments")
        try:
            experiments = mlflow.list_experiments()
            for exp in experiments:
                st.write(f"- {exp.name}")
        except Exception as e:
            st.error(f"Could not load MLflow experiments: {str(e)}")
    
    # Main content
    col1, col2 = st.columns(2)
    
    with col1:
        st.header("Upload Image")
        uploaded_file = st.file_uploader(
            "Choose an image...",
            type=["jpg", "jpeg", "png"],
            help="Upload a protein atlas image for classification"
        )
        
        if uploaded_file is not None:
            # Display uploaded image
            image = Image.open(uploaded_file)
            st.image(image, caption="Uploaded Image", use_column_width=True)
            
            # Process image
            image_array = process_image(image)
            
            # Make prediction
            if st.button("Classify"):
                with st.spinner("Processing..."):
                    predicted_class, probabilities = model.predict(image_array)
                    
                    # Store predictions in session state
                    st.session_state.predictions = {
                        'class': predicted_class[0],
                        'probabilities': probabilities[0]
                    }
    
    with col2:
        st.header("Results")
        if st.session_state.predictions is not None:
            # Display predicted class
            st.subheader("Predicted Class")
            st.write(f"Class {st.session_state.predictions['class']}")
            
            # Plot confidence scores
            st.subheader("Confidence Scores")
            plot_confidence_scores(st.session_state.predictions['probabilities'])
            
            # Display top 5 predictions
            st.subheader("Top 5 Predictions")
            top_5_idx = np.argsort(st.session_state.predictions['probabilities'])[-5:][::-1]
            for idx in top_5_idx:
                confidence = st.session_state.predictions['probabilities'][idx]
                st.write(f"Class {idx}: {confidence:.2%}")

if __name__ == "__main__":
    main() 