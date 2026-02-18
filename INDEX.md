# Project Index

Complete guide to navigating the AWS DevOps Agent Demo project.

## 📚 Documentation

### Getting Started
- **[README.md](README.md)** - Project overview and introduction
- **[QUICKSTART.md](QUICKSTART.md)** - 5-step quick start guide (⭐ Start here!)
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Comprehensive project summary
- **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Step-by-step deployment checklist

### Detailed Guides
- **[docs/SETUP.md](docs/SETUP.md)** - Detailed setup instructions with troubleshooting
- **[docs/TESTING.md](docs/TESTING.md)** - Complete testing guide with all scenarios
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Architecture documentation and diagrams
- **[docs/DEVOPS_AGENT_USAGE.md](docs/DEVOPS_AGENT_USAGE.md)** - ⭐ How DevOps Agent is used (detailed)
- **[docs/ENDPOINTS.md](docs/ENDPOINTS.md)** - API endpoints reference
- **[docs/FAQ.md](docs/FAQ.md)** - Frequently asked questions

## 🏗️ Infrastructure Code

### Terraform Modules
- **[terraform/main.tf](terraform/main.tf)** - Provider and main configuration
- **[terraform/variables.tf](terraform/variables.tf)** - Input variables
- **[terraform/outputs.tf](terraform/outputs.tf)** - Output values
- **[terraform/vpc.tf](terraform/vpc.tf)** - VPC, subnets, security groups
- **[terraform/ecs.tf](terraform/ecs.tf)** - ECS cluster, service, task definitions
- **[terraform/alb.tf](terraform/alb.tf)** - Application Load Balancer
- **[terraform/ecr.tf](terraform/ecr.tf)** - Container registry
- **[terraform/cloudwatch.tf](terraform/cloudwatch.tf)** - Logs, metrics, alarms
- **[terraform/devops-agent.tf](terraform/devops-agent.tf)** - DevOps Agent configuration

### Configuration
- **[terraform/terraform.tfvars.example](terraform/terraform.tfvars.example)** - Configuration template

## 💻 Application Code

### Node.js Application
- **[app/src/index.js](app/src/index.js)** - Express application with error endpoints
- **[app/package.json](app/package.json)** - Dependencies and scripts
- **[app/Dockerfile](app/Dockerfile)** - Container definition
- **[app/.dockerignore](app/.dockerignore)** - Docker ignore patterns

## 🔄 CI/CD

### GitHub Actions
- **[.github/workflows/deploy.yml](.github/workflows/deploy.yml)** - Application deployment workflow
- **[.github/workflows/terraform.yml](.github/workflows/terraform.yml)** - Infrastructure deployment workflow

## 🛠️ Scripts

### Bash Scripts (Linux/Mac)
- **[scripts/setup-agent-space.sh](scripts/setup-agent-space.sh)** - Configure DevOps Agent Space
- **[scripts/trigger-incidents.sh](scripts/trigger-incidents.sh)** - Trigger incident scenarios
- **[scripts/validate-setup.sh](scripts/validate-setup.sh)** - Validate deployment

### PowerShell Scripts (Windows)
- **[scripts/trigger-incidents.ps1](scripts/trigger-incidents.ps1)** - Trigger incidents (Windows)

### Make Commands
- **[Makefile](Makefile)** - Convenient command shortcuts

## 📋 Configuration Files

- **[.gitignore](.gitignore)** - Git ignore patterns
- **[LICENSE](LICENSE)** - MIT License

## 🎯 Quick Navigation

### I want to...

