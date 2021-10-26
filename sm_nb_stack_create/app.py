import os 
from datetime import datetime, timezone
import uuid
import boto3
import logging

logger = logging.getLogger()

def handler(event, context):
    logger.setLevel(logging.INFO)
    with open('resources/cfn_sm_nb.yml') as template_fileobj:
        template_data = template_fileobj.read()
    with open('resources/cfn_sm_nb.params.json') as parameter_fileobj:
        parameter_data = json.load(parameter_fileobj)

    cf = boto3.client('cloudformation')
    cf.validate_template(TemplateBody=template_data)

    params = {
        'StackName': stack_name,
        'TemplateBody': template_data,
        'Parameters': parameter_data,
    }
    try:
        if _stack_exists(stack_name):
            print('Updating {}'.format(stack_name))
            stack_result = cf.update_stack(**params)
            waiter = cf.get_waiter('stack_update_complete')
        else:
            print('Creating {}'.format(stack_name))
            stack_result = cf.create_stack(**params)
            waiter = cf.get_waiter('stack_create_complete')
        print("...waiting for stack to be ready...")
        waiter.wait(StackName=stack_name)
    except botocore.exceptions.ClientError as ex:
        error_message = ex.response['Error']['Message']
        if error_message == 'No updates are to be performed.':
            print("No changes")
        else:
            raise
    else:
        print(json.dumps(
            cf.describe_stacks(StackName=stack_result['StackId']),
            indent=2,
            default=json_serial
        ))
    
    return {
        'message': 'Success One'
    }

def _stack_exists(stack_name):
    stacks = cf.list_stacks()['StackSummaries']
    for stack in stacks:
        if stack['StackStatus'] == 'DELETE_COMPLETE':
            continue
        if stack_name == stack['StackName']:
            return True
    return False

def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""
    if isinstance(obj, datetime):
        serial = obj.isoformat()
        return serial
    raise TypeError("Type not serializable")

if __name__ == '__main__':
    main(*sys.argv[1:])
