# AWS DevOps Agent - Specific Usage in This Project

## What is AWS DevOps Agent?

AWS DevOps Agent is an AI-powered service that automatically investigates operational issues in your AWS environment. It acts as an intelligent assistant that:
- Detects anomalies and incidents
- Analyzes logs and metrics
- Correlates issues with code changes
- Provides root cause analysis
- Suggests remediation steps

## How We Use It in This Project

### 1. **Automatic Incident Investigation**

**Purpose**: When something goes wrong, DevOps Agent automatically investigates without manual intervention.

**How it works in our project**:
```
CloudWatch Alarm Triggers
    ↓
DevOps Agent Receives Alert
    ↓
Agent Automatically:
  - Gathers relevant logs from CloudWatch
  - Analyzes ECS task states
  - Checks recent deployments
  - Correlates with GitHub commits
  - Identifies patterns
    ↓
Creates Investigation Report
```

**Example Scenario**:
```bash
# You trigger an error spike
make test-error-spike

# What happens:
1. Application generates 20x 500 errors
2. CloudWatch alarm "high-5xx-errors" triggers
3. DevOps Agent receives alarm notification
4. Agent creates investigation automatically
5. Agent analyzes:
   - Error logs in CloudWatch
   - Recent ECS deployments
   - GitHub commits in last 24 hours
   - Container health status
6. Agent provides findings:
   - "Error spike detected at 14:23 UTC"
   - "Correlates with deployment at 14:15 UTC"
   - "Commit abc123 introduced changes to error handling"
   - "Recommendation: Review recent code changes"
```

### 2. **Log Analysis and Pattern Detection**

**Purpose**: Automatically search and analyze CloudWatch logs to find error patterns.

**How it works**:
- DevOps Agent has access to CloudWatch Logs (via IAM role)
- When alarm triggers, it searches logs for:
  - Error messages
  - Exception stack traces
  - Unusual patterns
  - Frequency of errors

**Example**:
```json
// Agent finds this in logs:
{
  "level": "ERROR",
  "message": "Intentional 500 error triggered",
  "timestamp": "2024-01-15T14:23:45.123Z",
  "stack": "Error: Something went wrong..."
}

// Agent analysis:
"Found 20 ERROR level logs in 2-minute window
Pattern: All errors from /error/500 endpoint
Frequency: 10 errors/minute (baseline: 0.1/minute)
Conclusion: Intentional error endpoint being called repeatedly"
```

### 3. **Code Correlation with GitHub**

**Purpose**: Link incidents to specific code changes and deployments.

**How it works**:
- GitHub Actions records deployment metadata in SSM Parameter Store
- DevOps Agent reads this metadata
- Agent correlates incidents with recent deployments

**Configuration in our project**:
```yaml
# In .github/workflows/deploy.yml
- name: Record deployment metadata
  run: |
    aws ssm put-parameter \
      --name "/devops-agent-demo/deployments/latest" \
      --value '{
        "timestamp": "2024-01-15T14:15:00Z",
        "commit": "abc123def456",
        "message": "Fix error handling",
        "author": "developer@example.com",
        "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/app:abc123"
      }'
```

**Agent correlation**:
```
Incident at 14:23 UTC
    ↓
Agent checks recent deployments
    ↓
Finds deployment at 14:15 UTC (8 minutes before)
    ↓
Links to GitHub commit abc123
    ↓
Shows code changes in investigation
    ↓
"Incident occurred 8 minutes after deployment
Commit: abc123 - 'Fix error handling'
Files changed: src/index.js (error handling logic)
Recommendation: Review recent changes to error handling"
```

### 4. **Container Introspection**

**Purpose**: Analyze ECS task states and container configurations.

**How it works**:
- DevOps Agent has ECS permissions (via IAM role)
- Agent can describe tasks, services, and task definitions
- Agent checks for configuration issues

**What Agent checks**:
```bash
# ECS Task State
- Task status (RUNNING, STOPPED, FAILED)
- Container exit codes
- Health check results
- Resource utilization (CPU, memory)

# Task Definition
- Container image version
- Environment variables
- Resource limits
- Health check configuration

# Service Configuration
- Desired vs running task count
- Deployment status
- Load balancer health
```

