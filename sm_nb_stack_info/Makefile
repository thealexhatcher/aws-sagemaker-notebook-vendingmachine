SHELL := /bin/bash
APP_NAME?="aws-lambda-function"
build:
	docker build -t $(APP_NAME) . 
test:
	docker run -p 9000:8080 hello-world 
	curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'
