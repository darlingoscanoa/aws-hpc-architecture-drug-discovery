"""
Lambda function to automatically shutdown the HPC cluster when inactive.
"""

import os
import boto3
import logging
from datetime import datetime, timedelta

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
ec2 = boto3.client('ec2')
cloudwatch = boto3.client('cloudwatch')

def get_cluster_instances(cluster_name):
    """
    Get all EC2 instances associated with the cluster.
    """
    response = ec2.describe_instances(
        Filters=[
            {
                'Name': 'tag:aws:parallelcluster:name',
                'Values': [cluster_name]
            }
        ]
    )
    
    instances = []
    for reservation in response['Reservations']:
        instances.extend(reservation['Instances'])
    return instances

def get_instance_metrics(instance_id):
    """
    Get CPU utilization metrics for an instance.
    """
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(hours=int(os.environ['SHUTDOWN_THRESHOLD']))
    
    response = cloudwatch.get_metric_data(
        MetricDataQueries=[
            {
                'Id': 'cpu',
                'MetricStat': {
                    'Metric': {
                        'Namespace': 'AWS/EC2',
                        'MetricName': 'CPUUtilization',
                        'Dimensions': [
                            {
                                'Name': 'InstanceId',
                                'Value': instance_id
                            }
                        ]
                    },
                    'Period': 300,
                    'Stat': 'Average'
                },
                'StartTime': start_time,
                'EndTime': end_time
            }
        ]
    )
    
    return response['MetricDataResults'][0]['Values']

def handler(event, context):
    """
    Main Lambda handler function.
    """
    try:
        cluster_name = os.environ['CLUSTER_NAME']
        logger.info(f"Processing cluster: {cluster_name}")
        
        # Get cluster instances
        instances = get_cluster_instances(cluster_name)
        if not instances:
            logger.info("No instances found for cluster")
            return
            
        # Check each instance
        for instance in instances:
            if instance['State']['Name'] != 'running':
                continue
                
            instance_id = instance['InstanceId']
            metrics = get_instance_metrics(instance_id)
            
            # Calculate average CPU utilization
            if metrics:
                avg_cpu = sum(metrics) / len(metrics)
                logger.info(f"Instance {instance_id} average CPU: {avg_cpu}%")
                
                # Shutdown if CPU utilization is below threshold
                if avg_cpu < 5:  # 5% CPU utilization threshold
                    logger.info(f"Shutting down instance {instance_id}")
                    ec2.stop_instances(InstanceIds=[instance_id])
            else:
                logger.warning(f"No metrics found for instance {instance_id}")
                
        return {
            'statusCode': 200,
            'body': 'Successfully processed cluster shutdown'
        }
        
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        raise 