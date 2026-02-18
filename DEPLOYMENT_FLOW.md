# Deployment Flow - Visual Guide

## 🎯 Complete Deployment Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    START HERE                                │
│                                                              │
│  Prerequisites: AWS CLI, Terraform, Docker, Git             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: Configure AWS CLI                                  │
│                                                              │
│  $ aws configure                                            │
│  Enter: Access Key, Secret Key, Region                      │
│                                                              │
│  ✓ Verify: aws sts get-caller-identity                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: Clone Repository                                   │
│                                                              │
│  $ git clone <repo-url>                                     │
│  $ cd aws-devops-agent-demo                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: Configure Project                                  │
│                                                              │
│  $ cp terraform/terraform.tfvars.example \                  │
│       terraform/terraform.tfvars                            │
│                                                              │
│  Optional: Edit terraform.tfvars                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: Deploy Infrastructure (10-15 min)                  │
│                                                              │
│  $ cd terraform                                             │
│  $ terraform init                                           │
│  $ terraform plan                                           │
│  $ terraform apply                                          │
│                                                              │
│  Creates:                                                   │
│  ├─ VPC & Networking                                        │
│  ├─ ECS Cluster                                             │
│  ├─ Load Balancer                                           │
│  ├─ ECR Repository                                          │
│  ├─ CloudWatch Alarms                                       │
│  └─ DevOps Agent IAM Roles                                  │
│                                                              │
│  ✓ Save outputs: ALB URL, ECR URL, Cluster name            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 5: Build & Push Docker Image (5 min)                 │
│                                                              │
│  $ cd ../app                                                │
│  $ ECR_REPO=$(terraform output -raw ecr_repository_url)     │
│  $ aws ecr get-login-password | docker login ...           │
│  $ docker build -t devops-agent-demo:latest .               │
│  $ docker tag devops-agent-demo:latest $ECR_REPO:latest    │
│  $ docker push $ECR_REPO:latest                             │
│                                                              │
│  ✓ Image pushed to ECR                                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 6: Wait for ECS Tasks (3-5 min)                      │
│                                                              │
│  ECS automatically:                                         │
│  ├─ Pulls image from ECR                                    │
│  ├─ Starts container                                        │
│  ├─ Runs health checks                                      │
│  └─ Registers with ALB                                      │
│                                                              │
│  $ aws ecs describe-services ...                            │
│  Wait for: running=1, pending=0                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 7: Verify Application (2 min)                         │
│                                                              │
│  $ ALB_URL=$(terraform output -raw alb_url)                 │
│  $ curl $ALB_URL/health                                     │
│                                                              │
│  Expected: {"status":"healthy",...}                         │
│                                                              │
│  ✓ Application is running!                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 8: Setup DevOps Agent (2 min)                        │
│                                                              │
│  $ cd ..                                                    │
│  $ chmod +x scripts/setup-agent-space.sh                   │
│  $ ./scripts/setup-agent-space.sh                          │
│                                                              │
│  Creates Agent Space configuration in SSM                   │
│                                                              │
│  ✓ DevOps Agent configured                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 9: Test Incident Response (5 min)                    │
│                                                              │
│  $ chmod +x scripts/trigger-incidents.sh                   │
│  $ ./scripts/trigger-incidents.sh error-spike              │
│                                                              │
│  What happens:                                              │
│  1. Script sends 20 error requests                          │
│  2. CloudWatch alarm triggers (2-3 min)                     │
│  3. DevOps Agent investigates automatically                 │
│  4. Investigation report ready                              │
│                                                              │
│  View in AWS Console:                                       │
│  DevOps Agent → Agent Spaces → Investigations              │
│                                                              │
│  ✓ Incident investigated automatically!                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  🎉 SUCCESS! PROJECT IS WORKING!                           │
│                                                              │
│  You now have:                                              │
│  ✓ ECS application running                                 │
│  ✓ CloudWatch monitoring active                            │
│  ✓ DevOps Agent investigating incidents                    │
│  ✓ Complete demo ready for LinkedIn!                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 10: Cleanup (When Done)                              │
│                                                              │
│  $ cd terraform                                             │
│  $ terraform destroy                                        │
│  Type: yes                                                  │
│                                                              │
│  ⚠️ IMPORTANT: Always destroy to avoid charges!            │
│                                                              │
│  ✓ All resources deleted                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Time Breakdown

```
Step 1: Configure AWS CLI          →  2 minutes
Step 2: Clone Repository            →  1 minute
Step 3: Configure Project           →  2 minutes
Step 4: Deploy Infrastructure       → 10-15 minutes ☕
Step 5: Build & Push Docker         →  5 minutes
Step 6: Wait for ECS Tasks          →  3-5 minutes
Step 7: Verify Application          →  2 minutes
Step 8: Setup DevOps Agent          →  2 minutes
Step 9: Test Incident Response      →  5 minutes
─────────────────────────────────────────────────
Total Time:                         → 30-40 minutes
```

---

## 🔄 What Happens Behind the Scenes

### During Terraform Apply:

