#!/bin/bash

# Setup Validation Script
# Checks prerequisites and validates the deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== AWS DevOps Agent Demo - Setup Validation ===${NC}"
echo ""

# Track validation status
ERRORS=0
WARNINGS=0

# Function to check command
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        if [ ! -z "$2" ]; then
            VERSION=$($1 --version 2>&1 | head -n1)
            echo "  Version: $VERSION"
        fi
    else
        echo -e "${RED}✗${NC} $1 is not installed"
        ERRORS=$((ERRORS + 1))
    fi
}

# Function to check AWS service
check_aws_service() {
    echo -e "${YELLOW}Checking $1...${NC}"
    if $2 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is accessible"
    else
        echo -e "${RED}✗${NC} $1 is not accessible"
        ERRORS=$((ERRORS + 1))
    fi
}

echo -e "${BLUE}1. Checking Prerequisites${NC}"
echo "─────────────────────────────"

# Check required commands
check_command "aws" "version"
check_command "terraform" "version"
check_command "docker" "version"
check_command "git" "version"
check_command "jq" "version"
check_command "curl" "version"

echo ""
echo -e "${BLUE}2. Checking AWS Credentials${NC}"
echo "─────────────────────────────"

if aws sts get-caller-identity &> /dev/null; then
    echo -e "${GREEN}✓${NC} AWS credentials are configured"
    ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    USER=$(aws sts get-caller-identity --query Arn --output text)
    REGION=$(aws configure get region || echo "us-east-1")
    echo "  Account: $ACCOUNT"
    echo "  User: $USER"
    echo "  Region: $REGION"
else
    echo -e "${RED}✗${NC} AWS credentials are not configured"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo -e "${BLUE}3. Checking Terraform State${NC}"
echo "─────────────────────────────"

if [ -f "terraform/terraform.tfstate" ]; then
    echo -e "${GREEN}✓${NC} Terraform state exists"
    
    cd terraform
    
    # Check if infrastructure is deployed
    if terraform output &> /dev/null; then
        echo -e "${GREEN}✓${NC} Infrastructure is deployed"
        
        # Get outputs
        ECS_CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
        ECS_SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")
        ALB_URL=$(terraform output -raw alb_url 2>/dev/null || echo "")
        ECR_REPO=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
        
        echo "  ECS Cluster: $ECS_CLUSTER"
        echo "  ECS Service: $ECS_SERVICE"
        echo "  ALB URL: $ALB_URL"
        echo "  ECR Repository: $ECR_REPO"
    else
        echo -e "${YELLOW}⚠${NC} Infrastructure outputs not available"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    cd ..
else
    echo -e "${YELLOW}⚠${NC} Terraform state not found"
    echo "  Run 'make apply' to deploy infrastructure"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo -e "${BLUE}4. Checking AWS Resources${NC}"
echo "─────────────────────────────"

if [ ! -z "$ECS_CLUSTER" ]; then
    # Check ECS Cluster
    if aws ecs describe-clusters --clusters $ECS_CLUSTER --query 'clusters[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
        echo -e "${GREEN}✓${NC} ECS Cluster is active"
    else
        echo -e "${RED}✗${NC} ECS Cluster is not active"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Check ECS Service
    RUNNING_COUNT=$(aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query 'services[0].runningCount' --output text 2>/dev/null || echo "0")
    DESIRED_COUNT=$(aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query 'services[0].desiredCount' --output text 2>/dev/null || echo "0")
    
    if [ "$RUNNING_COUNT" == "$DESIRED_COUNT" ] && [ "$RUNNING_COUNT" != "0" ]; then
        echo -e "${GREEN}✓${NC} ECS Service is healthy ($RUNNING_COUNT/$DESIRED_COUNT tasks)"
    else
        echo -e "${YELLOW}⚠${NC} ECS Service tasks: $RUNNING_COUNT/$DESIRED_COUNT"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Check ALB
    if [ ! -z "$ALB_URL" ]; then
        if curl -s -o /dev/null -w "%{http_code}" $ALB_URL/health | grep -q "200"; then
            echo -e "${GREEN}✓${NC} Application is responding"
        else
            echo -e "${YELLOW}⚠${NC} Application is not responding"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
    
    # Check ECR Repository
    if [ ! -z "$ECR_REPO" ]; then
        IMAGE_COUNT=$(aws ecr describe-images --repository-name $(echo $ECR_REPO | cut -d'/' -f2) --query 'length(imageDetails)' --output text 2>/dev/null || echo "0")
        if [ "$IMAGE_COUNT" -gt "0" ]; then
            echo -e "${GREEN}✓${NC} ECR repository has $IMAGE_COUNT image(s)"
        else
            echo -e "${YELLOW}⚠${NC} ECR repository is empty"
            echo "  Run 'make push' to push an image"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
fi

echo ""
echo -e "${BLUE}5. Checking CloudWatch${NC}"
echo "─────────────────────────────"

if [ ! -z "$ECS_CLUSTER" ]; then
    # Check Log Group
    if aws logs describe-log-groups --log-group-name-prefix "/ecs/devops-agent-demo" --query 'logGroups[0].logGroupName' --output text 2>/dev/null | grep -q "ecs"; then
        echo -e "${GREEN}✓${NC} CloudWatch Log Group exists"
    else
        echo -e "${YELLOW}⚠${NC} CloudWatch Log Group not found"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Check Alarms
    ALARM_COUNT=$(aws cloudwatch describe-alarms --alarm-name-prefix "devops-agent-demo" --query 'length(MetricAlarms)' --output text 2>/dev/null || echo "0")
    if [ "$ALARM_COUNT" -gt "0" ]; then
        echo -e "${GREEN}✓${NC} CloudWatch Alarms configured ($ALARM_COUNT alarms)"
        
        # Check alarm states
        ALARM_STATE=$(aws cloudwatch describe-alarms --alarm-name-prefix "devops-agent-demo" --state-value ALARM --query 'length(MetricAlarms)' --output text 2>/dev/null || echo "0")
        if [ "$ALARM_STATE" -gt "0" ]; then
            echo -e "${YELLOW}⚠${NC} $ALARM_STATE alarm(s) in ALARM state"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${YELLOW}⚠${NC} No CloudWatch Alarms found"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo ""
echo -e "${BLUE}6. Checking DevOps Agent Configuration${NC}"
echo "─────────────────────────────"

if aws ssm get-parameter --name "/devops-agent-demo-dev/devops-agent/space-config" &> /dev/null; then
    echo -e "${GREEN}✓${NC} DevOps Agent configuration exists"
else
    echo -e "${YELLOW}⚠${NC} DevOps Agent configuration not found"
    echo "  Run 'make setup-agent' to configure"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Your environment is ready. Try:"
    echo "  make test-error-spike"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo ""
    echo "Your environment is mostly ready, but some components may need attention."
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
    echo ""
    echo "Please fix the errors before proceeding."
    echo "See docs/SETUP.md for detailed instructions."
    exit 1
fi
