SHELL := /bin/bash
STACKNAME?= "aws-sagemaker-notebook-vendingmachine"
ENVIRONMENT?= "local"
REGION="us-east-1"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

validate_cfn: 
	aws cloudformation validate-template --template-body file://ecr.yml --output text
	aws cloudformation validate-template --template-body file://api.yml --output text

init:
	aws cloudformation deploy --stack-name sm_nb_stack_cleanup --template-file ecr.yml --parameter-overrides Name=sm_nb_stack_cleanup
	aws cloudformation deploy --stack-name sm_nb_stack_create --template-file ecr.yml --parameter-overrides Name=sm_nb_stack_create
	aws cloudformation deploy --stack-name sm_nb_stack_info --template-file ecr.yml --parameter-overrides Name=sm_nb_stack_info

push: init 
	aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com
	cd sm_nb_stack_cleanup \
	&& docker build -t sm_nb_stack_cleanup:latest -t $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/sm_nb_stack_cleanup:latest .
	&& docker push $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/sm_nb_stack_cleanup:latest
	&& cd -
	cd sm_nb_stack_create \
	&& docker build -t sm_nb_stack_create:latest -t $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/sm_nb_stack_create:latest .
	&& docker push $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/sm_nb_stack_create:latest
	&& cd -
	cd sm_nb_stack_info
	&& docker build -t sm_nb_stack_info:latest -t $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/sm_nb_stack_info:latest . 
	&& docker push $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/sm_nb_stack_info:latest
	&& cd - 

deploy:  validate push
	aws cloudformation deploy --stack-name $(STACKNAME)-$(ENVIRONMENT) --template-file api.yml --parameter-overrides file://api.params.$(ENVIRONMENT).json --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND 

destroy:
	aws cloudformation delete-stack --stack-name $(STACKNAME)
	aws cloudformation delete-stack --stack-name sm_nb_stack_cleanup 
	aws cloudformation delete-stack --stack-name sm_nb_stack_create 
	aws cloudformation delete-stack --stack-name sm_nb_stack_info