```
Terraform reads configuration
    ↓
Creates VPC (10.0.0.0/16)
    ↓
Creates public subnet (10.0.0.0/24)
    ↓
Creates private subnet (10.0.10.0/24)
    ↓
Creates Internet Gateway
    ↓
Creates NAT Gateway (⏳ slowest - 5 min)
    ↓
Creates Security Groups
    ↓
Creates ECR Repository
    ↓
Creates ECS Cluster
    ↓
Creates Task Definition
    ↓
Creates ECS Service
    ↓
Creates Application Load Balancer
    ↓
Creates Target Group
    ↓
Creates CloudWatch Log Group
    ↓
Creates CloudWatch Alarms (5 alarms)
    ↓
Creates IAM Roles (3 roles)
    ↓
Creates SSM Parameters
    ↓
✅ Infrastructure Ready!
```

### During Docker Push:

```
Docker builds image locally
    ↓
Layers are created:
  - Base image (node:18-alpine)
  - Dependencies (npm install)
  - Application code
  - Configuration
    ↓
Image is tagged
    ↓
Layers are pushed to ECR
    ↓
✅ Image Available in ECR!
```

### During ECS Task Start:

```
ECS Service detects new image
    ↓
Pulls image from ECR
    ↓
Starts container in private subnet
    ↓
Container runs health check
    ↓
Health check passes
    ↓
Registers with ALB target group
    ↓
ALB marks target as healthy
    ↓
ALB starts routing traffic
    ↓
✅ Application Accessible!
```

### During Incident Test:

```
Script sends 20 error requests
    ↓
Application returns 500 errors
    ↓
CloudWatch receives error metrics
    ↓
Alarm evaluates threshold (2 periods)
    ↓
Alarm state: OK → ALARM
    ↓
DevOps Agent receives notification
    ↓
Agent starts investigation:
  - Gathers CloudWatch logs
  - Checks ECS task status
  - Analyzes metrics
  - Reviews deployments
  - Correlates with GitHub
    ↓
Agent generates report
    ↓
✅ Investigation Complete!
```

---

## 🎯 Success Checkpoints

### ✅ Checkpoint 1: AWS CLI Configured
```bash
$ aws sts get-caller-identity
# Should show your account info
```

### ✅ Checkpoint 2: Terraform Initialized
```bash
$ terraform init
# Should show: "Terraform has been successfully initialized!"
```

### ✅ Checkpoint 3: Infrastructure Deployed
```bash
$ terraform output
# Should show: alb_url, ecr_repository_url, etc.
```

### ✅ Checkpoint 4: Docker Image Pushed
```bash
$ aws ecr describe-images --repository-name devops-agent-demo-dev
# Should show at least 1 image
```

### ✅ Checkpoint 5: ECS Task Running
```bash
$ aws ecs describe-services --cluster ... --services ...
# Should show: runningCount: 1
```

### ✅ Checkpoint 6: Application Responding
```bash
$ curl $ALB_URL/health
# Should return: {"status":"healthy",...}
```

### ✅ Checkpoint 7: DevOps Agent Configured
```bash
$ aws ssm get-parameter --name "/devops-agent-demo-dev/devops-agent/space-config"
# Should return configuration
```

### ✅ Checkpoint 8: Alarm Triggered
```bash
$ aws cloudwatch describe-alarms --alarm-names "devops-agent-demo-dev-high-5xx-errors"
# Should show: StateValue: "ALARM"
```

---

## 🚨 Common Issues & Quick Fixes

### Issue: Terraform apply fails
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check Terraform version
terraform --version  # Need v1.0+
```

### Issue: Docker push fails
```bash
# Re-login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REPO
```

### Issue: ECS task won't start
```bash
# Check logs
aws logs tail /ecs/devops-agent-demo-dev --follow

# Check if image exists in ECR
aws ecr describe-images --repository-name devops-agent-demo-dev
```

### Issue: Can't access application
```bash
# Wait 2-3 more minutes for ALB warmup

# Check target health
aws elbv2 describe-target-health --target-group-arn <arn>
```

### Issue: Alarm not triggering
```bash
# Trigger more errors
./scripts/trigger-incidents.sh error-spike

# Wait 2-3 minutes for evaluation

# Check alarm manually
aws cloudwatch describe-alarms --alarm-names "devops-agent-demo-dev-high-5xx-errors"
```

---

## 💡 Pro Tips

1. **Save your outputs** after terraform apply
2. **Wait patiently** for NAT Gateway (5 min)
3. **Check logs** if something fails
4. **Always destroy** when done testing
5. **Take screenshots** for LinkedIn post
6. **Test incrementally** - verify each step

---

## 📸 Screenshot Checklist for LinkedIn

- [ ] Terraform apply success output
- [ ] Application health check response
- [ ] CloudWatch dashboard with metrics
- [ ] DevOps Agent investigation report
- [ ] ECS service showing running tasks
- [ ] Architecture diagram (optional)

---

**Follow this flow and you'll have a working demo in 30-40 minutes!** 🚀
