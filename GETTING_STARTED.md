# Getting Started with AWS DevOps Agent Demo

Welcome! This guide will help you get started with the AWS DevOps Agent demo project based on your goals and experience level.

## Choose Your Path

### 🚀 I want to deploy quickly (20 minutes)
**Best for**: Quick evaluation, demos, learning the basics

**Follow**: [QUICKSTART.md](QUICKSTART.md)

**You'll learn**:
- How to deploy the infrastructure
- How to run the application
- How to trigger basic incidents

---

### 📚 I want to understand everything (1-2 hours)
**Best for**: Deep learning, production planning, architecture review

**Follow this sequence**:
1. [README.md](README.md) - Overview
2. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Complete summary
3. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Architecture details
4. [docs/SETUP.md](docs/SETUP.md) - Detailed setup
5. [docs/TESTING.md](docs/TESTING.md) - Testing guide

**You'll learn**:
- Complete architecture and design decisions
- All AWS services and how they interact
- Best practices and production considerations
- Comprehensive testing strategies

---

### 🔧 I want to customize for my needs (30 minutes + customization time)
**Best for**: Adapting the project, building on top of it

**Follow**:
1. [QUICKSTART.md](QUICKSTART.md) - Deploy first
2. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Understand structure
3. Modify `terraform/terraform.tfvars` - Configure
4. Edit `app/src/index.js` - Customize application
5. Update `terraform/*.tf` - Adjust infrastructure

**You'll learn**:
- How to modify configuration
- How to add custom endpoints
- How to adjust infrastructure
- How to integrate with your tools

---

### 🧪 I want to test DevOps Agent (30 minutes)
**Best for**: Evaluating DevOps Agent capabilities

**Follow**:
1. [QUICKSTART.md](QUICKSTART.md) - Deploy infrastructure
2. [docs/TESTING.md](docs/TESTING.md) - Testing guide
3. Run `make test-all` - Execute all scenarios
4. Review investigations in AWS Console

**You'll learn**:
- DevOps Agent investigation features
- How to trigger and monitor incidents
- Log analysis and code correlation
- Incident response workflows

---

### 🐛 I'm having issues (Variable time)
**Best for**: Troubleshooting deployment or runtime issues

**Follow**:
1. [docs/FAQ.md](docs/FAQ.md) - Common questions
2. [docs/SETUP.md](docs/SETUP.md) - Troubleshooting section
3. Run `./scripts/validate-setup.sh` - Validate setup
4. Check CloudWatch logs: `make logs`

**You'll learn**:
- Common issues and solutions
- How to diagnose problems
- Where to find logs and metrics
- How to get help

---

## Prerequisites Checklist

Before starting, ensure you have:

### Required
- [ ] AWS Account with admin access
- [ ] AWS CLI v2.x installed and configured
- [ ] Terraform v1.0+ installed
- [ ] Docker v20.x+ installed and running
- [ ] Git installed
- [ ] ~$60-120/month budget (or plan to destroy after testing)

### Optional
- [ ] Node.js 18+ (for local development)
- [ ] jq (for JSON parsing in scripts)
- [ ] GitHub account (for CI/CD)

### Verify Prerequisites

```bash
# Check AWS CLI
aws --version
aws sts get-caller-identity

# Check Terraform
terraform --version

# Check Docker
docker --version
docker ps

# Check Git
git --version
```

## Quick Decision Tree

```
Do you have 20 minutes?
├─ Yes → Follow QUICKSTART.md
└─ No → Bookmark and come back later

Have you deployed before?
├─ Yes → Go to docs/TESTING.md
└─ No → Follow DEPLOYMENT_CHECKLIST.md

Are you comfortable with AWS?
├─ Yes → Use Makefile commands
└─ No → Follow detailed docs/SETUP.md

Do you want to customize?
├─ Yes → Read docs/ARCHITECTURE.md first
└─ No → Use default configuration

Having issues?
├─ Yes → Check docs/FAQ.md
└─ No → Great! Continue testing
```

## Learning Paths by Role

### DevOps Engineer
**Goal**: Deploy and manage infrastructure

