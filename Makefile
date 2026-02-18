.PHONY: help init plan apply destroy build push deploy test clean

# Variables
PROJECT_NAME ?= devops-agent-demo
ENVIRONMENT ?= dev
AWS_REGION ?= us-east-1

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize Terraform
	cd terraform && terraform init

plan: ## Plan Terraform changes
	cd terraform && terraform plan

apply: ## Apply Terraform changes
	cd terraform && terraform apply

destroy: ## Destroy all infrastructure
	cd terraform && terraform destroy

build: ## Build Docker image
	cd app && docker build -t $(PROJECT_NAME):latest .

push: ## Push Docker image to ECR
	@ECR_REPO=$$(cd terraform && terraform output -raw ecr_repository_url); \
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $$ECR_REPO; \
	docker tag $(PROJECT_NAME):latest $$ECR_REPO:latest; \
	docker push $$ECR_REPO:latest

deploy: build push ## Build and deploy application
	@ECS_CLUSTER=$$(cd terraform && terraform output -raw ecs_cluster_name); \
	ECS_SERVICE=$$(cd terraform && terraform output -raw ecs_service_name); \
	aws ecs update-service --cluster $$ECS_CLUSTER --service $$ECS_SERVICE --force-new-deployment

setup-agent: ## Setup DevOps Agent Space
	chmod +x scripts/setup-agent-space.sh
	./scripts/setup-agent-space.sh

test-error-spike: ## Test error spike scenario
	chmod +x scripts/trigger-incidents.sh
	./scripts/trigger-incidents.sh error-spike

test-memory-leak: ## Test memory leak scenario
	chmod +x scripts/trigger-incidents.sh
	./scripts/trigger-incidents.sh memory-leak

test-cpu-spike: ## Test CPU spike scenario
	chmod +x scripts/trigger-incidents.sh
	./scripts/trigger-incidents.sh cpu-spike

test-health-failure: ## Test health check failure scenario
	chmod +x scripts/trigger-incidents.sh
	./scripts/trigger-incidents.sh health-failure

test-all: ## Run all test scenarios
	chmod +x scripts/trigger-incidents.sh
	./scripts/trigger-incidents.sh all

status: ## Show application status
	chmod +x scripts/trigger-incidents.sh
	./scripts/trigger-incidents.sh status

cleanup: ## Cleanup test artifacts
	chmod +x scripts/trigger-incidents.sh
	./scripts/trigger-incidents.sh cleanup

logs: ## Tail CloudWatch logs
	@LOG_GROUP=$$(cd terraform && terraform output -raw cloudwatch_log_group); \
	aws logs tail $$LOG_GROUP --follow

alarms: ## Show CloudWatch alarms
	@aws cloudwatch describe-alarms \
		--alarm-name-prefix "$(PROJECT_NAME)-$(ENVIRONMENT)" \
		--query 'MetricAlarms[*].[AlarmName,StateValue,StateReason]' \
		--output table

url: ## Show application URL
	@cd terraform && terraform output -raw alb_url

clean: ## Clean local artifacts
	rm -rf app/node_modules
	rm -rf terraform/.terraform
	rm -f terraform/*.tfstate*
	docker system prune -f
