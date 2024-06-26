import boto3
import os

CLUSTER_NAME = os.environ['ecsClusterName']
ASG_NAME = os.environ['asgName']

ecs = boto3.client('ecs')
autoscaling = boto3.client('autoscaling')
cloudwatch = boto3.client('cloudwatch')

def lambda_handler(event, context):
  ecs_response = ecs.describe_clusters(
    clusters=[CLUSTER_NAME],
  )

  if not ecs_response['clusters']:
    return {'statusCode': 200, 'body': 'No ECS cluster found with the given name.'}

  ecs_instance_count = ecs_response['clusters'][0]['registeredContainerInstancesCount']

  asg_response = autoscaling.describe_auto_scaling_groups(
    AutoScalingGroupNames=[ASG_NAME],
  )

  if not asg_response['AutoScalingGroups']:
    return {'statusCode': 200, 'body': 'No Auto Scaling Group found with the given name.'}

  asg_instance_count = len(asg_response['AutoScalingGroups'][0]['Instances'])

  instance_diff = asg_instance_count - ecs_instance_count

  cloudwatch.put_metric_data(
    Namespace="ECS",
    MetricData=[
      {
        'MetricName': "ContainerInstanceAsgInstanceDiff",
        'Dimensions': [
          {
            'Name': 'ClusterName',
            'Value': CLUSTER_NAME
          },
        ],
        'Value': instance_diff,
        'Unit': 'Count'
      },
    ]
  )

  return {
    'statusCode': 200,
    'body': f'Container Instance / ASG Instance difference ({instance_diff}) calculated and published successfully.'}
