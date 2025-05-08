#!/bin/bash
#SBATCH --job-name=drug_discovery_inference
#SBATCH --output=inference_%j.log
#SBATCH --error=inference_%j.err
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --constraint=on-demand  # Request on-demand instances
#SBATCH --time=4:00:00   # Max runtime of 4 hours

# Load environment
module load cuda/11.7
module load python/3.8

# Install requirements
pip3 install torch torchvision --index-url https://download.pytorch.org/whl/cu117

# Run inference
python3 /shared/ml/inference.py
