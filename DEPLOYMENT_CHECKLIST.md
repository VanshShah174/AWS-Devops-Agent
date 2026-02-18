# Deployment Checklist

Use this checklist to ensure a successful deployment of the AWS DevOps Agent demo project.

## Pre-Deployment

### Prerequisites
- [ ] AWS Account created and accessible
- [ ] AWS CLI installed and configured (`aws --version`)
- [ ] Terraform installed (`terraform --version`)
- [ ] Docker installed and running (`docker --version`)
- [ ] Git installed (`git --version`)
- [ ] jq installed for JSON parsing (`jq --version`)
- [ ] Node.js 18+ installed (optional, for local dev)

### AWS Configuration
- [ ] AWS credentials configured (`aws configure`)
- [ ] Verified AWS access (`aws sts get-caller-identity`)
- [ ] Confirmed AWS region (default: us-east-1)
- [ ] Checked AWS service limits (VPC, ECS, ALB)
- [ ] Estimated monthly costs (~$56-120)

### Repository Setup
- [ ] Repository cloned locally
- [ ] Reviewed README.md
- [ ] Copied `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`
- [ ] Customized variables if needed

## Infrastructure Deployment

### Terraform Initialization
- [ ] Changed to terraform directory (`cd terraform`)
- [ ] Ran `terraform init`
- [ ] Verified provider downloads
- [ ] Reviewed initialization output

### Infrastructure Planning
- [ ] Ran `terraform plan`
- [ ] Reviewed planned resources (~40 resources)
- [ ] Verified no errors in plan
- [ ] Confirmed resource names and tags

### Infrastructure Deployment
- [ ] Ran `terraform apply`
- [ ] Reviewed apply plan
- [ ] Typed `yes` to confirm
- [ ] Waited for completion (10-15 minutes)
- [ ] Verified all resources created successfully

### Post-Infrastructure Verification
- [ ] Ran `terraform output` to view outputs
- [ ] Noted ECS cluster name
- [ ] Noted ECS service name
- [ ] Noted ALB DNS name
- [ ] Noted ECR repository URL
- [ ] Verified VPC created
- [ ] Verified subnets created
- [ ] Verified security groups created

## Application Deployment

### Docker Image Build
- [ ] Changed to app directory (`cd ../app`)
- [ ] Reviewed Dockerfile
- [ ] Built Docker image (`docker build -t devops-agent-demo:latest .`)
- [ ] Verified image built successfully
- [ ] Tested image locally (optional)

### ECR Push
- [ ] Retrieved ECR repository URL from Terraform output
- [ ] Logged in to ECR (`aws ecr get-login-password | docker login ...`)
- [ ] Tagged image with ECR URL
- [ ] Pushed image to ECR (`docker push ...`)
- [ ] Verified image in ECR console

### ECS Deployment
- [ ] Waited for ECS service to pull image
- [ ] Checked ECS service status
- [ ] Verified desired count matches running count
- [ ] Checked task health status
- [ ] Reviewed task logs in CloudWatch

### Application Verification
- [ ] Retrieved ALB URL from Terraform output
- [ ] Tested home endpoint (`curl <ALB_URL>/`)
- [ ] Tested health endpoint (`curl <ALB_URL>/health`)
- [ ] Verified 200 OK response
- [ ] Tested metrics endpoint (`curl <ALB_URL>/metrics`)
- [ ] Opened application in browser

## Monitoring Setup

### CloudWatch Configuration
- [ ] Verified log group created (`/ecs/devops-agent-demo-dev`)
- [ ] Checked logs are being written
- [ ] Verified CloudWatch dashboard created
- [ ] Opened dashboard in AWS console
- [ ] Verified all alarms created (5 alarms)
- [ ] Checked alarm states (should be OK)

### DevOps Agent Setup
- [ ] Made setup script executable (`chmod +x scripts/setup-agent-space.sh`)
- [ ] Ran setup script (`./scripts/setup-agent-space.sh`)
- [ ] Verified configuration saved to SSM
- [ ] Reviewed Agent Space configuration
- [ ] Noted Agent Space name

## GitHub Actions Setup (Optional)

### GitHub Secrets Configuration
- [ ] Opened GitHub repository settings
- [ ] Navigated to Secrets and variables > Actions
- [ ] Added `AWS_ACCESS_KEY_ID`
- [ ] Added `AWS_SECRET_ACCESS_KEY`
- [ ] Added `AWS_REGION`
- [ ] Added `ECR_REPOSITORY`
- [ ] Added `ECS_CLUSTER`
- [ ] Added `ECS_SERVICE`

