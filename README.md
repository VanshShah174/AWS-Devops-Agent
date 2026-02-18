# AWS DevOps Agent Demo Project

A comprehensive demonstration of AWS DevOps Agent capabilities for incident response and monitoring in a containerized ECS environment.

## Project Overview

**What is this?** A hands-on demonstration of AWS DevOps Agent - an AI-powered service that automatically investigates operational issues in your AWS environment.

**The Problem:** When incidents occur (errors, crashes, performance issues), engineers spend 30-60 minutes manually searching logs, checking metrics, and correlating deployments to find the root cause.

**The Solution:** AWS DevOps Agent does this automatically in 2-3 minutes, providing AI-powered analysis, code correlation, and remediation recommendations.

**This Project Demonstrates:**
- Complete AWS DevOps Agent setup for ECS applications
- Automatic incident investigation when CloudWatch alarms trigger
- AI-powered log analysis and pattern detection
- Code correlation with GitHub deployments
- Container health introspection
- 5 realistic incident scenarios you can trigger and test
- 82% reduction in Mean Time To Resolution (MTTR)

**📖 See [DEVOPS_AGENT_PURPOSE.md](DEVOPS_AGENT_PURPOSE.md) for a detailed explanation of how DevOps Agent is used.**

This project also includes:
- Containerized web application on Amazon ECS with Fargate
- Infrastructure as Code using Terraform
- CI/CD pipeline with GitHub Actions
- Comprehensive monitoring with CloudWatch

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Repository                     │
│              (Code + GitHub Actions CI/CD)               │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  Amazon ECR Registry                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Application Load Balancer                   │
│                    (Public Subnet)                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   ECS Fargate Cluster                    │
│              (Private Subnet - 2 Tasks)                  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              CloudWatch Logs & Metrics                   │
│           ◄──── AWS DevOps Agent ────►                   │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- Docker installed locally
- GitHub account
- AWS CLI configured
- Node.js 18+ (for local development)

## 🚀 Quick Start - Follow This!

### **→ [STEP_BY_STEP_GUIDE.md](STEP_BY_STEP_GUIDE.md) ← START HERE!**

**Complete beginner-friendly guide (30-40 minutes):**
- ✅ Prerequisites checklist with installation links
- ✅ Step-by-step commands with expected outputs
- ✅ Troubleshooting for common issues
- ✅ Success checkpoints at each step
- ✅ Cleanup instructions to avoid charges

**Also see:** [DEPLOYMENT_FLOW.md](DEPLOYMENT_FLOW.md) for visual flow diagram

---

### Quick Commands (For Experienced Users):

```bash
# 1. Configure AWS
aws configure

# 2. Clone and setup
git clone <repo-url>
cd aws-devops-agent-demo
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# 3. Deploy infrastructure (10-15 min)
cd terraform
terraform init
terraform apply

# 4. Build & push Docker image (5 min)
cd ../app
ECR_REPO=$(cd ../terraform && terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO
docker build -t app:latest .
docker tag app:latest $ECR_REPO:latest
docker push $ECR_REPO:latest

# 5. Wait for ECS tasks to start (3-5 min)
# Check: aws ecs describe-services --cluster <cluster> --services <service>

# 6. Setup DevOps Agent (2 min)
cd ..
chmod +x scripts/setup-agent-space.sh
./scripts/setup-agent-space.sh

# 7. Test incident response (5 min)
chmod +x scripts/trigger-incidents.sh
./scripts/trigger-incidents.sh error-spike

# 8. View investigation in AWS Console
# DevOps Agent → Agent Spaces → devops-agent-demo-dev → Investigations
```

### ⚠️ IMPORTANT: Cleanup to Avoid Charges

```bash
cd terraform
terraform destroy  # Type 'yes' to confirm
```

**Estimated cost if left running:** ~$35/month (single AZ, 1 task)

```bash
aws configure
```

### 3. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. Setup GitHub Actions