**Path**:
1. [QUICKSTART.md](QUICKSTART.md) - Deploy
2. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Understand
3. Review `terraform/` - Study IaC
4. [docs/TESTING.md](docs/TESTING.md) - Test
5. Customize for your needs

**Time**: 2-3 hours

---

### Software Developer
**Goal**: Understand application and APIs

**Path**:
1. [README.md](README.md) - Overview
2. [QUICKSTART.md](QUICKSTART.md) - Deploy
3. Review `app/src/index.js` - Study code
4. [docs/ENDPOINTS.md](docs/ENDPOINTS.md) - API reference
5. Add custom endpoints

**Time**: 1-2 hours

---

### SRE/Operations
**Goal**: Learn monitoring and incident response

**Path**:
1. [QUICKSTART.md](QUICKSTART.md) - Deploy
2. [docs/TESTING.md](docs/TESTING.md) - Test scenarios
3. Review `terraform/cloudwatch.tf` - Monitoring
4. Practice incident response
5. Integrate with your tools

**Time**: 2-3 hours

---

### Manager/Architect
**Goal**: Evaluate solution and understand costs

**Path**:
1. [README.md](README.md) - Overview
2. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Details
3. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Design
4. Review cost estimates
5. Watch demo or have team deploy

**Time**: 30-60 minutes (reading only)

---

### Student/Learner
**Goal**: Learn AWS and DevOps practices

**Path**:
1. [README.md](README.md) - Start here
2. [QUICKSTART.md](QUICKSTART.md) - Deploy
3. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Learn
4. [docs/TESTING.md](docs/TESTING.md) - Experiment
5. Modify and break things!

**Time**: 3-4 hours (hands-on learning)

---

## First-Time Setup (Detailed)

### Step 1: Prepare Your Environment (5 minutes)

```bash
# Clone repository
git clone <your-repo-url>
cd aws-devops-agent-demo

# Verify tools
./scripts/validate-setup.sh
```

### Step 2: Configure AWS (2 minutes)

```bash
# Configure credentials
aws configure

# Verify access
aws sts get-caller-identity
```

### Step 3: Customize Configuration (2 minutes)

```bash
# Copy example config
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit if needed (optional)
nano terraform/terraform.tfvars
```

### Step 4: Deploy Infrastructure (10-15 minutes)

```bash
# Initialize and deploy
make init
make apply
```

Type `yes` when prompted.

### Step 5: Deploy Application (5 minutes)

```bash
# Build and push
make build
make push

# Wait for tasks to be healthy
make status
```

### Step 6: Verify Deployment (2 minutes)

```bash
# Get URL
make url

# Test application
curl $(make url)/health
```

### Step 7: Setup DevOps Agent (2 minutes)

```bash
# Configure Agent Space
make setup-agent
```

### Step 8: Test Incident Response (5 minutes)

```bash
# Trigger test scenario
make test-error-spike

# Monitor results
make logs
make alarms
```

**Total Time**: ~30-40 minutes

## Common First-Time Issues

### Issue: "AWS credentials not configured"
**Solution**: Run `aws configure` and enter your credentials

### Issue: "Terraform state locked"
**Solution**: Wait a few minutes or run `terraform force-unlock <LOCK_ID>`

### Issue: "Docker daemon not running"
**Solution**: Start Docker Desktop or Docker service

### Issue: "Tasks not starting"
**Solution**: Check logs with `make logs` and verify ECR image exists

### Issue: "Can't access application"
**Solution**: Wait 2-3 minutes for ALB to become active, then try again

## What to Expect

### During Deployment
- Terraform will create ~40 AWS resources
- You'll see progress in the terminal
- Some resources (NAT Gateway) take 5-10 minutes
- Total deployment: 10-15 minutes

### After Deployment
- Application accessible via ALB URL
- 2 ECS tasks running
- CloudWatch logs streaming
- 5 alarms in OK state
- Dashboard available in CloudWatch

### During Testing
- Alarms will trigger (expected!)
- Logs will show errors (intentional!)
- DevOps Agent will create investigations
- You can restore with `make cleanup`

## Success Criteria