### Workflow Verification
- [ ] Reviewed `.github/workflows/deploy.yml`
- [ ] Reviewed `.github/workflows/terraform.yml`
- [ ] Pushed code to trigger workflow
- [ ] Verified workflow execution
- [ ] Checked deployment success

## Testing

### Basic Functionality Tests
- [ ] Made scripts executable (`chmod +x scripts/*.sh`)
- [ ] Ran validation script (`./scripts/validate-setup.sh`)
- [ ] Verified all checks passed
- [ ] Tested all application endpoints

### Incident Scenario Tests
- [ ] Tested error spike (`make test-error-spike`)
- [ ] Verified alarm triggered
- [ ] Checked CloudWatch logs
- [ ] Tested memory leak (`make test-memory-leak`)
- [ ] Verified memory alarm
- [ ] Tested CPU spike (`make test-cpu-spike`)
- [ ] Verified CPU alarm
- [ ] Tested health failure (`make test-health-failure`)
- [ ] Verified unhealthy targets alarm
- [ ] Restored health (`curl <ALB_URL>/error/enable-health`)

### DevOps Agent Verification
- [ ] Opened AWS DevOps Agent console
- [ ] Located Agent Space
- [ ] Verified investigations created
- [ ] Reviewed log analysis
- [ ] Checked code correlation
- [ ] Verified deployment tracking

## Documentation Review

### Read Documentation
- [ ] Read README.md
- [ ] Read QUICKSTART.md
- [ ] Read docs/SETUP.md
- [ ] Read docs/TESTING.md
- [ ] Read docs/ARCHITECTURE.md
- [ ] Read PROJECT_SUMMARY.md

### Understand Commands
- [ ] Reviewed Makefile targets (`make help`)
- [ ] Tested common commands
- [ ] Understood cleanup process

## Post-Deployment

### Monitoring
- [ ] Set up CloudWatch dashboard bookmark
- [ ] Configured alarm notifications (optional)
- [ ] Set up log insights queries (optional)
- [ ] Documented custom metrics (optional)

### Cost Management
- [ ] Reviewed AWS Cost Explorer
- [ ] Set up billing alerts
- [ ] Documented expected costs
- [ ] Planned cleanup schedule

### Backup & Documentation
- [ ] Saved Terraform state location
- [ ] Documented custom configurations
- [ ] Saved important URLs and ARNs
- [ ] Created runbook for common tasks

## Cleanup (When Done)

### Application Cleanup
- [ ] Stopped running tests
- [ ] Cleared memory leaks (`curl <ALB_URL>/error/clear-memory`)
- [ ] Restored health checks
- [ ] Verified application healthy

### Infrastructure Cleanup
- [ ] Backed up any important data
- [ ] Ran `terraform destroy`
- [ ] Typed `yes` to confirm
- [ ] Waited for completion (5-10 minutes)
- [ ] Verified all resources deleted
- [ ] Checked AWS console for orphaned resources
- [ ] Verified no ongoing charges

## Troubleshooting Checklist

### If Tasks Won't Start
- [ ] Check ECR image exists
- [ ] Verify task definition
- [ ] Review IAM permissions
- [ ] Check CloudWatch logs
- [ ] Verify security groups
- [ ] Check subnet configuration

### If Health Checks Fail
- [ ] Test health endpoint directly
- [ ] Check security group rules
- [ ] Verify target group configuration
- [ ] Review application logs
- [ ] Check container port mapping

### If Alarms Don't Trigger
- [ ] Verify metrics are published
- [ ] Check alarm configuration
- [ ] Review evaluation periods
- [ ] Test with higher load
- [ ] Check SNS topic configuration

### If Costs Are High
- [ ] Review running resources
- [ ] Check NAT Gateway usage
- [ ] Verify task count
- [ ] Review log retention
- [ ] Consider single AZ deployment

## Success Criteria

### Deployment Successful When:
- [ ] All Terraform resources created
- [ ] ECS tasks running and healthy
- [ ] Application accessible via ALB
- [ ] Health checks passing
- [ ] Logs appearing in CloudWatch
- [ ] Alarms configured and OK
- [ ] DevOps Agent configured
- [ ] Test scenarios working
- [ ] No errors in logs
- [ ] Costs within budget

## Notes

**Deployment Date**: _______________

**Deployed By**: _______________

**AWS Account**: _______________

**Region**: _______________

**ALB URL**: _______________

**Issues Encountered**: 
_______________________________________________
_______________________________________________
_______________________________________________

**Custom Configurations**:
_______________________________________________
_______________________________________________
_______________________________________________

**Next Steps**:
_______________________________________________
_______________________________________________
_______________________________________________

---

**Tip**: Print this checklist and check off items as you complete them!
