SHELL := /bin/bash
STACKNAME?= "aws-sagemaker-notebook-vendingmachine"
clean:
	rm -f resources.out.yml
validate:
	aws cloudformation validate-template --template-body file://resources.yml --output text	
deploy: build 
	cd sm_nb_stack_cleanup && make push
	cd sm_nb_stack_create && make push
	cd sm_nb_stack_info && make push
	aws cloudformation deploy --stack-name $(STACKNAME) --template-file resources.out.yml --parameter-overrides file://resources.params.$(S3_PREFIX).json --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND 
destroy:
	aws cloudformation delete-stack --stack-name $(STACKNAME)
