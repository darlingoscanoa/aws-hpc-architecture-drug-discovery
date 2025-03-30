# Detailed Cost Breakdown (g4dn.xlarge)

## 1. Compute Resources (g4dn.xlarge)

### On-Demand Pricing
- Cost per hour: $0.526
- Training (35 minutes): $0.526 × (35/60) = $0.307
- Inference (12 minutes): $0.526 × (12/60) = $0.105
- **Total On-Demand**: $0.412

### Spot Instance Pricing
- Cost per hour: $0.158 (70% discount)
- Training (35 minutes): $0.158 × (35/60) = $0.092
- Inference (12 minutes): $0.158 × (12/60) = $0.032
- **Total Spot**: $0.124

### Reserved Instance Pricing (1-year)
- Cost per hour: $0.342 (35% discount)
- Training (35 minutes): $0.342 × (35/60) = $0.200
- Inference (12 minutes): $0.342 × (12/60) = $0.068
- **Total Reserved**: $0.268

## 2. Storage Costs

### FSx for Lustre
- Cost per hour: $0.24
- Total time: 47 minutes
- **Total FSx**: $0.24 × (47/60) = $0.188

### S3 Storage
- Standard Storage: $0.023/GB/month
- Estimated usage: 5 GB
- **Total S3**: $0.023 × 5 × (47/720) = $0.008

## 3. Network Costs

### Data Transfer
- Inbound: Free
- Outbound:
  - Training data: 2 GB
  - Model weights: 1 GB
  - Inference results: 1 GB
  - Total: 4 GB
- **Total Network**: $0.09 × 4 = $0.36

## 4. Total Cost Breakdown

### On-Demand Scenario
- Compute: $0.412
- Storage: $0.196
- Network: $0.36
- **Total**: $0.968

### Spot Instance Scenario
- Compute: $0.124
- Storage: $0.196
- Network: $0.36
- **Total**: $0.680

### Reserved Instance Scenario
- Compute: $0.268
- Storage: $0.196
- Network: $0.36
- **Total**: $0.824

## 5. Cost Optimization Recommendations

### For Training Phase
- Use Spot Instance for training
- Savings: $0.215 ($0.307 - $0.092)
- Risk: Potential interruption
- Mitigation: Checkpoint every 5 minutes

### For Inference Phase
- Use On-Demand for inference
- Cost: $0.105
- Reason: Shorter duration, need reliability

### Hybrid Approach (Recommended)
- Training: Spot Instance ($0.092)
- Inference: On-Demand ($0.105)
- Storage: FSx ($0.188)
- Network: $0.36
- **Total Optimized**: $0.745

## 6. Cost Comparison

| Scenario | Training | Inference | Total |
|----------|----------|-----------|--------|
| All On-Demand | $0.307 | $0.105 | $0.968 |
| All Spot | $0.092 | $0.032 | $0.680 |
| All Reserved | $0.200 | $0.068 | $0.824 |
| **Hybrid (Recommended)** | $0.092 | $0.105 | $0.745 |

## 7. Notes
- Prices based on US East (N. Virginia) region
- Storage costs are prorated for actual usage time
- Network costs are fixed regardless of instance type
- Spot instances offer best value but require interruption handling
- Hybrid approach balances cost and reliability 