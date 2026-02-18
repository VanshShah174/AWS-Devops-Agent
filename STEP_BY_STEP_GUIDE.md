# Step-by-Step Guide to Make This Project Work

## 🎯 Goal
Deploy a working AWS DevOps Agent demo that automatically investigates incidents in your ECS application.

## ⏱️ Total Time: ~30 minutes

---

## 📋 Prerequisites (5 minutes)

### 1. Install Required Tools

**Check if you have them:**
```bash
aws --version        # Need: AWS CLI v2.x
terraform --version  # Need: Terraform v1.0+
docker --version     # Need: Docker v20.x+
git --version        # Need: Git
```

**If missing, install:**
- **AWS CLI**: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- **Terraform**: https://developer.hashicorp.com/terraform/downloads
- **Docker**: https://docs.docker.com/get-docker/
- **Git**: https://git-scm.com/downloads

### 2. AWS Account Setup

**You need:**
- AWS Account (free tier eligible)
- IAM user with admin permissions
- Access key and secret key

**Get your credentials:**
1. Log into AWS Console
2. Go to IAM → Users → Your User → Security Credentials
3. Create Access Key → CLI
4. Save the Access Key ID and Secret Access Key

---

## 🚀 Step 1: Configure AWS CLI (2 minutes)

```bash
# Configure AWS credentials
aws configure

# Enter when prompted:
AWS Access Key ID: [paste your access key]
AWS Secret Access Key: [paste your secret key]
Default region name: us-east-1
Default output format: json

# Verify it works
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "AIDAXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

✅ **Success!** AWS CLI is configured.

---

## 📥 Step 2: Clone the Repository (1 minute)

```bash
# Clone the project
git clone <your-repo-url>
cd aws-devops-agent-demo

# Verify files exist
ls -la
```

**You should see:**
```
README.md
terraform/
app/
scripts/
docs/
.github/
```

✅ **Success!** Repository cloned.

---

## ⚙️ Step 3: Configure the Project (2 minutes)

### Option A: Use Default Configuration (Recommended)

```bash
# Copy example configuration
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Use defaults - no changes needed!
```

### Option B: Customize (Optional)

```bash
# Edit configuration
nano terraform/terraform.tfvars

# Change these if you want:
aws_region = "us-east-1"           # Your preferred region
project_name = "devops-agent-demo"  # Your project name
environment = "dev"                 # Environment name
```

**For cost optimization, ensure these are set:**
```hcl
availability_zones = ["us-east-1a"]  # Single AZ only
desired_count = 1                     # Single task
```

✅ **Success!** Configuration ready.

---

## 🏗️ Step 4: Deploy Infrastructure with Terraform (10-15 minutes)

### Initialize Terraform

```bash
cd terraform

# Initialize Terraform (downloads providers)
terraform init
```

**Expected output:**
```
Terraform has been successfully initialized!
```

### Review What Will Be Created

```bash
# See what Terraform will create
terraform plan
```

**You'll see:**
- ~40 resources to be created
- VPC, subnets, security groups
- ECS cluster and service
- Load balancer
- CloudWatch alarms
- ECR repository

### Deploy Everything

```bash
# Deploy infrastructure
terraform apply

# Type 'yes' when prompted
```

**This takes 10-15 minutes.** ☕ Grab coffee!

**Progress indicators:**
```
Creating VPC...                    ✓
Creating subnets...                ✓
Creating NAT gateway...            ⏳ (slowest - 5 min)
Creating ECS cluster...            ✓
Creating load balancer...          ✓
Creating CloudWatch alarms...      ✓
```

**When complete, you'll see:**
```
Apply complete! Resources: 40 added, 0 changed, 0 destroyed.

Outputs:
alb_url = "http://devops-agent-demo-dev-alb-123456789.us-east-1.elb.amazonaws.com"
ecr_repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/devops-agent-demo-dev"
ecs_cluster_name = "devops-agent-demo-dev-cluster"
```

**Save these outputs!** You'll need them.

✅ **Success!** Infrastructure deployed.

---

## 🐳 Step 5: Build and Push Docker Image (5 minutes)

### Get ECR Repository URL

```bash
# Still in terraform/ directory
ECR_REPO=$(terraform output -raw ecr_repository_url)
echo $ECR_REPO
```

### Login to ECR

```bash
# Login to Amazon ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REPO
```

**Expected output:**
```
Login Succeeded
```

### Build Docker Image

```bash
# Go to app directory
cd ../app

# Build the image
docker build -t devops-agent-demo:latest .
```

**Expected output:**
```
Successfully built abc123def456
Successfully tagged devops-agent-demo:latest
```

### Tag and Push to ECR

```bash
# Tag the image
docker tag devops-agent-demo:latest $ECR_REPO:latest

