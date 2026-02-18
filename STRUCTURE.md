# Project Structure

Visual representation of the complete project structure with descriptions.

```
aws-devops-agent-demo/
│
├── 📄 README.md                          # Project overview and quick reference
├── 📄 QUICKSTART.md                      # 5-step quick start guide ⭐
├── 📄 PROJECT_SUMMARY.md                 # Comprehensive project summary
├── 📄 DEPLOYMENT_CHECKLIST.md            # Step-by-step deployment checklist
├── 📄 INDEX.md                           # Navigation guide for all files
├── 📄 STRUCTURE.md                       # This file - project structure
├── 📄 LICENSE                            # MIT License
├── 📄 Makefile                           # Convenient command shortcuts
├── 📄 .gitignore                         # Git ignore patterns
│
├── 📁 app/                               # Application code
│   ├── 📁 src/
│   │   └── 📄 index.js                  # Express.js application
│   │                                     # - RESTful API endpoints
│   │                                     # - Prometheus metrics
│   │                                     # - Error testing endpoints
│   │                                     # - Health checks
│   │
│   ├── 📄 package.json                   # Node.js dependencies
│   ├── 📄 Dockerfile                     # Container definition
│   └── 📄 .dockerignore                  # Docker ignore patterns
│
├── 📁 terraform/                         # Infrastructure as Code
│   ├── 📄 main.tf                       # Provider configuration
│   │                                     # - AWS provider setup
│   │                                     # - Default tags
│   │
│   ├── 📄 variables.tf                  # Input variables
│   │                                     # - AWS region
│   │                                     # - Project configuration
│   │                                     # - Resource sizing
│   │
│   ├── 📄 outputs.tf                    # Output values
│   │                                     # - VPC ID
│   │                                     # - ALB URL
│   │                                     # - ECS cluster/service names
│   │                                     # - ECR repository URL
│   │
│   ├── 📄 vpc.tf                        # Network resources
│   │                                     # - VPC with DNS support
│   │                                     # - Public/private subnets (2 AZs)
│   │                                     # - Internet Gateway
│   │                                     # - NAT Gateways
│   │                                     # - Route tables
│   │                                     # - Security groups
│   │
│   ├── 📄 ecs.tf                        # ECS resources
│   │                                     # - ECS cluster with Container Insights
│   │                                     # - Task definition (Fargate)
│   │                                     # - ECS service with auto-scaling
│   │                                     # - IAM roles (execution & task)
│   │
│   ├── 📄 alb.tf                        # Load balancer
│   │                                     # - Application Load Balancer
│   │                                     # - Target group with health checks
│   │                                     # - HTTP listener
│   │
│   ├── 📄 ecr.tf                        # Container registry
│   │                                     # - ECR repository
│   │                                     # - Image scanning
│   │                                     # - Lifecycle policy
│   │
│   ├── 📄 cloudwatch.tf                 # Monitoring
│   │                                     # - Log groups
│   │                                     # - Metric alarms (CPU, memory, 5XX, health)
│   │                                     # - SNS topic for alerts
│   │                                     # - CloudWatch dashboard
│   │                                     # - Log metric filters
│   │
│   ├── 📄 devops-agent.tf               # DevOps Agent setup
│   │                                     # - IAM role for DevOps Agent
│   │                                     # - Permissions for ECS, CloudWatch, ECR
│   │                                     # - SSM parameter for configuration
│   │
│   └── 📄 terraform.tfvars.example      # Configuration template
│                                         # - Copy to terraform.tfvars
│                                         # - Customize for your environment
│
├── 📁 .github/                           # GitHub-specific files
│   └── 📁 workflows/                     # GitHub Actions workflows
│       ├── 📄 deploy.yml                # Application deployment
│       │                                 # - Build Docker image
│       │                                 # - Push to ECR
│       │                                 # - Deploy to ECS
│       │                                 # - Record deployment metadata
│       │
│       └── 📄 terraform.yml             # Infrastructure deployment
│                                         # - Terraform format check
│                                         # - Terraform plan (on PR)
│                                         # - Terraform apply (on main)
│
├── 📁 scripts/                           # Helper scripts
│   ├── 📄 setup-agent-space.sh          # Configure DevOps Agent Space
│   │                                     # - Retrieve infrastructure info
│   │                                     # - Create Agent Space config
│   │                                     # - Store in SSM Parameter Store
│   │
│   ├── 📄 trigger-incidents.sh          # Trigger incident scenarios (Bash)
│   │                                     # - error-spike: Multiple 500 errors
│   │                                     # - memory-leak: Memory exhaustion
│   │                                     # - cpu-spike: CPU saturation
│   │                                     # - health-failure: Failed health checks
│   │                                     # - timeout: Slow responses
│   │                                     # - status: Show current status
│   │                                     # - cleanup: Restore healthy state
│   │
│   ├── 📄 trigger-incidents.ps1         # Trigger incidents (PowerShell)
│   │                                     # - Same scenarios as .sh version
│   │                                     # - For Windows users
│   │
│   └── 📄 validate-setup.sh             # Validate deployment
│                                         # - Check prerequisites
│                                         # - Verify AWS credentials
│                                         # - Check Terraform state
│                                         # - Validate AWS resources
│                                         # - Check CloudWatch setup
│
└── 📁 docs/                              # Detailed documentation
    ├── 📄 SETUP.md                      # Detailed setup guide
    │                                     # - Prerequisites
    │                                     # - Step-by-step instructions
    │                                     # - Troubleshooting
    │                                     # - Cleanup procedures
    │
    ├── 📄 TESTING.md                    # Testing guide
    │                                     # - All incident scenarios
    │                                     # - Monitoring investigations
    │                                     # - DevOps Agent features
    │                                     # - Advanced testing
    │
    ├── 📄 ARCHITECTURE.md               # Architecture documentation
    │                                     # - High-level architecture
    │                                     # - Component details
    │                                     # - Data flow diagrams
    │                                     # - Security architecture
    │                                     # - Scalability considerations
    │
    ├── 📄 ENDPOINTS.md                  # API endpoints reference
    │                                     # - Standard endpoints (/, /health, /metrics)
    │                                     # - Error testing endpoints
    │                                     # - Request/response examples
    │                                     # - Testing examples
    │
    └── 📄 FAQ.md                        # Frequently asked questions
                                          # - General questions
                                          # - Prerequisites
                                          # - Deployment
                                          # - Application
                                          # - Monitoring
                                          # - DevOps Agent
                                          # - Testing
                                          # - Troubleshooting
```

