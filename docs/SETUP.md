# Detailed Setup Guide

This guide provides step-by-step instructions for setting up the AWS DevOps Agent demo project.

## Prerequisites

### Required Tools
- AWS CLI v2.x or later
- Terraform v1.0 or later
- Docker v20.x or later
- Git
- jq (for JSON parsing in scripts)
- Node.js 18+ (for local development)

### AWS Account Requirements
- AWS account with administrative access
- AWS CLI configured with credentials
- Sufficient service limits for:
  - VPC (1)
  - ECS Fargate tasks (2)
  - Application Load Balancer (1)
  - NAT Gateways (2)

### Estimated Costs
- **Monthly**: ~$56 USD (us-east-1)
  - ECS Fargate: ~$30
  - ALB: ~$20
  - NAT Gateways: ~$64 (can be reduced to 1 for demo)
  - CloudWatch: ~$5
  - ECR: ~$1

## Step 1: Clone Repository

```bash
git clone <your-repo-url>
cd aws-devops-agent-demo
```

## Step 2: Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

## Step 3: Customize Configuration (Optional)

Edit `terraform/terraform.tfvars`:

```hcl
aws_region         = "us-east-1"
project_name       = "devops-agent-demo"
environment        = "dev"
desired_count      = 2
container_cpu      = 256
container_memory   = 512
github_repo        = "your-username/your-repo"
```

## Step 4: Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

This will create:
- VPC with public/private subnets
- ECS cluster and service
- Application Load Balancer
- ECR repository
- CloudWatch log groups and alarms
- IAM roles and policies

**Note**: Initial deployment takes approximately 10-15 minutes.

## Step 5: Build and Push Docker Image

```bash
# Get ECR repository URL
ECR_REPO=$(cd terraform && terraform output -raw ecr_repository_url)
AWS_REGION=$(cd terraform && terraform output -raw aws_region || echo "us-east-1")

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

# Build and push image
cd app
docker build -t $ECR_REPO:latest .
docker push $ECR_REPO:latest
cd ..
```

## Step 6: Deploy Application to ECS

The ECS service will automatically pull the image and start tasks.

```bash
# Check service status
ECS_CLUSTER=$(cd terraform && terraform output -raw ecs_cluster_name)
ECS_SERVICE=$(cd terraform && terraform output -raw ecs_service_name)

aws ecs describe-services \
  --cluster $ECS_CLUSTER \
  --services $ECS_SERVICE \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'
```

Wait for `runningCount` to equal `desiredCount`.

## Step 7: Verify Deployment

```bash
# Get ALB URL
ALB_URL=$(cd terraform && terraform output -raw alb_url)

# Test health endpoint
curl $ALB_URL/health

# Expected response:
# {"status":"healthy","uptime":123.456,"memory":{...},"timestamp":"..."}
```

## Step 8: Setup GitHub Actions (Optional)

### Add GitHub Secrets

In your GitHub repository, go to Settings > Secrets and variables > Actions, and add:

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_REGION`: Your AWS region (e.g., us-east-1)
- `ECR_REPOSITORY`: ECR repository name (from Terraform output)
- `ECS_CLUSTER`: ECS cluster name (from Terraform output)
- `ECS_SERVICE`: ECS service name (from Terraform output)

### Trigger Deployment

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

The GitHub Actions workflow will:
1. Build Docker image
2. Push to ECR
3. Update ECS service
4. Record deployment metadata

## Step 9: Configure DevOps Agent Space

```bash
# Make script executable
chmod +x scripts/setup-agent-space.sh

# Run setup script
./scripts/setup-agent-space.sh
```

This script:
- Retrieves infrastructure information
- Creates Agent Space configuration
- Stores configuration in SSM Parameter Store

## Step 10: Verify Monitoring Setup

### Check CloudWatch Dashboard

```bash
# Open CloudWatch dashboard
aws cloudwatch get-dashboard \
  --dashboard-name devops-agent-demo-dev \
  --query 'DashboardBody' \
  --output text | jq .
```

### View Logs

```bash
# Tail logs
aws logs tail /ecs/devops-agent-demo-dev --follow
```

### Check Alarms

```bash
# List alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix "devops-agent-demo" \
  --query 'MetricAlarms[*].[AlarmName,StateValue]' \
  --output table
```

## Step 11: Test Application Endpoints

```bash
ALB_URL=$(cd terraform && terraform output -raw alb_url)

# Home page
curl $ALB_URL/

# Health check
curl $ALB_URL/health

# Metrics
curl $ALB_URL/metrics
```

## Troubleshooting

### Issue: ECS Tasks Not Starting

**Check task logs:**
```bash
aws logs tail /ecs/devops-agent-demo-dev --follow
```

**Common causes:**
- Image not found in ECR
- Insufficient memory/CPU
- Security group misconfiguration

**Solution:**
```bash
# Verify image exists
aws ecr describe-images --repository-name devops-agent-demo-dev

# Check task definition
aws ecs describe-task-definition --task-definition devops-agent-demo-dev-task
```

### Issue: ALB Health Checks Failing

**Check target health:**
```bash
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
  --names devops-agent-demo-dev-tg \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

aws elbv2 describe-target-health \
  --target-group-arn $TARGET_GROUP_ARN
```

**Common causes:**
- Application not listening on correct port
- Security group blocking traffic
- Health check path incorrect

**Solution:**
```bash
# Verify security group rules
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=devops-agent-demo-dev-ecs-tasks-sg"
```

### Issue: Cannot Access Application

**Verify ALB is active:**
```bash
aws elbv2 describe-load-balancers \
  --names devops-agent-demo-dev-alb \
  --query 'LoadBalancers[0].State'
```

**Check DNS resolution:**
```bash
ALB_DNS=$(cd terraform && terraform output -raw alb_dns_name)
nslookup $ALB_DNS
```

### Issue: High Costs

**Reduce NAT Gateways:**

Edit `terraform/variables.tf`:
```hcl
variable "availability_zones" {
  default = ["us-east-1a"]  # Use only 1 AZ
}
```

**Use Fargate Spot:**

Edit `terraform/ecs.tf`:
```hcl
capacity_providers = ["FARGATE_SPOT"]
```

**Reduce task count:**
```hcl
variable "desired_count" {
  default = 1
}
```

## Cleanup

To avoid ongoing charges, destroy all resources:

```bash
cd terraform
terraform destroy
```

**Note**: This will delete:
- All ECS tasks and services
- Load balancer
- VPC and networking components
- CloudWatch logs (after retention period)
- ECR images

## Next Steps

- [Testing Guide](TESTING.md) - Learn how to trigger and test incident scenarios
- Configure email notifications for CloudWatch alarms
- Set up GitHub integration for deployment correlation
- Customize monitoring dashboards
- Add custom metrics to application

## Support

For issues or questions:
1. Check CloudWatch logs for errors
2. Review Terraform state for resource status
3. Verify AWS service limits
4. Check GitHub Actions logs for CI/CD issues
