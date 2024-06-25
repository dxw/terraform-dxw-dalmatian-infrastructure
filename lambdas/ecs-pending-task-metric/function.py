import boto3
import os

CLUSTER_NAME = os.environ['ecsClusterName']

def lambda_handler(event, context):
  ecs_client = boto3.client('ecs')
  cloudwatch_client = boto3.client('cloudwatch')

  response = ecs_client.describe_clusters(
    clusters=[CLUSTER_NAME]
  )

  pending_tasks = response['clusters'][0]['pendingTasksCount']

  response = cloudwatch_client.put_metric_data(
    Namespace='ECS',
    MetricData=[
      {
        'MetricName': 'PendingTasksCount',
        'Dimensions': [
          {
            'Name': 'ClusterName',
            'Value': CLUSTER_NAME
          },
        ],
        'Value': pending_tasks,
        'Unit': 'Count'
      },
    ]
  )

  return {
    'statusCode': 200,
    'body': f'Successfully created custom metric for {CLUSTER_NAME} with {pending_tasks} pending tasks'
  }
