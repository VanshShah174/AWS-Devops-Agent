# Quick Start Guide

Get the AWS DevOps Agent demo up and running in under 30 minutes.

## Prerequisites Check

```bash
# Check AWS CLI
aws --version

# Check Terraform
terraform --version

# Check Docker
docker --version

# Check AWS credentials
aws sts get-caller-identity
```

## 5-Step Setup

### Step 1: Clone and Configure (2 minutes)

```bash
git clone <your-repo-url>
cd aws-devops-agent-demo

# Copy example config
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit if needed (optional)
# nano terraform/terraform.tfvars
```

### Step 2: Deploy Infrastructure (10-15 minutes)

```bash
make init
make apply
```

Type `yes` when prompted.

### Step 3: Build and Deploy Application (5 minutes)

```bash
make build
make push
```

Wait for ECS tasks to become healthy:
```bash
make status
```

### Step 4: Verify Deployment (1 minute)

```bash
# Get application URL
make url

# Test the application
curl $(make url)/health
```

Expected response:
```json
{"status":"healthy","uptime":123.456,...}
```

### Step 5: Setup DevOps Agent (2 minutes)

```bash
make setup-agent
```

## Test Incident Response

### Quick Test - Error Spike

```bash
make test-error-spike
```

This will:
1. Send 20 error requests
2. Trigger CloudWatch alarm
3. Create DevOps Agent investigation

### View Results

```bash
# Check alarms
make alarms

# View logs
make logs

# Check application status
make status
```

## What's Next?

### Run All Test Scenarios

```bash
make test-all
```

### Monitor in Real-Time

```bash
# Terminal 1: Watch logs
make logs

# Terminal 2: Trigger incidents
make test-memory-leak
```

### Access AWS Console

**CloudWatch Dashboard**:
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=devops-agent-demo-dev
```

**ECS Cluster**:
```
https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/devops-agent-demo-dev-cluster
```

## Common Commands

```bash
# Show all available commands
make help

# Deploy code changes
make deploy

# View application URL
make url

# Tail logs
make logs

# Check alarm status
make alarms

# Run specific test
make test-cpu-spike

# Cleanup after testing
make cleanup

# Destroy everything
make destroy
```

## Troubleshooting

### Tasks Not Starting

```bash
# Check service events
aws ecs describe-services \
  --cluster devops-agent-demo-dev-cluster \
  --services devops-agent-demo-dev-service \
  --query 'services[0].events[0:5]'

# Check logs
make logs
```

### Can't Access Application

```bash
# Verify ALB is active
aws elbv2 describe-load-balancers \
  --names devops-agent-demo-dev-alb \
  --query 'LoadBalancers[0].State'

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups --names devops-agent-demo-dev-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
```

### High Costs

Reduce to single AZ and 1 task:

```bash
# Edit terraform/terraform.tfvars
availability_zones = ["us-east-1a"]
desired_count = 1

# Apply changes
make apply
```

## Cleanup

When you're done testing:

```bash
make destroy
```

Type `yes` to confirm.

## Full Documentation

- [Detailed Setup Guide](docs/SETUP.md)
- [Testing Scenarios](docs/TESTING.md)
- [Architecture Overview](docs/ARCHITECTURE.md)

## Support

- Check logs: `make logs`
- View alarms: `make alarms`
- Application status: `make status`
- GitHub Issues: [Report a problem]

## Estimated Costs

- **Hourly**: ~$0.08
- **Daily**: ~$1.90
- **Monthly**: ~$56

Remember to run `make destroy` when not in use!
