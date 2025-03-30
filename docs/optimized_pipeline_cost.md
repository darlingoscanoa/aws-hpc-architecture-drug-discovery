# Optimized End-to-End Pipeline Cost (2 Hours)

## Time Allocation
- Training: 35 minutes
- Inference: 12 minutes
- Documentation/Screenshots: 73 minutes
- **Total**: 120 minutes (2 hours)

## Infrastructure Components

### 1. AWS Batch Setup
- **Compute Environment**
  - Type: MANAGED
  - Service Role: AWSBatchServiceRole
  - Instance Role: ecsInstanceRole
  - VPC: Custom VPC
  - Subnets: Private subnets
  - Security Groups: Custom security group

### 2. Compute Resources

#### Training Phase (35 minutes)
- **AWS Batch Job Queue**
  - Priority: 1
  - Compute Environment: g4dn.xlarge (Spot)
  - Cost per hour: $0.158
  - Duration: 35 minutes
  - Cost: $0.158 × (35/60) = $0.092

#### Inference Phase (12 minutes)
- **AWS Batch Job Queue**
  - Priority: 2
  - Compute Environment: g3s.xlarge (On-Demand)
  - Cost per hour: $0.75
  - Duration: 12 minutes
  - Cost: $0.75 × (12/60) = $0.15

#### Documentation Phase (73 minutes)
- **t3.medium** (CPU only)
  - Cost per hour: $0.0416
  - Duration: 73 minutes
  - Cost: $0.0416 × (73/60) = $0.051

### 3. Storage Resources

#### FSx for Lustre
- **Configuration**
  - Storage Capacity: 1.2 TB
  - Throughput: 1.2 GB/s
  - IOPS: 50,000
  - Cost per hour: $0.24
  - Duration: 2 hours
  - **Total FSx**: $0.48

#### S3 Storage
- **Buckets**
  - Input Data: 2 GB
  - Model Weights: 1 GB
  - Results: 1 GB
  - Documentation: 1 GB
  - **Total S3**: $0.0003

### 4. Network Resources

#### EFA (Elastic Fabric Adapter)
- **Configuration**
  - Type: efa-g4dn
  - Network Interface: eth0
  - Security Group: Custom
  - Cost: Included in instance cost

#### Data Transfer
- **Outbound**
  - Training Data: 2 GB
  - Model Weights: 1 GB
  - Results: 1 GB
  - Documentation: 1 GB
  - **Total Network**: $0.45

## Visualization Requirements

### 1. Scaling Efficiency
- **Metrics to Capture**
  - Job completion time
  - Number of nodes
  - Resource utilization
  - Cost per job

### 2. Cost Optimization
- **Dashboards**
  - Spot vs On-Demand savings
  - Component cost breakdown
  - Cost per processed item

### 3. Performance Metrics
- **Benchmarks**
  - FSx I/O throughput
  - EFA network performance
  - Memory utilization

## Cost Breakdown

### Phase-by-Phase
1. Training (35 min):
   - Compute (g4dn.xlarge Spot): $0.092
   - Storage: $0.20
   - Network: $0.15
   - **Subtotal**: $0.442

2. Inference (12 min):
   - Compute (g3s.xlarge On-Demand): $0.15
   - Storage: $0.20
   - Network: $0.15
   - **Subtotal**: $0.50

3. Documentation (73 min):
   - Compute (t3.medium On-Demand): $0.051
   - Storage: $0.08
   - Network: $0.15
   - **Subtotal**: $0.281

### Total Cost
- Compute: $0.293
- Storage: $0.48
- Network: $0.45
- **Total**: $1.223

## Cost Savings
- Original Cost: $1.767
- Optimized Cost: $1.223
- **Total Savings**: $0.544 (30.8%)

## Screenshot Checklist

### AWS Console Screenshots
1. **Compute Resources**
   - EC2 Dashboard (g4dn.xlarge, g3s.xlarge)
   - GPU utilization graphs
   - Instance metrics

2. **Storage**
   - FSx for Lustre dashboard
   - S3 bucket structure
   - Storage metrics

3. **Networking**
   - EFA configuration
   - Network performance graphs
   - Security groups

4. **AWS Batch**
   - Job queue status
   - Compute environment
   - Job history

5. **Monitoring**
   - CloudWatch dashboards
   - Performance metrics
   - Cost explorer

### Visualization Screenshots
1. **Scaling Efficiency**
   - Job completion time graph
   - Node utilization heat map
   - Speedup ratio chart

2. **Cost Optimization**
   - Spot vs On-Demand comparison
   - Component cost breakdown
   - Cost per job analysis

3. **Performance**
   - FSx throughput graph
   - EFA network metrics
   - Memory utilization chart

## Notes
- All prices based on US East (N. Virginia) region
- AWS Batch provides better job management and scaling
- EFA improves network performance for distributed training
- FSx for Lustre optimizes I/O performance
- Documentation phase uses minimal resources 