**Example Investigation**:
```
Agent finds:
- Service desired count: 2
- Service running count: 1
- Task stopped reason: "Essential container exited"
- Container exit code: 137 (OOM killed)
- Memory limit: 512MB
- Memory usage at exit: 510MB

Agent conclusion:
"Container was killed due to memory exhaustion
Memory usage reached 99.6% of limit
Recommendation: Increase memory limit or investigate memory leak"
```

### 5. **Deployment Tracking**

**Purpose**: Track all deployments and their impact on system health.

**How it works**:
- Every deployment is recorded with metadata
- Agent maintains deployment timeline
- Agent correlates incidents with deployments

**Deployment timeline**:
```
14:00 - Deployment started (commit abc123)
14:05 - New tasks launched
14:10 - Health checks passing
14:15 - Deployment complete
14:23 - Error spike detected ← Agent correlates this
14:30 - Memory alarm triggered ← Agent links to same deployment
```

**Agent insight**:
```
"Multiple incidents detected after deployment at 14:15
- Error spike at 14:23 (8 min after)
- Memory alarm at 14:30 (15 min after)
Pattern suggests deployment introduced issues
Recommendation: Consider rollback to previous version"
```

## Specific Use Cases in This Project

### Use Case 1: Error Spike Investigation

**Trigger**: `make test-error-spike`

**What happens**:
1. Script sends 20 requests to `/error/500`
2. CloudWatch alarm `high-5xx-errors` triggers
3. DevOps Agent investigation starts

**Agent investigates**:
- ✓ Searches logs for error patterns
- ✓ Identifies `/error/500` endpoint
- ✓ Checks if this is a new pattern
- ✓ Reviews recent deployments
- ✓ Checks ECS task health

**Agent provides**:
```
Investigation Summary:
- Issue: High 5XX error rate (20 errors in 2 minutes)
- Source: /error/500 endpoint
- Pattern: Intentional error endpoint
- Impact: No actual service degradation
- Root Cause: Testing scenario, not production issue
- Action: No action needed (test scenario)
```

### Use Case 2: Memory Leak Detection

**Trigger**: `make test-memory-leak`

**What happens**:
1. Script calls `/error/memory-leak` 5 times
2. Memory usage increases to 80%+
3. CloudWatch alarm `memory-high` triggers
4. DevOps Agent investigation starts

**Agent investigates**:
- ✓ Checks ECS task memory metrics
- ✓ Analyzes memory usage trend
- ✓ Searches logs for memory-related messages
- ✓ Reviews task definition memory limits
- ✓ Checks for recent code changes

**Agent provides**:
```
Investigation Summary:
- Issue: Memory utilization at 85% (threshold: 80%)
- Trend: Rapid increase from 30% to 85% in 5 minutes
- Pattern: Memory not being released
- Logs: Found "Memory leak triggered" messages
- Root Cause: Intentional memory leak for testing
- Recommendation: In production, investigate memory leaks
  and consider increasing memory limit or fixing leak
```

### Use Case 3: Container Health Failure

**Trigger**: `make test-health-failure`

**What happens**:
1. Script calls `/error/disable-health`
2. Health checks start failing
3. ALB marks targets as unhealthy
4. CloudWatch alarm `unhealthy-targets` triggers
5. DevOps Agent investigation starts

**Agent investigates**:
- ✓ Checks ALB target health
- ✓ Reviews ECS task status
- ✓ Analyzes health check logs
- ✓ Checks recent deployments
- ✓ Reviews task definition health check config

**Agent provides**:
```
Investigation Summary:
- Issue: All targets unhealthy (0/2 healthy)
- Health Check: Returning 503 Service Unavailable
- Timeline: Health checks started failing at 15:30
- Pattern: Sudden failure, not gradual degradation
- Logs: Found "Health check disabled" message
- Root Cause: Health endpoint intentionally disabled
- Impact: ALB stopped routing traffic to targets
- Recommendation: In production, investigate why health
  endpoint is failing and restore service
```