#### Deploy the project
1. Read [QUICKSTART.md](QUICKSTART.md)
2. Follow [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
3. Reference [docs/SETUP.md](docs/SETUP.md) if needed

#### Test incident scenarios
1. Read [docs/TESTING.md](docs/TESTING.md)
2. Use `scripts/trigger-incidents.sh` or `scripts/trigger-incidents.ps1`
3. Check [docs/ENDPOINTS.md](docs/ENDPOINTS.md) for API reference

#### Understand the architecture
1. Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
2. Review [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
3. Examine Terraform files in `terraform/`

#### Troubleshoot issues
1. Check [docs/FAQ.md](docs/FAQ.md)
2. Review [docs/SETUP.md](docs/SETUP.md) troubleshooting section
3. Run `scripts/validate-setup.sh`

#### Customize the project
1. Modify `terraform/terraform.tfvars`
2. Edit `app/src/index.js` for application changes
3. Update Terraform files for infrastructure changes

#### Set up CI/CD
1. Review [.github/workflows/deploy.yml](.github/workflows/deploy.yml)
2. Add GitHub Secrets (see [docs/SETUP.md](docs/SETUP.md))
3. Push to trigger workflows

## 📊 Project Statistics

### Infrastructure Resources
- **~40 AWS resources** created by Terraform
- **2 Availability Zones** for high availability
- **2 ECS Tasks** running by default
- **5 CloudWatch Alarms** for monitoring

### Application Features
- **8 API endpoints** (3 standard + 5 error testing)
- **Prometheus metrics** integration
- **Structured JSON logging**
- **Health check** endpoint

### Documentation
- **9 documentation files** (~15,000 words)
- **3 helper scripts** (Bash + PowerShell)
- **2 CI/CD workflows**
- **1 Makefile** with 20+ commands

## 🔍 Search Guide

### Find by Topic

**AWS Services:**
- ECS/Fargate: `terraform/ecs.tf`, `docs/ARCHITECTURE.md`
- Load Balancer: `terraform/alb.tf`, `docs/ARCHITECTURE.md`
- CloudWatch: `terraform/cloudwatch.tf`, `docs/TESTING.md`
- VPC/Networking: `terraform/vpc.tf`, `docs/ARCHITECTURE.md`
- DevOps Agent: `terraform/devops-agent.tf`, `docs/SETUP.md`

**Operations:**
- Deployment: `QUICKSTART.md`, `docs/SETUP.md`, `.github/workflows/`
- Testing: `docs/TESTING.md`, `scripts/trigger-incidents.*`
- Monitoring: `docs/TESTING.md`, `terraform/cloudwatch.tf`
- Troubleshooting: `docs/FAQ.md`, `docs/SETUP.md`

**Development:**
- Application Code: `app/src/index.js`
- Container: `app/Dockerfile`
- API Reference: `docs/ENDPOINTS.md`
- Architecture: `docs/ARCHITECTURE.md`

## 📈 Learning Path

### Beginner
1. Read [README.md](README.md)
2. Follow [QUICKSTART.md](QUICKSTART.md)
3. Try basic commands from [Makefile](Makefile)
4. Test one scenario from [docs/TESTING.md](docs/TESTING.md)

### Intermediate
1. Study [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
2. Review Terraform code in `terraform/`
3. Understand application code in `app/`
4. Test all scenarios from [docs/TESTING.md](docs/TESTING.md)
5. Customize configuration

### Advanced
1. Modify infrastructure in `terraform/`
2. Add custom endpoints to `app/src/index.js`
3. Create custom alarms in `terraform/cloudwatch.tf`
4. Integrate with external tools
5. Implement production hardening

## 🎓 Use Cases by Role

### DevOps Engineer
- **Start:** [QUICKSTART.md](QUICKSTART.md)
- **Focus:** `terraform/`, [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Test:** All scenarios in [docs/TESTING.md](docs/TESTING.md)

### Developer
- **Start:** [README.md](README.md)
- **Focus:** `app/`, [docs/ENDPOINTS.md](docs/ENDPOINTS.md)
- **Test:** API endpoints, local development

### SRE/Operations
- **Start:** [docs/TESTING.md](docs/TESTING.md)
- **Focus:** Monitoring, alerting, incident response
- **Test:** All incident scenarios

### Manager/Architect
- **Start:** [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
- **Focus:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Review:** Cost estimates, capabilities

## 🔗 External Resources

### AWS Documentation
- [ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### Tools Documentation
- [Terraform](https://www.terraform.io/docs)
- [Docker](https://docs.docker.com/)
- [Express.js](https://expressjs.com/)
- [Prometheus](https://prometheus.io/docs/)

## 📞 Getting Help

### Self-Service
1. Check [docs/FAQ.md](docs/FAQ.md)
2. Review relevant documentation
3. Run `scripts/validate-setup.sh`
4. Check CloudWatch logs

### Community Support
1. Search GitHub Issues
2. Create new issue with details
3. Include logs and error messages

## 🚀 Quick Commands

```bash
# Get help
make help

# Deploy everything
make init && make apply && make build && make push

# Test scenarios
make test-error-spike
make test-memory-leak
make test-cpu-spike

# Monitor
make logs
make alarms
make status

# Get URL
make url

# Cleanup
make cleanup
make destroy
```

## 📝 File Naming Conventions

- **UPPERCASE.md** - Root-level documentation
- **docs/*.md** - Detailed documentation
- **terraform/*.tf** - Infrastructure code
- **app/** - Application code
- **scripts/*.sh** - Bash scripts
- **scripts/*.ps1** - PowerShell scripts
- **.github/** - GitHub-specific files

## 🎯 Next Steps

1. **New to the project?** Start with [QUICKSTART.md](QUICKSTART.md)
2. **Ready to deploy?** Follow [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
3. **Want to understand?** Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
4. **Need to test?** See [docs/TESTING.md](docs/TESTING.md)
5. **Have questions?** Check [docs/FAQ.md](docs/FAQ.md)

---

**Happy Learning! 🎉**

For the best experience, start with [QUICKSTART.md](QUICKSTART.md) and have your AWS credentials ready!
