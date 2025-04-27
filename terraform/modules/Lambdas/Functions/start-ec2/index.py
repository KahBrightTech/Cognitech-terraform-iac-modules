import boto3
import logging
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Extracting InstanceIds from the event sent by CloudFormation or Service Catalog
        props = event.get('ResourceProperties', {})
        instance_ids = props.get('InstanceIds', [])
        
        if not instance_ids:
            raise ValueError("Missing 'InstanceIds' in input")

        ec2 = boto3.resource('ec2')
        result = []

        # Iterate through the list of EC2 instance IDs
        for instance_id in instance_ids:
            instance = ec2.Instance(instance_id)
            state = instance.state['Name']
            logger.info(f"Instance {instance_id} is currently {state}")

            if state != 'running':
                logger.info(f"Starting instance {instance_id}...")
                instance.start()
                instance.wait_until_running()
                logger.info(f"Started instance {instance_id}")
                result.append({'InstanceId': instance_id, 'PreviousState': state, 'NewState': 'running'})
            else:
                logger.info(f"Instance {instance_id} was already running")
                result.append({'InstanceId': instance_id, 'PreviousState': state, 'NewState': state})

        # Return result after successful operation
        return {
            'statusCode': 200,
            'body': json.dumps({'Result': result})
        }

    except Exception as e:
        logger.error(f"Error occurred: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'Message': str(e)})
        }