### Use Case 4: Deployment Correlation

**Trigger**: Deploy new code, then trigger incident

**What happens**:
1. GitHub Actions deploys new version
2. Deployment metadata recorded
3. Later, incident occurs
4. DevOps Agent correlates incident with deployment

**Agent investigates**:
- ✓ Checks deployment timeline
- ✓ Identifies recent deployment
- ✓ Reviews GitHub commit details
- ✓ Analyzes code changes
- ✓ Correlates timing

**Agent provides**:
```
Investigation Summary:
- Issue: Error spike detected at 16:45
- Recent Deployment: 16:30 (15 minutes before incident)
- Commit: abc123 - "Update error handling logic"
- Files Changed: src/index.js (error handling)
- Correlation: High confidence (timing + code changes)
- Pattern: Errors started immediately after deployment
- Recommendation: Review commit abc123, consider rollback
- Rollback Command: aws ecs update-service --task-definition previous-version
```

## IAM Permissions for DevOps Agent

**What we configured** (in `terraform/devops-agent.tf`):

```hcl
# ECS Permissions - To inspect containers
- ecs:DescribeClusters
- ecs:DescribeServices
- ecs:DescribeTasks
- ecs:DescribeTaskDefinition
- ecs:ListTasks

# CloudWatch Logs - To analyze logs
- logs:GetLogEvents
- logs:FilterLogEvents
- logs:DescribeLogStreams

# CloudWatch Metrics - To analyze metrics
- cloudwatch:GetMetricData
- cloudwatch:GetMetricStatistics
- cloudwatch:DescribeAlarms

# Load Balancer - To check health
- elasticloadbalancing:DescribeTargetHealth
- elasticloadbalancing:DescribeLoadBalancers

# ECR - To check container images
- ecr:DescribeImages
- ecr:DescribeRepositories
```

## Agent Space Configuration

**What is an Agent Space?**
An Agent Space is a logical grouping of resources that DevOps Agent monitors.

**Our configuration** (in `scripts/setup-agent-space.sh`):

```json
{
  "name": "devops-agent-demo-dev",
  "description": "DevOps Agent space for demo ECS application",
  "resources": {
    "ecsCluster": "devops-agent-demo-dev-cluster",
    "ecsService": "devops-agent-demo-dev-service",
    "cloudWatchLogGroup": "/ecs/devops-agent-demo-dev",
    "loadBalancer": "devops-agent-demo-dev-alb"
  },
  "integrations": {
    "cloudWatch": {
      "enabled": true,
      "logGroup": "/ecs/devops-agent-demo-dev",
      "alarms": [
        "cpu-high",
        "memory-high",
        "unhealthy-targets",
        "high-5xx-errors",
        "error-count-high"
      ]
    },
    "github": {
      "enabled": true,
      "repository": "your-username/your-repo",
      "correlateDeployments": true
    }
  },
  "investigation": {
    "autoCreate": true,
    "triggers": ["alarm", "deployment", "error-spike"]
  }
}
```

## How to Access DevOps Agent Investigations

### 1. AWS Console
```
1. Open AWS Console
2. Navigate to "DevOps Agent" service
3. Click "Agent Spaces"
4. Select "devops-agent-demo-dev"
5. View "Investigations" tab
6. Click on any investigation to see details
```

### 2. AWS CLI
```bash
# List investigations
aws devops-agent list-investigations \
  --agent-space-name devops-agent-demo-dev

# Get investigation details
aws devops-agent get-investigation \
  --investigation-id <investigation-id>
```

## What You'll See in an Investigation

