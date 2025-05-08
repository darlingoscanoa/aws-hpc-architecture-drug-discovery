#!/bin/bash
#SBATCH --job-name=drug_discovery_training
#SBATCH --output=training_%j.log
#SBATCH --error=training_%j.err
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --constraint=spot  # Request spot instances
#SBATCH --time=12:00:00   # Max runtime of 12 hours

# Load environment
module load cuda/11.7
module load python/3.8

# Install requirements
pip3 install torch torchvision --index-url https://download.pytorch.org/whl/cu117

# Run training
python3 /shared/ml/train_model.py
