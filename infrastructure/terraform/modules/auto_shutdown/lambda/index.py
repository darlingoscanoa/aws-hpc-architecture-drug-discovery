import boto3
import os
from datetime import datetime, timezone

def handler(event, context):
    ec2 = boto3.client('ec2')
    
    # Get environment variables
    shutdown_hour = int(os.environ.get('SHUTDOWN_HOUR', '19'))  # Default to 7 PM
    threshold_hours = int(os.environ.get('THRESHOLD_HOURS', '1'))
    
    # Get current hour in UTC
    current_hour = datetime.now(timezone.utc).hour
    
    if current_hour == shutdown_hour:
        # Get all running instances
        response = ec2.describe_instances(
            Filters=[
                {'Name': 'instance-state-name', 'Values': ['running']}
            ]
        )
        
        instances_to_stop = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                # Check instance tags
                tags = {t['Key']: t['Value'] for t in instance.get('Tags', [])}
                if tags.get('AutoShutdown', 'true').lower() == 'true':
                    instances_to_stop.append(instance['InstanceId'])
        
        if instances_to_stop:
            ec2.stop_instances(InstanceIds=instances_to_stop)
            print(f"Stopped instances: {instances_to_stop}")
        else:
            print("No instances to stop")