You've successfully deployed when:
- ✅ `make status` shows 2/2 tasks running
- ✅ `curl $(make url)/health` returns 200 OK
- ✅ `make alarms` shows all alarms in OK state
- ✅ CloudWatch dashboard shows metrics
- ✅ `make test-error-spike` triggers alarm

## Next Steps After Deployment

### Immediate (5 minutes)
1. Test all endpoints: `curl $(make url)/`
2. View CloudWatch dashboard
3. Check logs: `make logs`

### Short-term (30 minutes)
1. Run all test scenarios: `make test-all`
2. Review DevOps Agent investigations
3. Explore CloudWatch metrics

### Medium-term (1-2 hours)
1. Customize application code
2. Add custom metrics
3. Modify alarm thresholds
4. Integrate with your tools

### Long-term (Ongoing)
1. Adapt for production use
2. Add authentication
3. Implement auto-scaling
4. Set up multi-region

## Cost Management

### During Testing
- **Cost**: ~$0.08/hour
- **Recommendation**: Destroy when not in use

### For Learning
- **Cost**: ~$2/day
- **Recommendation**: Deploy during work hours, destroy overnight

### For Demo/POC
- **Cost**: ~$56-120/month
- **Recommendation**: Use single AZ and 1 task to minimize costs

### Cleanup
```bash
make destroy
```

## Getting Help

### Self-Service Resources
1. **[docs/FAQ.md](docs/FAQ.md)** - Common questions
2. **[docs/SETUP.md](docs/SETUP.md)** - Troubleshooting
3. **`./scripts/validate-setup.sh`** - Validation tool
4. **`make logs`** - View application logs

### Community Support
1. Search GitHub Issues
2. Create new issue with:
   - Error messages
   - Steps to reproduce
   - Terraform/CloudWatch logs
   - Output of `validate-setup.sh`

## Recommended Reading Order

### Minimum (Quick Start)
1. README.md
2. QUICKSTART.md

**Time**: 15 minutes reading + 20 minutes deployment

### Standard (Complete Understanding)
1. README.md
2. QUICKSTART.md
3. PROJECT_SUMMARY.md
4. docs/ARCHITECTURE.md
5. docs/TESTING.md

**Time**: 1-2 hours reading + 30 minutes deployment

### Comprehensive (Deep Dive)
1. All of the above, plus:
6. docs/SETUP.md
7. docs/ENDPOINTS.md
8. docs/FAQ.md
9. Review all Terraform code
10. Review application code

**Time**: 3-4 hours

## Tips for Success

### Do's ✅
- Read QUICKSTART.md before deploying
- Verify prerequisites first
- Follow the deployment checklist
- Test one scenario at a time
- Monitor CloudWatch during tests
- Destroy resources when done

### Don'ts ❌
- Don't skip prerequisite checks
- Don't modify multiple things at once
- Don't ignore error messages
- Don't leave resources running unnecessarily
- Don't test in production (this is a demo!)

## Keyboard Shortcuts (Makefile)

```bash
make help          # Show all commands
make init          # Initialize Terraform
make apply         # Deploy infrastructure
make build         # Build Docker image
make push          # Push to ECR
make deploy        # Build + push + update ECS
make logs          # Tail logs
make alarms        # Show alarms
make status        # Application status
make url           # Show URL
make test-all      # Run all tests
make cleanup       # Restore health
make destroy       # Delete everything
```

## Visual Progress Indicator

```
Prerequisites ✓
    ↓
Configure AWS ✓
    ↓
Deploy Infrastructure ⏳ (10-15 min)
    ↓
Build & Push Image ⏳ (5 min)
    ↓
Verify Deployment ✓
    ↓
Setup DevOps Agent ✓
    ↓
Test Scenarios ✓
    ↓
Review Investigations ✓
    ↓
Cleanup & Destroy ✓
```

## Ready to Start?

Choose your path:
- **Quick**: [QUICKSTART.md](QUICKSTART.md)
- **Detailed**: [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
- **Learning**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Testing**: [docs/TESTING.md](docs/TESTING.md)

---

**Questions?** Check [docs/FAQ.md](docs/FAQ.md) or [INDEX.md](INDEX.md) for navigation help!

**Good luck! 🚀**