### Investigation Dashboard
```
Investigation ID: inv-abc123
Status: Active
Created: 2024-01-15 14:23:45 UTC
Trigger: CloudWatch Alarm (high-5xx-errors)

Timeline:
├─ 14:15 - Deployment completed (commit abc123)
├─ 14:23 - Error spike detected (20 errors)
├─ 14:23 - Investigation started
├─ 14:24 - Log analysis completed
├─ 14:24 - Code correlation completed
└─ 14:25 - Investigation completed

Findings:
1. Error Spike Pattern
   - 20 errors in 2-minute window
   - All from /error/500 endpoint
   - Baseline: 0.1 errors/minute
   - Spike: 10 errors/minute

2. Code Correlation
   - Recent deployment: 8 minutes before incident
   - Commit: abc123 - "Fix error handling"
   - Files changed: src/index.js

3. Container Health
   - All tasks running normally
   - No container restarts
   - Memory: 45% (normal)
   - CPU: 12% (normal)

4. Log Analysis
   - Found "Intentional 500 error triggered" messages
   - Pattern suggests testing scenario
   - No actual application errors

Recommendation:
This appears to be a testing scenario rather than a
production issue. The error endpoint is being called
intentionally. No action required.

Related Resources:
- ECS Service: devops-agent-demo-dev-service
- CloudWatch Logs: /ecs/devops-agent-demo-dev
- GitHub Commit: abc123
- Alarm: high-5xx-errors
```

## Real-World Benefits

### Without DevOps Agent:
```
1. Alarm triggers at 2 AM
2. On-call engineer wakes up
3. Logs into AWS Console
4. Checks CloudWatch logs manually
5. Searches for error patterns
6. Checks ECS task status
7. Reviews recent deployments
8. Looks at GitHub commits
9. Correlates timing manually
10. Determines root cause
Total time: 30-60 minutes
```

### With DevOps Agent:
```
1. Alarm triggers at 2 AM
2. DevOps Agent investigates automatically
3. Engineer receives investigation report
4. Report shows:
   - Root cause identified
   - Code changes correlated
   - Recommendation provided
5. Engineer takes action based on report
Total time: 5-10 minutes
```

## Testing the DevOps Agent

### Step-by-Step Test

```bash
# 1. Deploy the project
make init && make apply && make build && make push

# 2. Setup DevOps Agent
make setup-agent

# 3. Trigger an incident
make test-error-spike

# 4. Wait 2-3 minutes for alarm to trigger

# 5. Check AWS Console
# Navigate to DevOps Agent > Agent Spaces > devops-agent-demo-dev
# You should see a new investigation

# 6. Review the investigation
# Click on the investigation to see:
# - Timeline of events
# - Log analysis
# - Code correlation
# - Recommendations

# 7. Trigger another scenario
make test-memory-leak

# 8. Compare investigations
# Notice how DevOps Agent provides different
# analysis for different types of issues
```

## Key Takeaways

### DevOps Agent in This Project:

1. **Automatic Investigation** - No manual log searching needed
2. **Code Correlation** - Links incidents to deployments and commits
3. **Pattern Detection** - Identifies anomalies and trends
4. **Root Cause Analysis** - Provides likely causes
5. **Actionable Recommendations** - Suggests next steps
6. **Time Savings** - Reduces MTTR (Mean Time To Resolution)

### What Makes It Valuable:

- **24/7 Monitoring** - Always watching, even when you're not
- **Consistent Analysis** - Same thorough investigation every time
- **Fast Response** - Starts investigating immediately
- **Context Aware** - Understands your infrastructure
- **Learning System** - Gets better over time

### This Demo Shows:

- How to configure DevOps Agent for ECS
- How to integrate with CloudWatch
- How to enable GitHub correlation
- How to trigger and view investigations
- How to interpret investigation results
- Real-world incident scenarios

## Summary

**AWS DevOps Agent in this project is used to**:

1. ✅ Automatically investigate incidents when alarms trigger
2. ✅ Analyze CloudWatch logs for error patterns
3. ✅ Correlate incidents with GitHub deployments
4. ✅ Inspect ECS container states and configurations
5. ✅ Provide root cause analysis and recommendations
6. ✅ Reduce mean time to resolution (MTTR)
7. ✅ Demonstrate AI-powered incident response

**The project provides**:
- Complete DevOps Agent setup
- IAM roles and permissions
- Agent Space configuration
- Integration with CloudWatch and GitHub
- Multiple test scenarios to trigger investigations
- Documentation on how to use and interpret results

This is a **practical, hands-on demonstration** of how DevOps Agent can automate incident response in a real ECS environment!