## File Categories

### 📘 Documentation (Root Level)
Essential reading materials at the project root for quick access.

### 📗 Documentation (docs/)
Detailed guides and references for in-depth understanding.

### 🏗️ Infrastructure (terraform/)
Terraform modules defining all AWS resources.

### 💻 Application (app/)
Node.js application with Express.js and error testing endpoints.

### 🔄 CI/CD (.github/)
GitHub Actions workflows for automated deployment.

### 🛠️ Scripts (scripts/)
Helper scripts for setup, testing, and validation.

## Key Files by Purpose

### Getting Started
1. **QUICKSTART.md** - Start here for rapid deployment
2. **README.md** - Project overview
3. **DEPLOYMENT_CHECKLIST.md** - Systematic deployment guide

### Development
1. **app/src/index.js** - Application code
2. **app/Dockerfile** - Container definition
3. **Makefile** - Development commands

### Infrastructure
1. **terraform/main.tf** - Entry point
2. **terraform/ecs.tf** - Core compute resources
3. **terraform/cloudwatch.tf** - Monitoring setup

### Operations
1. **scripts/trigger-incidents.sh** - Testing tool
2. **scripts/validate-setup.sh** - Validation tool
3. **docs/TESTING.md** - Testing procedures

### Reference
1. **docs/ARCHITECTURE.md** - System design
2. **docs/ENDPOINTS.md** - API reference
3. **docs/FAQ.md** - Common questions