Add these secrets to your GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `ECR_REPOSITORY`
- `ECS_CLUSTER`
- `ECS_SERVICE`

### 5. Deploy Application

Push to main branch to trigger CI/CD:
```bash
git push origin main
```

## Project Structure

```
.
├── app/                          # Application code
│   ├── src/
│   │   └── index.js             # Node.js application
│   ├── Dockerfile               # Container definition
│   └── package.json             # Dependencies
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                  # Main configuration
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   ├── vpc.tf                   # Network resources
│   ├── ecs.tf                   # ECS cluster & services
│   ├── alb.tf                   # Load balancer
│   ├── cloudwatch.tf            # Monitoring
│   └── devops-agent.tf          # DevOps Agent setup
├── .github/
│   └── workflows/
│       └── deploy.yml           # CI/CD pipeline
├── scripts/                      # Helper scripts
│   ├── setup-agent-space.sh     # Agent Space configuration
│   └── trigger-incidents.sh     # Test scenarios
└── docs/                         # Documentation
    ├── SETUP.md                 # Detailed setup guide
    └── TESTING.md               # Testing scenarios
```

## Application Endpoints

- `GET /` - Home page
- `GET /health` - Health check endpoint
- `GET /metrics` - Application metrics
- `GET /error/500` - Trigger 500 error
- `GET /error/timeout` - Simulate database timeout
- `GET /error/memory-leak` - Trigger memory leak
- `GET /error/cpu-spike` - Cause CPU spike

## Testing Incident Response

### Scenario 1: Application Error Spike
```bash
./scripts/trigger-incidents.sh error-spike
```

### Scenario 2: Memory Leak
```bash
./scripts/trigger-incidents.sh memory-leak
```

### Scenario 3: Container Health Failure
```bash
./scripts/trigger-incidents.sh health-failure
```

## Monitoring

Access CloudWatch dashboards:
```bash
aws cloudwatch get-dashboard --dashboard-name devops-agent-demo
```

View logs:
```bash
aws logs tail /ecs/devops-agent-demo --follow
```

## How AWS DevOps Agent is Used

**AWS DevOps Agent** is an AI-powered service that automatically investigates operational issues. In this project, it:

### 1. **Automatic Incident Investigation**
When a CloudWatch alarm triggers (e.g., high error rate), DevOps Agent automatically:
- Gathers relevant logs from CloudWatch
- Analyzes ECS task states and health
- Checks recent deployments
- Identifies error patterns
- Creates an investigation report with findings

### 2. **Code Correlation with GitHub**
Links incidents to specific code changes:
- Tracks deployment metadata from GitHub Actions
- Correlates incident timing with deployments
- Shows which commit/PR may have caused the issue
- Provides code change context

### 3. **Container Introspection**
Analyzes your ECS environment:
- Checks task health and status
- Reviews resource utilization (CPU, memory)
- Examines container configurations
- Identifies configuration issues

### 4. **Log Analysis**
Automatically searches CloudWatch logs:
- Finds error patterns and stack traces
- Identifies frequency and trends
- Highlights unusual patterns
- Provides log excerpts in investigation

### 5. **Root Cause Analysis**
Provides actionable insights:
- Suggests likely root causes
- Recommends remediation steps
- Shows related resources
- Reduces mean time to resolution (MTTR)

**See [docs/DEVOPS_AGENT_USAGE.md](docs/DEVOPS_AGENT_USAGE.md) for detailed usage examples and investigation walkthroughs.**

## Cleanup

```bash
cd terraform
terraform destroy
```

## Cost Estimation

Approximate monthly costs (us-east-1):
- ECS Fargate (2 tasks): ~$30
- ALB: ~$20
- CloudWatch: ~$5
- ECR: ~$1
- Total: ~$56/month

## Troubleshooting

See [docs/SETUP.md](docs/SETUP.md) for detailed troubleshooting steps.

## License

MIT
