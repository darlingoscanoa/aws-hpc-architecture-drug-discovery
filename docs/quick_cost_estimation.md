# Quick Cost Estimation (2-Hour Pipeline)

This document provides a simplified cost estimation for a 2-hour training and inference pipeline using GPU instances.

## Training Phase (1 Hour)

### Compute Resources
- **5 g4dn.xlarge instances** (for parallel training)
  - Specifications:
    - 4 vCPUs
    - 16 GB RAM
    - 1 NVIDIA T4 GPU
    - Up to 25 Gbps network
  - Cost per hour: $0.526 × 5 = $2.63
  - Total for 1 hour: $2.63

### Storage
- **FSx for Lustre** (temporary storage during training)
  - 1.2 TB capacity
  - Cost per hour: $171.52 ÷ 720 = $0.24
  - Total for 1 hour: $0.24

### Network
- **Data Transfer** (model weights and checkpoints)
  - Estimated 10 GB transfer
  - Cost: $0.09 × 10 = $0.90
  - Total for 1 hour: $0.90

## Inference Phase (1 Hour)

### Compute Resources
- **2 g4dn.xlarge instances** (for inference)
  - Cost per hour: $0.526 × 2 = $1.05
  - Total for 1 hour: $1.05

### Storage
- **FSx for Lustre** (model loading and inference)
  - Cost per hour: $0.24
  - Total for 1 hour: $0.24

### Network
- **Data Transfer** (input/output data)
  - Estimated 5 GB transfer
  - Cost: $0.09 × 5 = $0.45
  - Total for 1 hour: $0.45

## Total Cost Breakdown

### Training (1 Hour)
- Compute: $2.63
- Storage: $0.24
- Network: $0.90
- **Subtotal**: $3.77

### Inference (1 Hour)
- Compute: $1.05
- Storage: $0.24
- Network: $0.45
- **Subtotal**: $1.74

### Total Cost (2 Hours)
- **Training + Inference**: $5.51

## Cost Optimization Options

### Using Spot Instances (70% discount)
- Training compute: $2.63 × 0.3 = $0.79
- Inference compute: $1.05 × 0.3 = $0.32
- **Total with Spot**: $2.59

### Using Reserved Instances (35% discount)
- Training compute: $2.63 × 0.65 = $1.71
- Inference compute: $1.05 × 0.65 = $0.68
- **Total with Reserved**: $4.58

## Alternative GPU Options

### For Larger Models
- **g4dn.2xlarge** (2 GPUs)
  - Cost per hour: $0.752
  - Better for larger models
  - More memory (32 GB)

### For Maximum Performance
- **p3.2xlarge** (1 NVIDIA V100 GPU)
  - Cost per hour: $3.06
  - Better for complex models
  - Higher memory bandwidth

### For Cost Optimization
- **g3s.xlarge** (1 NVIDIA Tesla M60)
  - Cost per hour: $0.75
  - Good balance of cost/performance
  - Sufficient for most inference tasks

## Notes
- Prices are based on US East (N. Virginia) region
- Storage costs are prorated for the 2-hour period
- Network costs are estimated based on typical model sizes
- GPU instances are more cost-effective for ML workloads
- T4 GPUs provide good performance for most ML tasks
- No additional costs for CloudWatch or Lambda as they're negligible for 2 hours 