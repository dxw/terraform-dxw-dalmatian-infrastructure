import json
import boto3
import os

asgName = os.environ['asgName']
launchTemplateName = os.environ['launchTemplateName']
amiVersion = os.environ['amiVersion']

def lambda_handler(event, context):
    asgClient = boto3.client('autoscaling')
    ec2Client = boto3.client('ec2')

    # Update launch template to use the latest AMI
    response = ec2Client.describe_images(
        Owners=['amazon'],
        Filters=[
            {'Name': 'name', 'Values': [amiVersion]},
            {'Name': 'state', 'Values': ['available']},
            {'Name': 'architecture', 'Values': ['x86_64']}
        ]
    )

    images = sorted(
        response['Images'],
        key=lambda x: x['CreationDate'],
        reverse=True
    )
    if not images:
        raise Exception("No AMIs found!")

    latest_ami_id = images[0]['ImageId']
    print(f"Latest AMI ID: {latest_ami_id}")

    try:
        template_response = ec2Client.describe_launch_template_versions(
            LaunchTemplateName=launchTemplateName,
            Versions=["$Latest"]
        )
        template_data = template_response['LaunchTemplateVersions'][0]['LaunchTemplateData']
    except Exception as e:
        print(f"Error retrieving launch template: {e}")
        raise

    print(f"Currnt AMI ID: {template_data['ImageId']}")

    if template_data['ImageId'] != latest_ami_id:
        template_data['ImageId'] = latest_ami_id

        try:
            new_version_response = ec2Client.create_launch_template_version(
                LaunchTemplateName=launchTemplateName,
                SourceVersion="$Latest",
                LaunchTemplateData=template_data
            )
            new_version_number = new_version_response['LaunchTemplateVersion']['VersionNumber']
            print(f"Created new launch template version: {new_version_number}")
        except Exception as e:
            print(f"Error creating new launch template version: {e}")
            raise
    else:
        print(f"Launch template unchanged - AMI is alreaduy up to date")

    # Start instance refresh
    print(f"Starting instance refresh ...")
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
