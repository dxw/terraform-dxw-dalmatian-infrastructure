import json
import boto3
import os

asgName = os.environ['asgName']

def lambda_handler(event, context):
    asgClient = boto3.client('autoscaling')
    try:
        response = asgClient.start_instance_refresh(
            AutoScalingGroupName=asgName,
            Strategy='Rolling'
        )

        return {
            'statusCode': 200,
            'body': json.dumps(response)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(str(e))
        }