# Push to ECR
docker push $ECR_REPO:latest
```

**Expected output:**
```
latest: digest: sha256:abc123... size: 1234
```

✅ **Success!** Docker image pushed to ECR.

---

## 🚀 Step 6: Wait for ECS Tasks to Start (3-5 minutes)

### Check ECS Service Status

```bash
# Go back to terraform directory
cd ../terraform

# Get cluster and service names
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name)
ECS_SERVICE=$(terraform output -raw ecs_service_name)

# Check service status
aws ecs describe-services \
  --cluster $ECS_CLUSTER \
  --services $ECS_SERVICE \
  --query 'services[0].{desired:desiredCount,running:runningCount,pending:pendingCount}'
```

**Wait until:**
```json
{
    "desired": 1,
    "running": 1,
    "pending": 0
}
```

**This takes 3-5 minutes** for:
- ECS to pull image from ECR
- Container to start
- Health checks to pass
- ALB to mark target as healthy

### Check if it's ready

```bash
# Check every 30 seconds
watch -n 30 'aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query "services[0].runningCount"'

# Press Ctrl+C when it shows: 1
```

✅ **Success!** ECS task is running.

---

## ✅ Step 7: Verify Application is Working (2 minutes)

### Get Application URL

```bash
# Get ALB URL
ALB_URL=$(terraform output -raw alb_url)
echo "Application URL: $ALB_URL"
```

### Test the Application

```bash
# Test home endpoint
curl $ALB_URL/

# Expected response:
{
  "service": "DevOps Agent Demo",
  "version": "1.0.0",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "requestCount": 1,
  "environment": "dev"
}

# Test health endpoint
curl $ALB_URL/health

