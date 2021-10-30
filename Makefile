SHELL:=/bin/bash
REGION=us-east-1
ACCOUNT_ID = $(shell aws sts get-caller-identity --query Account --output text)
ENVIRONMENT?= "local"
STACKNAME?= "aws-sagemaker-notebook-vendingmachine"
APP_NAME?= sm_nb_function
IMAGE_NAME?= $(subst _,-,$(APP_NAME))


deploy_ecr:
	aws cloudformation deploy --stack-name $(STACKNAME)-ecr --template-file ecr.yml --parameter-overrides Name=$(IMAGE_NAME)

destroy_ecr:
	aws cloudformation delete-stack --stack-name $(STACKNAME)-ecr && aws cloudformation wait stack-delete-complete --stack-name $(STACKNAME)


build:
	cd $(APP_NAME) \
	docker build -t $(APP_NAME) . \
	&& cd -

test:
	docker run -p 9000:8080 hello-world 
	curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'

push: build
	cd $(APP_NAME) \
	&& aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com \
	&& docker tag $(APP_NAME):latest $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/$(IMAGE_NAME):latest \
	&& docker push $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/$(IMAGE_NAME):latest \
	&& cd -

cfn_validate: 
	aws cloudformation validate-template --template-body file://ecr.yml --output text
	aws cloudformation validate-template --template-body file://api.yml --output text

deploy: cfn_validate push
	aws cloudformation deploy --stack-name $(STACKNAME)-$(ENVIRONMENT) --template-file api.yml --parameter-overrides Environment=$(ENVIRONMENT),ImageName=$(IMAGE_NAME) --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND 

destroy:
	aws cloudformation delete-stack --stack-name $(STACKNAME) && aws cloudformation wait stack-delete-complete --stack-name $(STACKNAME)


