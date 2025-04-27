import boto3
import logging
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Pull instance IDs from the event
        instance_ids = event.get('InstanceIds', [])

        if not instance_ids:
            raise ValueError("Missing 'InstanceIds' in input")

        ec2 = boto3.resource('ec2')
        result = []

        # Iterate through each instance
        for instance_id in instance_ids:
            instance = ec2.Instance(instance_id)
            state = instance.state['Name']
            logger.info(f"Instance {instance_id} is currently {state}")

            if state == 'running':
                logger.info(f"Stopping instance {instance_id}...")
                instance.stop()
                instance.wait_until_stopped()
                logger.info(f"Instance {instance_id} is now stopped")
                result.append({'InstanceId': instance_id, 'PreviousState': 'running', 'NewState': 'stopped'})
            else:
                logger.info(f"Instance {instance_id} was already {state}")
                result.append({'InstanceId': instance_id, 'PreviousState': state, 'NewState': state})

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
