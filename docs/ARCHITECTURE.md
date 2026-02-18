# Architecture Documentation

## Overview

This document describes the architecture of the AWS DevOps Agent demo project, including infrastructure components, data flow, and integration points.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                        │
│                                                                  │
│  ┌──────────────┐         ┌──────────────┐                     │
│  │ Application  │         │   GitHub     │                     │
│  │    Code      │────────▶│   Actions    │                     │
│  └──────────────┘         └──────┬───────┘                     │
└─────────────────────────────────┼─────────────────────────────┘
                                   │
                                   │ CI/CD Pipeline
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Amazon ECR                                │
│                   (Container Registry)                           │
└─────────────────────────────────┬───────────────────────────────┘
                                   │
                                   │ Pull Image
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                         AWS VPC                                  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              Public Subnets (2 AZs)                     │    │
│  │                                                          │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │     Application Load Balancer (ALB)              │  │    │
│  │  │  - Health Checks                                  │  │    │
│  │  │  - Traffic Distribution                           │  │    │
│  │  └────────────────────┬─────────────────────────────┘  │    │
│  └───────────────────────┼────────────────────────────────┘    │
│                          │                                       │
│  ┌───────────────────────┼────────────────────────────────┐    │
│  │              Private Subnets (2 AZs)                    │    │
│  │                      │                                  │    │
│  │  ┌───────────────────▼──────────────────────────────┐  │    │
│  │  │         ECS Fargate Cluster                       │  │    │
│  │  │                                                    │  │    │
│  │  │  ┌──────────────┐      ┌──────────────┐         │  │    │
│  │  │  │   Task 1     │      │   Task 2     │         │  │    │
│  │  │  │  (Container) │      │  (Container) │         │  │    │
│  │  │  └──────┬───────┘      └──────┬───────┘         │  │    │
│  │  └─────────┼─────────────────────┼──────────────────┘  │    │
│  └────────────┼─────────────────────┼─────────────────────┘    │
└───────────────┼─────────────────────┼──────────────────────────┘
                │                     │
                │ Logs & Metrics      │
                ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Amazon CloudWatch                             │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  Log Groups  │  │   Metrics    │  │    Alarms    │         │
│  └──────────────┘  └──────────────┘  └──────┬───────┘         │
└─────────────────────────────────────────────┼──────────────────┘
                                               │
                                               │ Triggers
                                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS DevOps Agent                              │
│                                                                  │
│  - Automatic Investigation Creation                             │
│  - Log Analysis                                                 │
│  - Code Correlation                                             │
│  - Container Introspection                                      │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Application Layer

#### Node.js Application
- **Framework**: Express.js
- **Port**: 3000
- **Features**:
  - RESTful API endpoints
  - Prometheus metrics
  - Structured JSON logging
  - Health check endpoint
  - Intentional error endpoints

#### Container Specifications
- **Base Image**: node:18-alpine
- **CPU**: 256 units (0.25 vCPU)
- **Memory**: 512 MB
- **Health Check**: HTTP GET /health every 30s

### 2. Network Layer

#### VPC Configuration
- **CIDR**: 10.0.0.0/16
- **Availability Zones**: 2 (us-east-1a, us-east-1b)
- **Subnets**:
  - Public: 10.0.0.0/24, 10.0.1.0/24
  - Private: 10.0.10.0/24, 10.0.11.0/24

#### Security Groups

**ALB Security Group**:
```
Inbound:
  - Port 80 (HTTP) from 0.0.0.0/0
Outbound:
  - All traffic
```

**ECS Tasks Security Group**:
```
Inbound:
  - Port 3000 from ALB Security Group
Outbound:
  - All traffic
```

#### Load Balancer
- **Type**: Application Load Balancer
- **Scheme**: Internet-facing
- **Target Type**: IP (for Fargate)
- **Health Check**:
  - Path: /health
  - Interval: 30s
  - Timeout: 5s
  - Healthy threshold: 2
  - Unhealthy threshold: 3

### 3. Compute Layer

#### ECS Cluster
- **Launch Type**: Fargate
- **Capacity Providers**: FARGATE, FARGATE_SPOT
- **Container Insights**: Enabled

#### ECS Service
- **Desired Count**: 2 tasks
- **Deployment**:
  - Maximum: 200%
  - Minimum healthy: 100%
  - Circuit breaker: Enabled with rollback
- **Network Mode**: awsvpc
- **Execute Command**: Enabled

#### Task Definition
```json
{
  "family": "devops-agent-demo-dev-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::...:role/...",
  "taskRoleArn": "arn:aws:iam::...:role/...",
  "containerDefinitions": [
    {
      "name": "app",
      "image": "...",
      "portMappings": [{"containerPort": 3000}],
      "logConfiguration": {...},
      "healthCheck": {...}
    }
  ]
}
```

### 4. Monitoring Layer

#### CloudWatch Log Groups
- **Name**: /ecs/devops-agent-demo-dev
- **Retention**: 7 days
- **Log Format**: JSON structured logs

#### CloudWatch Metrics

**ECS Metrics**:
- CPUUtilization
- MemoryUtilization
- RunningTaskCount

**ALB Metrics**:
- TargetResponseTime
- RequestCount
- HTTPCode_Target_2XX_Count
- HTTPCode_Target_4XX_Count
- HTTPCode_Target_5XX_Count
- HealthyHostCount
- UnHealthyHostCount

**Custom Metrics**:
- ErrorCount (from log metric filter)

#### CloudWatch Alarms

