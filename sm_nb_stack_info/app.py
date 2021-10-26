def handler(event, context): 

    stack_id = 'USER_PROVIDED'

    cf_client = boto3.client('cloudformation')
    stack_response = client.describe_stacks(StackName=stack_id)

    #get notebook instance name from stack 
    instance 
    sm_client = boto3.client('sagemaker')
    url_response = client.create_presigned_notebook_instance_url(NotebookInstanceName='string',SessionExpirationDurationInSeconds=)

    return {
        'stack_info': stack_response,
        'presigned_url': url_response
    }