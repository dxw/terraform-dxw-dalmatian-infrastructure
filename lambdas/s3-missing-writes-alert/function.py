import boto3
import json
import os
from datetime import datetime, timedelta, timezone

MONITORED_BUCKETS = json.loads(os.environ.get('MONITORED_BUCKETS', '[]'))
SLACK_SNS_TOPIC_ARN = os.environ.get('SLACK_SNS_TOPIC_ARN')

cloudwatch = boto3.client('cloudwatch')
sns = boto3.client('sns')

def lambda_handler(event, context):
    # Calculate the time window for the previous full calendar day (exactly 24 hours)
    now = datetime.now(timezone.utc)
    yesterday = now - timedelta(days=1)
    
    start_time = yesterday.replace(hour=0, minute=0, second=0, microsecond=0)
    end_time = start_time + timedelta(days=1)
    
    print(f"Checking S3 missing writes for the period: {start_time.isoformat()} to {end_time.isoformat()}")

    for bucket_name in MONITORED_BUCKETS:
        response = cloudwatch.get_metric_data(
            MetricDataQueries=[
                {
                    'Id': 'm1',
                    'MetricStat': {
                        'Metric': {
                            'Namespace': 'AWS/S3',
                            'MetricName': 'PutRequests',
                            'Dimensions': [
                                {
                                    'Name': 'BucketName',
                                    'Value': bucket_name
                                },
                                {
                                    'Name': 'FilterId',
                                    'Value': 'EntireBucket'
                                }
                            ]
                        },
                        'Period': 86400,
                        'Stat': 'Sum'
                    },
                    'ReturnData': True
                }
            ],
            StartTime=start_time,
            EndTime=end_time
        )

        results = response.get('MetricDataResults', [])
        put_requests_sum = 0
        if results and results[0].get('Values'):
            put_requests_sum = results[0]['Values'][0]

        if put_requests_sum == 0:
            print(f"Bucket {bucket_name} had 0 PutRequests. Sending alert.")
            send_alert(bucket_name, start_time)
        else:
            print(f"Bucket {bucket_name} had {put_requests_sum} PutRequests. No alert needed.")

    return {
        'statusCode': 200,
        'body': 'S3 missing writes check completed.'
    }

def send_alert(bucket_name, date):
    date_str = date.strftime('%Y-%m-%d')
    message = (
        f"🚨 *S3 Missing Writes Alert*\n\n"
        f"Bucket: `{bucket_name}`\n"
        f"Date: `{date_str}`\n"
        f"Issue: No `PutRequests` (file writes) detected for the previous full calendar day.\n\n"
        f"Please investigate if this is expected or if there is an issue with the data ingestion pipeline."
    )
    
    subject = f"S3 Missing Writes Alert: {bucket_name}"
    
    if SLACK_SNS_TOPIC_ARN:
        sns.publish(
            TopicArn=SLACK_SNS_TOPIC_ARN,
            Message=message,
            Subject=subject
        )
