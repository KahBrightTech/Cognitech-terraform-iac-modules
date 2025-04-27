import boto3
import logging
import json
import urllib3

logger = logging.getLogger()
logger.setLevel(logging.INFO)
http = urllib3.PoolManager()

def send_response(event, context, status, data, physical_resource_id=None):
    response_body = {
        'Status': status,
        'Reason': f'See logs in {context.log_stream_name}',
        'PhysicalResourceId': physical_resource_id or context.log_stream_name,
        'StackId': event['StackId'],
        'RequestId': event['RequestId'],
        'LogicalResourceId': event['LogicalResourceId'],
        'Data': data
    }
    json_response = json.dumps(response_body)
    headers = {'Content-Type': ''}
    try:
        http.request("PUT", event["ResponseURL"], body=json_response, headers=headers)
    except Exception as e:
        logger.error(f"send_response failed: {e}")

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    try:
        props = event.get('ResourceProperties', {})
        instance_ids = props.get('InstanceIds', [])
        if not instance_ids:
            raise ValueError("Missing 'InstanceIds' in ResourceProperties")

        ec2 = boto3.resource('ec2')
        result = []
        for instance_id in instance_ids:
            instance = ec2.Instance(instance_id)
            state = instance.state['Name']
            logger.info(f"Instance {instance_id} is currently {state}")

            if state != 'running':
                instance.start()
                instance.wait_until_running()
                logger.info(f"Started instance {instance_id}")
                result.append({'InstanceId': instance_id, 'State': 'started'})
            else:
                result.append({'InstanceId': instance_id, 'State': 'already running'})

        send_response(event, context, 'SUCCESS', result)
    except Exception as e:
        logger.error(str(e))
        send_response(event, context, 'FAILED', {'Message': str(e)})
