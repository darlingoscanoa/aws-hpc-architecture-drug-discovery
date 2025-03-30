"""
AWS Infrastructure Cost Estimation Script

This script estimates the cost of running the HPC infrastructure for the drug discovery pipeline.
It takes into account spot instance pricing and other AWS service costs.
"""

import boto3
import json
from datetime import datetime, timedelta
from typing import Dict, List
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class AWSCostEstimator:
    def __init__(self):
        self.ec2 = boto3.client('ec2')
        self.pricing = boto3.client('pricing')
        self.region = os.getenv('AWS_REGION', 'us-east-1')
        
    def get_spot_price(self, instance_type: str) -> float:
        """Get current spot price for an instance type."""
        response = self.ec2.describe_spot_price_history(
            InstanceTypes=[instance_type],
            ProductDescriptions=['Linux/UNIX'],
            MaxResults=1
        )
        return float(response['SpotPriceHistory'][0]['SpotPrice'])

    def get_on_demand_price(self, instance_type: str) -> float:
        """Get on-demand price for an instance type."""
        response = self.pricing.get_products(
            ServiceCode='AmazonEC2',
            Filters=[
                {'Type': 'TERM_MATCH', 'Field': 'instanceType', 'Value': instance_type},
                {'Type': 'TERM_MATCH', 'Field': 'operatingSystem', 'Value': 'Linux'},
                {'Type': 'TERM_MATCH', 'Field': 'tenancy', 'Value': 'Shared'},
                {'Type': 'TERM_MATCH', 'Field': 'capacitystatus', 'Value': 'Used'},
                {'Type': 'TERM_MATCH', 'Field': 'regionCode', 'Value': self.region}
            ]
        )
        price_list = json.loads(response['PriceList'][0])
        return float(price_list['terms']['OnDemand'][list(price_list['terms']['OnDemand'].keys())[0]]['priceDimensions'][list(price_list['terms']['OnDemand'][list(price_list['terms']['OnDemand'].keys())[0]]['priceDimensions'].keys())[0]]['pricePerUnit']['USD'])

    def estimate_costs(self, 
                      instance_type: str,
                      num_nodes: int,
                      runtime_hours: float,
                      spot_price_limit: float) -> Dict:
        """Estimate total costs for the infrastructure."""
        spot_price = min(self.get_spot_price(instance_type), spot_price_limit)
        on_demand_price = self.get_on_demand_price(instance_type)
        
        # Calculate costs
        spot_cost = spot_price * num_nodes * runtime_hours
        on_demand_cost = on_demand_price * num_nodes * runtime_hours
        
        # Additional costs (estimated)
        storage_cost = 0.1 * runtime_hours  # FSx for Lustre
        network_cost = 0.05 * runtime_hours  # Data transfer
        
        total_cost = spot_cost + storage_cost + network_cost
        
        return {
            'spot_cost': spot_cost,
            'on_demand_cost': on_demand_cost,
            'storage_cost': storage_cost,
            'network_cost': network_cost,
            'total_cost': total_cost,
            'spot_price': spot_price,
            'on_demand_price': on_demand_price
        }

def main():
    # Load configuration
    instance_type = os.getenv('INSTANCE_TYPE', 'hpc6a.48xlarge')
    num_nodes = int(os.getenv('MAX_NODES', '2'))
    runtime_hours = float(os.getenv('MAX_RUNTIME_HOURS', '2'))
    spot_price_limit = float(os.getenv('SPOT_PRICE', '0.5'))
    
    # Create estimator
    estimator = AWSCostEstimator()
    
    # Get cost estimates
    costs = estimator.estimate_costs(
        instance_type=instance_type,
        num_nodes=num_nodes,
        runtime_hours=runtime_hours,
        spot_price_limit=spot_price_limit
    )
    
    # Print results
    print("\nCost Estimation Results:")
    print(f"Instance Type: {instance_type}")
    print(f"Number of Nodes: {num_nodes}")
    print(f"Runtime Hours: {runtime_hours}")
    print(f"\nSpot Price: ${costs['spot_price']:.4f}/hour")
    print(f"On-Demand Price: ${costs['on_demand_price']:.4f}/hour")
    print(f"\nSpot Instance Cost: ${costs['spot_cost']:.2f}")
    print(f"Storage Cost: ${costs['storage_cost']:.2f}")
    print(f"Network Cost: ${costs['network_cost']:.2f}")
    print(f"\nTotal Estimated Cost: ${costs['total_cost']:.2f}")

if __name__ == "__main__":
    main() 