| Alarm Name | Metric | Threshold | Evaluation Periods |
|------------|--------|-----------|-------------------|
| cpu-high | CPUUtilization | > 80% | 2 |
| memory-high | MemoryUtilization | > 80% | 2 |
| unhealthy-targets | UnHealthyHostCount | > 0 | 2 |
| high-5xx-errors | HTTPCode_Target_5XX_Count | > 10 | 2 |
| error-count-high | ErrorCount | > 10 | 1 |

### 5. CI/CD Pipeline

#### GitHub Actions Workflows

**Deploy Workflow** (`.github/workflows/deploy.yml`):
1. Checkout code
2. Configure AWS credentials
3. Login to ECR
4. Build Docker image
5. Push to ECR
6. Update ECS task definition
7. Deploy to ECS
8. Record deployment metadata

**Terraform Workflow** (`.github/workflows/terraform.yml`):
1. Checkout code
2. Setup Terraform
3. Format check
4. Initialize
5. Validate
6. Plan (on PR)
7. Apply (on main branch)

### 6. DevOps Agent Integration

#### Agent Space Configuration
```json
{
  "name": "devops-agent-demo-dev",
  "resources": {
    "ecsCluster": "devops-agent-demo-dev-cluster",
    "ecsService": "devops-agent-demo-dev-service",
    "cloudWatchLogGroup": "/ecs/devops-agent-demo-dev"
  },
  "integrations": {
    "cloudWatch": {
      "enabled": true,
      "logGroup": "/ecs/devops-agent-demo-dev"
    },
    "github": {
      "enabled": true,
      "correlateDeployments": true
    }
  }
}
```

#### IAM Permissions

**DevOps Agent Role**:
- ECS: Describe clusters, services, tasks
- CloudWatch: Get logs, metrics, alarms
- ELB: Describe load balancers, target groups
- EC2: Describe network resources
- ECR: Describe repositories, images

## Data Flow

### 1. Request Flow

```
User Request
    ↓
Internet Gateway
    ↓
Application Load Balancer (Public Subnet)
    ↓
Target Group Health Check
    ↓
ECS Task (Private Subnet)
    ↓
Container Application
    ↓
Response
```

### 2. Logging Flow

```
Application Log
    ↓
STDOUT/STDERR
    ↓
awslogs Driver
    ↓
CloudWatch Log Group
    ↓
Log Metric Filter
    ↓
CloudWatch Metric
    ↓
CloudWatch Alarm (if threshold exceeded)
    ↓
SNS Topic
    ↓
DevOps Agent Investigation
```

### 3. Deployment Flow

```
Git Push
    ↓
GitHub Actions Trigger
    ↓
Build Docker Image
    ↓
Push to ECR
    ↓
Update Task Definition
    ↓
ECS Rolling Deployment
    ↓
Health Check Validation
    ↓
Record Deployment Metadata (SSM)
    ↓
DevOps Agent Correlation
```

### 4. Investigation Flow

```
CloudWatch Alarm Triggered
    ↓
DevOps Agent Notified
    ↓
Create Investigation
    ↓
Gather Context:
  - Recent deployments
  - Log analysis
  - Metric trends
  - Task status
    ↓
Correlate with GitHub:
  - Recent commits
  - Code changes
  - Deployment history
    ↓
Generate Investigation Report
```

## Scalability Considerations

### Horizontal Scaling
- ECS Service Auto Scaling based on CPU/Memory
- ALB distributes traffic across tasks
- Multi-AZ deployment for high availability

### Vertical Scaling
- Adjust task CPU/Memory in task definition
- Update container resource limits

### Cost Optimization
- Use Fargate Spot for non-critical workloads
- Reduce NAT Gateway count for dev environments
- Implement log retention policies
- Use ECR lifecycle policies

## Security Architecture

### Network Security
- Private subnets for ECS tasks
- Security groups with least privilege
- NAT Gateways for outbound internet access

### IAM Security
- Separate execution and task roles
- Principle of least privilege
- No hardcoded credentials

### Container Security
- Non-root user in container
- ECR image scanning enabled
- Minimal base image (Alpine)

### Secrets Management
- GitHub Secrets for CI/CD credentials
- SSM Parameter Store for configuration
- No secrets in code or logs

## Disaster Recovery

### Backup Strategy
- Infrastructure as Code (Terraform state)
- Container images in ECR
- CloudWatch logs retention

### Recovery Procedures
1. Redeploy infrastructure with Terraform
2. Pull latest image from ECR
3. Update ECS service
4. Verify health checks

### RTO/RPO
- **RTO**: ~15 minutes (infrastructure + deployment)
- **RPO**: Near-zero (stateless application)

## Monitoring and Alerting

### Key Metrics
- Application availability (target health)
- Response time (p50, p95, p99)
- Error rate (5XX errors)
- Resource utilization (CPU, memory)
- Request throughput

### Alert Routing
```
CloudWatch Alarm
    ↓
SNS Topic
    ↓
├─ Email (optional)
├─ DevOps Agent
└─ PagerDuty/Opsgenie (optional)
```

## Future Enhancements

1. **Multi-Region Deployment**
   - Route53 for DNS
   - Cross-region replication
   - Global load balancing

2. **Enhanced Monitoring**
   - X-Ray tracing
   - Custom business metrics
   - Real User Monitoring (RUM)

3. **Advanced Security**
   - WAF integration
   - Secrets Manager for sensitive data
   - VPC endpoints for AWS services

4. **Database Integration**
   - RDS or DynamoDB
   - Connection pooling
   - Read replicas

5. **Caching Layer**
   - ElastiCache (Redis)
   - CloudFront CDN
   - Application-level caching
