# End-to-End Pipeline Cost (2 Hours)

## Time Allocation
- Training: 35 minutes
- Inference: 12 minutes
- Documentation/Screenshots: 73 minutes
- **Total**: 120 minutes (2 hours)

## Cost Breakdown

### 1. Compute Resources (g4dn.xlarge)

#### Training Phase (35 minutes)
- **Spot Instance** (recommended for training)
  - Cost per hour: $0.158
  - Duration: 35 minutes
  - Cost: $0.158 × (35/60) = $0.092

#### Inference Phase (12 minutes)
- **On-Demand** (recommended for inference)
  - Cost per hour: $0.526
  - Duration: 12 minutes
  - Cost: $0.526 × (12/60) = $0.105

#### Documentation Phase (73 minutes)
- **On-Demand** (needed for screenshots)
  - Cost per hour: $0.526
  - Duration: 73 minutes
  - Cost: $0.526 × (73/60) = $0.640

### 2. Storage Costs (Full 2 Hours)

#### FSx for Lustre
- Cost per hour: $0.24
- Duration: 2 hours
- **Total FSx**: $0.24 × 2 = $0.48

#### S3 Storage
- Standard Storage: $0.023/GB/month
- Estimated usage: 5 GB
- **Total S3**: $0.023 × 5 × (2/720) = $0.0003

### 3. Network Costs

#### Data Transfer
- Inbound: Free
- Outbound:
  - Training data: 2 GB
  - Model weights: 1 GB
  - Inference results: 1 GB
  - Documentation uploads: 1 GB
  - Total: 5 GB
- **Total Network**: $0.09 × 5 = $0.45

## Total Cost Breakdown

### Phase-by-Phase
1. Training (35 min):
   - Compute (Spot): $0.092
   - Storage: $0.20
   - Network: $0.15
   - **Subtotal**: $0.442

2. Inference (12 min):
   - Compute (On-Demand): $0.105
   - Storage: $0.20
   - Network: $0.15
   - **Subtotal**: $0.455

3. Documentation (73 min):
   - Compute (On-Demand): $0.640
   - Storage: $0.08
   - Network: $0.15
   - **Subtotal**: $0.870

### Total Cost
- Compute: $0.837
- Storage: $0.48
- Network: $0.45
- **Total**: $1.767

## Cost Optimization Options

### Option 1: All Spot Instances
- Training: $0.092
- Inference: $0.032
- Documentation: $0.192
- **Total**: $0.746
- **Risk**: Potential interruption during documentation

### Option 2: Hybrid (Recommended)
- Training: Spot ($0.092)
- Inference: On-Demand ($0.105)
- Documentation: On-Demand ($0.640)
- **Total**: $1.767
- **Benefit**: Reliable for documentation

### Option 3: All On-Demand
- Training: $0.307
- Inference: $0.105
- Documentation: $0.640
- **Total**: $1.052
- **Benefit**: Most reliable

## Recommendations

### For Cost Optimization
1. Use Spot instances for training
2. Use On-Demand for inference and documentation
3. Implement checkpointing every 5 minutes
4. Monitor instance status

### For Documentation
1. Schedule screenshots during low-cost periods
2. Batch upload documentation
3. Use S3 for temporary storage
4. Clean up resources after documentation

## Notes
- Prices based on US East (N. Virginia) region
- Documentation phase is the most expensive due to longer duration
- Network costs are fixed regardless of instance type
- Storage costs are prorated for the full 2-hour period 