## File Sizes (Approximate)

```
Documentation:
  README.md                    ~5 KB
  QUICKSTART.md               ~4 KB
  PROJECT_SUMMARY.md          ~12 KB
  docs/SETUP.md               ~15 KB
  docs/TESTING.md             ~18 KB
  docs/ARCHITECTURE.md        ~20 KB
  docs/ENDPOINTS.md           ~15 KB
  docs/FAQ.md                 ~12 KB

Infrastructure:
  terraform/*.tf              ~25 KB total
  
Application:
  app/src/index.js            ~8 KB
  
Scripts:
  scripts/*.sh                ~10 KB total
  
Total Documentation:         ~100 KB
Total Code:                  ~45 KB
```

## Lines of Code (Approximate)

```
Infrastructure (Terraform):   ~800 lines
Application (JavaScript):     ~250 lines
Scripts (Bash/PowerShell):    ~400 lines
Documentation (Markdown):     ~3000 lines
CI/CD (YAML):                 ~150 lines
───────────────────────────────────────
Total:                        ~4600 lines
```

## Resource Count

### AWS Resources Created
- **Networking**: 1 VPC, 4 subnets, 2 NAT gateways, 1 IGW, 4 route tables, 2 security groups
- **Compute**: 1 ECS cluster, 1 ECS service, 1 task definition, 2 tasks
- **Load Balancing**: 1 ALB, 1 target group, 1 listener
- **Storage**: 1 ECR repository
- **Monitoring**: 1 log group, 5 alarms, 1 dashboard, 1 SNS topic, 1 metric filter
- **IAM**: 3 roles, 3 policies
- **SSM**: 1 parameter

**Total**: ~40 AWS resources

## Dependencies

### Application Dependencies
```json
{
  "express": "^4.18.2",
  "prom-client": "^15.1.0"
}
```

### Development Tools Required
- AWS CLI v2.x
- Terraform v1.0+
- Docker v20.x+
- Git
- Node.js 18+ (optional)
- jq (optional)

## File Relationships

```
Deployment Flow:
  terraform/*.tf → AWS Resources
  app/Dockerfile → ECR Image
  ECR Image → ECS Tasks
  ECS Tasks → ALB → Users

Testing Flow:
  scripts/trigger-incidents.* → Application Endpoints
  Application → CloudWatch Logs
  CloudWatch Logs → Alarms
  Alarms → DevOps Agent

Documentation Flow:
  QUICKSTART.md → docs/SETUP.md → docs/TESTING.md
  README.md → PROJECT_SUMMARY.md → docs/ARCHITECTURE.md
```

## Modification Frequency

### Frequently Modified
- `terraform/terraform.tfvars` - Configuration changes
- `app/src/index.js` - Application updates
- `docs/TESTING.md` - New test scenarios

### Occasionally Modified
- `terraform/*.tf` - Infrastructure changes
- `.github/workflows/*.yml` - CI/CD updates
- `scripts/*.sh` - Script improvements

### Rarely Modified
- `README.md` - Major updates only
- `docs/ARCHITECTURE.md` - Architectural changes
- `LICENSE` - Never (unless changing license)

## Navigation Tips

1. **Start with INDEX.md** for a complete navigation guide
2. **Use QUICKSTART.md** for rapid deployment
3. **Reference docs/** for detailed information
4. **Check FAQ.md** for common questions
5. **Use Makefile** for convenient commands

## File Naming Conventions

- **UPPERCASE.md** - Important root documentation
- **lowercase.md** - Supporting documentation
- **kebab-case.sh** - Shell scripts
- **kebab-case.tf** - Terraform modules
- **camelCase.js** - JavaScript files

---

**Need help finding something?** Check [INDEX.md](INDEX.md) for a complete navigation guide!
