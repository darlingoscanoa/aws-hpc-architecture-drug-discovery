#!/bin/bash
#SBATCH --job-name=gpu_test
#SBATCH --output=gpu_test_%j.out
#SBATCH --error=gpu_test_%j.err
#SBATCH --nodes=1
#SBATCH --gres=gpu:1

# Load CUDA environment
source /etc/profile.d/modules.sh

# Install PyTorch if not already installed
pip3 install torch

# Run the test
python3 /shared/gpu_test.py
