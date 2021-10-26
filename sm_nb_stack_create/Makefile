SHELL := /bin/bash
APP_NAME?="aws-lambda-function"
REGION="us-east-1"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

init:
	aws ecr create-repository --repository-name $(APP_NAME)--region $(REGION)
build:
	docker build -t $(APP_NAME) . 
test:
	docker run -p 9000:8080 hello-world 
	curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'
push: build
	aws ecr get-login-password --region $(REGION) | \
		docker login --username AWS --password-stdin $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com \
	docker tag  $(APP_NAME):latest $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/$(APP_NAME):latest
	docker push $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/$(APP_NAME):latest
destroy:
	aws ecr delete-repository --repository-name $(APP_NAME) --force --region $(REGION)