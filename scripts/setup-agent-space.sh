#!/bin/bash

# AWS DevOps Agent Space Setup Script
# This script configures the DevOps Agent Space for the ECS application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="${PROJECT_NAME:-devops-agent-demo}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo -e "${GREEN}=== AWS DevOps Agent Space Setup ===${NC}"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AWS credentials configured${NC}"

# Get infrastructure outputs from Terraform
echo -e "${YELLOW}Retrieving infrastructure information...${NC}"
cd terraform

if [ ! -f "terraform.tfstate" ]; then
    echo -e "${RED}Error: Terraform state not found. Please run 'terraform apply' first${NC}"
    exit 1
fi

ECS_CLUSTER=$(terraform output -raw ecs_cluster_name)
ECS_SERVICE=$(terraform output -raw ecs_service_name)
LOG_GROUP=$(terraform output -raw cloudwatch_log_group)
ALB_ARN=$(terraform output -json | jq -r '.alb_dns_name.value')
AGENT_ROLE_ARN=$(terraform output -raw devops_agent_role_arn)

cd ..

echo -e "${GREEN}✓ Infrastructure information retrieved${NC}"
echo "  - ECS Cluster: $ECS_CLUSTER"
echo "  - ECS Service: $ECS_SERVICE"
echo "  - Log Group: $LOG_GROUP"
echo "  - Agent Role: $AGENT_ROLE_ARN"
echo ""

# Create Agent Space configuration
echo -e "${YELLOW}Creating DevOps Agent Space configuration...${NC}"

AGENT_SPACE_CONFIG=$(cat <<EOF
{
  "name": "${PROJECT_NAME}-${ENVIRONMENT}",
  "description": "DevOps Agent Space for ${PROJECT_NAME} ECS application",
  "resources": {
    "ecsCluster": "${ECS_CLUSTER}",
    "ecsService": "${ECS_SERVICE}",
    "cloudWatchLogGroup": "${LOG_GROUP}",
    "iamRole": "${AGENT_ROLE_ARN}"
  },
  "integrations": {
    "cloudWatch": {
      "enabled": true,
      "logGroup": "${LOG_GROUP}",
      "metricNamespace": "AWS/ECS"
    },
    "github": {
      "enabled": true,
      "repository": "${GITHUB_REPOSITORY:-}",
      "correlateDeployments": true
    }
  },
  "alerting": {
    "enabled": true,
    "channels": ["cloudwatch"]
  },
  "investigation": {
    "autoCreate": true,
    "triggers": [
      "alarm",
      "deployment",
      "error-spike"
    ]
  }
}
EOF
)

# Save configuration to SSM Parameter Store
echo "$AGENT_SPACE_CONFIG" | aws ssm put-parameter \
    --name "/${PROJECT_NAME}-${ENVIRONMENT}/devops-agent/space-config" \
    --value file:///dev/stdin \
    --type String \
    --overwrite \
    --region $AWS_REGION

echo -e "${GREEN}✓ Agent Space configuration saved to SSM${NC}"
echo ""

# Display setup instructions
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Configure GitHub integration (if not already done):"
echo "   - Add GitHub personal access token to secrets"
echo "   - Set GITHUB_REPOSITORY environment variable"
echo ""
echo "2. Access the DevOps Agent Space:"
echo "   - Space Name: ${PROJECT_NAME}-${ENVIRONMENT}"
echo "   - ECS Cluster: ${ECS_CLUSTER}"
echo "   - ECS Service: ${ECS_SERVICE}"
echo ""
echo "3. Test incident scenarios:"
echo "   ./scripts/trigger-incidents.sh error-spike"
echo ""
echo -e "${GREEN}Configuration saved to: /${PROJECT_NAME}-${ENVIRONMENT}/devops-agent/space-config${NC}"
