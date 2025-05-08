"""
AWS Resource Cleanup Script

This script cleans up all AWS resources created during the HPC lab session.
It ensures no resources are left running to avoid unnecessary charges.
"""

import boto3
import os
from typing import List
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class AWSCleanup:
    def __init__(self):
        self.ec2 = boto3.client('ec2')
        self.s3 = boto3.client('s3')
        self.fsx = boto3.client('fsx')
        self.cluster_name = os.getenv('CLUSTER_NAME', 'hpc-drug-discovery')
        
    def get_cluster_instances(self) -> List[str]:
        """Get list of EC2 instances belonging to the cluster."""
        response = self.ec2.describe_instances(
            Filters=[
                {'Name': 'tag:Name', 'Values': [f'{self.cluster_name}-*']},
                {'Name': 'instance-state-name', 'Values': ['running', 'stopped']}
            ]
        )
        instances = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instances.append(instance['InstanceId'])
        return instances

    def get_cluster_volumes(self) -> List[str]:
        """Get list of EBS volumes belonging to the cluster."""
        response = self.ec2.describe_volumes(
            Filters=[
                {'Name': 'tag:Name', 'Values': [f'{self.cluster_name}-*']}
            ]
        )
        return [volume['VolumeId'] for volume in response['Volumes']]

    def get_cluster_snapshots(self) -> List[str]:
        """Get list of EBS snapshots belonging to the cluster."""
        response = self.ec2.describe_snapshots(
            Filters=[
                {'Name': 'tag:Name', 'Values': [f'{self.cluster_name}-*']}
            ]
        )
        return [snapshot['SnapshotId'] for snapshot in response['Snapshots']]

    def get_cluster_s3_buckets(self) -> List[str]:
        """Get list of S3 buckets belonging to the cluster."""
        response = self.s3.list_buckets()
        return [bucket['Name'] for bucket in response['Buckets'] 
                if bucket['Name'].startswith(self.cluster_name)]

    def get_cluster_fsx_filesystems(self) -> List[str]:
        """Get list of FSx filesystems belonging to the cluster."""
        response = self.fsx.describe_file_systems()
        return [fs['FileSystemId'] for fs in response['FileSystems']
                if fs['Tags'] and any(tag['Key'] == 'Name' and 
                                    tag['Value'].startswith(self.cluster_name)
                                    for tag in fs['Tags'])]

    def cleanup(self):
        """Clean up all cluster resources."""
        print("Starting cleanup process...")
        
        # Terminate EC2 instances
        instances = self.get_cluster_instances()
        if instances:
            print(f"Terminating {len(instances)} EC2 instances...")
            self.ec2.terminate_instances(InstanceIds=instances)
            self.ec2.get_waiter('instance_terminated').wait(InstanceIds=instances)
        
        # Delete EBS volumes
        volumes = self.get_cluster_volumes()
        if volumes:
            print(f"Deleting {len(volumes)} EBS volumes...")
            for volume_id in volumes:
                try:
                    self.ec2.delete_volume(VolumeId=volume_id)
                except self.ec2.exceptions.ClientError:
                    print(f"Could not delete volume {volume_id}")
        
        # Delete EBS snapshots
        snapshots = self.get_cluster_snapshots()
        if snapshots:
            print(f"Deleting {len(snapshots)} EBS snapshots...")
            for snapshot_id in snapshots:
                try:
                    self.ec2.delete_snapshot(SnapshotId=snapshot_id)
                except self.ec2.exceptions.ClientError:
                    print(f"Could not delete snapshot {snapshot_id}")
        
        # Delete S3 buckets
        buckets = self.get_cluster_s3_buckets()
        if buckets:
            print(f"Deleting {len(buckets)} S3 buckets...")
            for bucket_name in buckets:
                try:
                    # Delete all objects in bucket
                    self.s3.delete_bucket(Bucket=bucket_name)
                except self.s3.exceptions.ClientError:
                    print(f"Could not delete bucket {bucket_name}")
        
        # Delete FSx filesystems
        filesystems = self.get_cluster_fsx_filesystems()
        if filesystems:
            print(f"Deleting {len(filesystems)} FSx filesystems...")
            for fs_id in filesystems:
                try:
                    self.fsx.delete_file_system(FileSystemId=fs_id)
                except self.fsx.exceptions.ClientError:
                    print(f"Could not delete filesystem {fs_id}")
        
        print("Cleanup completed!")

def main():
    cleanup = AWSCleanup()
    cleanup.cleanup()

if __name__ == "__main__":
    main() 