# Expected response:
{
  "status": "healthy",
  "uptime": 123.456,
  "memory": {...},
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

**If you get errors:**
- Wait 2 more minutes (ALB might still be warming up)
- Check ECS task logs: `aws logs tail /ecs/devops-agent-demo-dev --follow`

✅ **Success!** Application is running and accessible.

---

## 🤖 Step 8: Setup DevOps Agent (2 minutes)

```bash
# Go back to project root
cd ..

# Make script executable
chmod +x scripts/setup-agent-space.sh

# Run setup script
./scripts/setup-agent-space.sh
```

**Expected output:**
```
=== AWS DevOps Agent Space Setup ===
✓ AWS credentials configured
✓ Infrastructure information retrieved
✓ Agent Space configuration saved to SSM
```

✅ **Success!** DevOps Agent configured.

---

## 🧪 Step 9: Test Incident Response (5 minutes)

### Trigger an Error Spike

```bash
# Make script executable
chmod +x scripts/trigger-incidents.sh

# Trigger error spike
./scripts/trigger-incidents.sh error-spike
```

**Expected output:**
```
Triggering error spike...
....................
✓ Error spike triggered (20 requests)
Expected: High 5XX error alarm should trigger
```

### Wait for Alarm to Trigger (2-3 minutes)

```bash
# Check alarm status
aws cloudwatch describe-alarms \
  --alarm-names "devops-agent-demo-dev-high-5xx-errors" \
  --query 'MetricAlarms[0].StateValue'

# Wait until it shows: "ALARM"
```

### View DevOps Agent Investigation

**Option 1: AWS Console (Recommended)**
```
1. Open AWS Console
2. Search for "DevOps Agent" service
3. Click "Agent Spaces"
4. Select "devops-agent-demo-dev"
5. Click "Investigations" tab
6. Click on the latest investigation
```

**You'll see:**
- Timeline of events
- Log analysis
- Root cause assessment
- Recommendations

**Option 2: AWS CLI**
```bash
# List investigations
aws devops-agent list-investigations \
  --agent-space-name devops-agent-demo-dev
```

✅ **Success!** DevOps Agent investigated the incident automatically!

---

## 📊 Step 10: View Monitoring (Optional)

### View CloudWatch Logs

```bash
# Tail logs in real-time
aws logs tail /ecs/devops-agent-demo-dev --follow

# Press Ctrl+C to stop
```

### View CloudWatch Dashboard

```
1. Open AWS Console
2. Go to CloudWatch → Dashboards
3. Select "devops-agent-demo-dev"
4. View metrics and graphs
```

### Check All Alarms

```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix "devops-agent-demo-dev" \
  --query 'MetricAlarms[*].[AlarmName,StateValue]' \
  --output table
```

---

## 🎉 Success! Your Project is Working!

### What You've Accomplished:

✅ Deployed complete AWS infrastructure with Terraform  
✅ Containerized application running on ECS  
✅ Load balancer distributing traffic  
✅ CloudWatch monitoring and alarms  
✅ DevOps Agent automatically investigating incidents  
✅ Tested incident response workflow  

---

## 🧹 Step 11: Cleanup (When Done Testing)

### ⚠️ IMPORTANT: Destroy Resources to Avoid Charges

```bash
# Go to terraform directory
cd terraform

# Destroy everything
terraform destroy

# Type 'yes' when prompted
```

**This takes 5-10 minutes.**

### Verify Everything is Deleted

```bash
# Check ECS clusters
aws ecs list-clusters

# Check NAT gateways (most expensive)
aws ec2 describe-nat-gateways \
  --filter "Name=state,Values=available" \
  --query 'NatGateways[*].NatGatewayId'

# Should return empty: []
```

✅ **Success!** All resources cleaned up.

---

## 🔄 Complete Flow Summary

```
1. Prerequisites (5 min)
   ├─ Install AWS CLI, Terraform, Docker
   └─ Get AWS credentials

2. Configure AWS CLI (2 min)
   └─ aws configure

3. Clone Repository (1 min)
   └─ git clone

4. Configure Project (2 min)
   └─ cp terraform.tfvars.example terraform.tfvars

5. Deploy Infrastructure (10-15 min)
   ├─ terraform init
   ├─ terraform plan
   └─ terraform apply

6. Build & Push Docker Image (5 min)
   ├─ docker build
   └─ docker push to ECR

7. Wait for ECS Tasks (3-5 min)
   └─ Check service status

8. Verify Application (2 min)
   └─ curl $ALB_URL/health

9. Setup DevOps Agent (2 min)
   └─ ./scripts/setup-agent-space.sh

10. Test Incident Response (5 min)
    ├─ ./scripts/trigger-incidents.sh error-spike
    └─ View investigation in AWS Console

11. Cleanup (5-10 min)
    └─ terraform destroy
```

**Total Time: ~30-40 minutes**

---

## 🆘 Troubleshooting

### Issue: "terraform init" fails
```bash
# Solution: Check Terraform version
terraform --version  # Need v1.0+

# Upgrade if needed
```

### Issue: "docker push" fails
```bash
# Solution: Re-login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REPO
```

### Issue: ECS tasks not starting
```bash
# Check logs
aws logs tail /ecs/devops-agent-demo-dev --follow

# Common causes:
# - Image not found in ECR (check push succeeded)
# - Insufficient memory/CPU (check task definition)
# - Security group blocking traffic
```

### Issue: Can't access application
```bash
# Wait 2-3 more minutes for ALB to warm up

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names devops-agent-demo-dev-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)
```

### Issue: Alarm not triggering
```bash
# Trigger more errors
./scripts/trigger-incidents.sh error-spike

# Wait 2-3 minutes for evaluation periods

# Check alarm manually
aws cloudwatch describe-alarms \
  --alarm-names "devops-agent-demo-dev-high-5xx-errors"
```

---

## 💰 Cost Tracking

### Expected Costs:
- **Hourly**: ~$0.05
- **Daily**: ~$1.20
- **Monthly**: ~$35 (if left running)

### Set Up Cost Alert:
```bash
# Add your email to terraform/cloudwatch.tf
# Then run: terraform apply
```

### Always Destroy When Done:
```bash
terraform destroy
```

---

## 📸 For LinkedIn Post

### Take Screenshots of:
1. ✅ Terraform apply output
2. ✅ Application running (curl output)
3. ✅ CloudWatch dashboard
4. ✅ DevOps Agent investigation report
5. ✅ ECS service running

### Record a Demo Video:
```bash
# Use OBS Studio or QuickTime to record:
1. Show terraform apply
2. Show application responding
3. Trigger incident
4. Show DevOps Agent investigation
```

---

## 🎓 What You Learned

- ✅ Infrastructure as Code with Terraform
- ✅ Container orchestration with ECS
- ✅ Docker containerization
- ✅ AWS networking (VPC, subnets, security groups)
- ✅ Load balancing with ALB
- ✅ Monitoring with CloudWatch
- ✅ AI-powered incident response with DevOps Agent
- ✅ CI/CD concepts with GitHub Actions

---

## 📚 Next Steps

1. **Customize the application** - Add your own endpoints
2. **Try other incident scenarios** - Memory leak, CPU spike
3. **Add GitHub Actions** - Automate deployments
4. **Explore DevOps Agent** - Review more investigations
5. **Share on LinkedIn** - Show what you built!

---

## 🤝 Need Help?

- Check [docs/FAQ.md](docs/FAQ.md) for common questions
- Review [docs/SETUP.md](docs/SETUP.md) for detailed troubleshooting
- Check CloudWatch logs for errors
- Verify AWS credentials are correct

---

**🎉 Congratulations! You've successfully deployed an AWS DevOps Agent demo project!**

Now go share your achievement on LinkedIn! 🚀
