# Testing Guide

This guide covers testing incident response scenarios with AWS DevOps Agent.

## Overview

The demo application includes several intentional error endpoints designed to trigger various incident scenarios. These scenarios help demonstrate how AWS DevOps Agent detects, investigates, and correlates issues.

## Prerequisites

- Infrastructure deployed and running
- Application accessible via ALB
- DevOps Agent Space configured
- CloudWatch alarms active

## Quick Test

```bash
# Make script executable
chmod +x scripts/trigger-incidents.sh

# Run all scenarios
./scripts/trigger-incidents.sh all
```

## Incident Scenarios

### Scenario 1: Application Error Spike

**Objective**: Trigger high 5XX error rate alarm

**Steps**:
```bash
./scripts/trigger-incidents.sh error-spike
```

**What happens**:
1. Script sends 20 requests to `/error/500` endpoint
2. Application returns 500 errors
3. CloudWatch alarm `high-5xx-errors` triggers after 2 evaluation periods
4. DevOps Agent creates investigation
5. Agent correlates errors with recent deployments

**Expected Metrics**:
- HTTPCode_Target_5XX_Count: 20+
- Error rate: 100% (during test)

**Verification**:
```bash
# Check alarm state
aws cloudwatch describe-alarms \
  --alarm-names "devops-agent-demo-dev-high-5xx-errors" \
  --query 'MetricAlarms[0].StateValue'

# View error logs
aws logs filter-log-events \
  --log-group-name /ecs/devops-agent-demo-dev \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '5 minutes ago' +%s)000
```

**DevOps Agent Investigation**:
- Identifies error spike pattern
- Searches logs for error messages
- Correlates with recent code changes
- Suggests potential root causes

### Scenario 2: Memory Leak

**Objective**: Trigger high memory utilization alarm

**Steps**:
```bash
./scripts/trigger-incidents.sh memory-leak
```

**What happens**:
1. Script calls `/error/memory-leak` endpoint 5 times
2. Each call allocates ~100MB of memory
3. Memory usage increases to 80%+
4. CloudWatch alarm `memory-high` triggers
5. DevOps Agent investigates memory patterns

**Expected Metrics**:
- MemoryUtilization: 80%+
- Container memory: 400MB+ (out of 512MB)

**Verification**:
```bash
# Check memory metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ClusterName,Value=devops-agent-demo-dev-cluster Name=ServiceName,Value=devops-agent-demo-dev-service \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average

# View memory logs
aws logs filter-log-events \
  --log-group-name /ecs/devops-agent-demo-dev \
  --filter-pattern "memory"
```

**Cleanup**:
```bash
curl $(cd terraform && terraform output -raw alb_url)/error/clear-memory
```

### Scenario 3: CPU Spike

**Objective**: Trigger high CPU utilization alarm

**Steps**:
```bash
./scripts/trigger-incidents.sh cpu-spike
```

**What happens**:
1. Script calls `/error/cpu-spike` endpoint 3 times concurrently
2. Each call performs CPU-intensive calculations for 5 seconds
3. CPU utilization spikes to 80%+
4. CloudWatch alarm `cpu-high` triggers
5. DevOps Agent analyzes CPU patterns

**Expected Metrics**:
- CPUUtilization: 80%+
- Duration: ~5 seconds per request

**Verification**:
```bash
# Check CPU metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=devops-agent-demo-dev-cluster Name=ServiceName,Value=devops-agent-demo-dev-service \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average
```

### Scenario 4: Container Health Check Failure

**Objective**: Trigger unhealthy targets alarm

**Steps**:
```bash
./scripts/trigger-incidents.sh health-failure
```

**What happens**:
1. Script calls `/error/disable-health` endpoint
2. Health check endpoint returns 503
3. ALB marks targets as unhealthy after 3 failed checks (~90 seconds)
4. CloudWatch alarm `unhealthy-targets` triggers
5. DevOps Agent investigates container health

**Expected Metrics**:
- UnHealthyHostCount: 2 (all tasks)
- HealthyHostCount: 0

**Verification**:
```bash
# Check target health
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
  --names devops-agent-demo-dev-tg \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

aws elbv2 describe-target-health \
  --target-group-arn $TARGET_GROUP_ARN
```

**Restore Health**:
```bash
curl $(cd terraform && terraform output -raw alb_url)/error/enable-health
```

### Scenario 5: Database Timeout

**Objective**: Simulate slow database queries

**Steps**:
```bash
./scripts/trigger-incidents.sh timeout
```

**What happens**:
1. Script calls `/error/timeout` endpoint
2. Request hangs for 30 seconds
3. Response time metrics increase
4. DevOps Agent detects latency spike

**Expected Metrics**:
- TargetResponseTime: 30+ seconds
- Request duration: 30000ms

**Verification**:
```bash
# Check response time
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=$(aws elbv2 describe-load-balancers --names devops-agent-demo-dev-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text | cut -d: -f6-) \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average
```

## Monitoring Investigations

### View CloudWatch Logs

```bash
# Real-time log streaming
aws logs tail /ecs/devops-agent-demo-dev --follow

# Filter for errors
aws logs filter-log-events \
  --log-group-name /ecs/devops-agent-demo-dev \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '1 hour ago' +%s)000
```

### Check Alarm States

```bash
# List all alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix "devops-agent-demo" \
  --query 'MetricAlarms[*].[AlarmName,StateValue,StateReason]' \
  --output table

# Get specific alarm history
aws cloudwatch describe-alarm-history \
  --alarm-name "devops-agent-demo-dev-high-5xx-errors" \
  --max-records 10
```

### View Metrics Dashboard

```bash
# Get dashboard URL
echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=devops-agent-demo-dev"
```

### Check ECS Service Events

```bash
aws ecs describe-services \
  --cluster devops-agent-demo-dev-cluster \
  --services devops-agent-demo-dev-service \
  --query 'services[0].events[0:10]' \
  --output table
```

## DevOps Agent Investigation Features

### 1. Automatic Investigation Creation

When an alarm triggers, DevOps Agent automatically:
- Creates an investigation
- Gathers relevant logs and metrics
- Identifies affected resources
- Correlates with recent changes

### 2. Code Correlation

DevOps Agent links incidents to:
- Recent deployments
- GitHub commits
- Code changes
- Deployment metadata

**View deployment history**:
```bash
aws ssm get-parameter \
  --name "/devops-agent-demo/deployments/latest" \
  --query 'Parameter.Value' \
  --output text | jq .
```

### 3. Container Introspection

DevOps Agent analyzes:
- Task definitions
- Container configurations
- Resource allocations
- Environment variables

**View task details**:
```bash
# List running tasks
aws ecs list-tasks \
  --cluster devops-agent-demo-dev-cluster \
  --service-name devops-agent-demo-dev-service

# Describe task
TASK_ARN=$(aws ecs list-tasks --cluster devops-agent-demo-dev-cluster --service-name devops-agent-demo-dev-service --query 'taskArns[0]' --output text)

aws ecs describe-tasks \
  --cluster devops-agent-demo-dev-cluster \
  --tasks $TASK_ARN
```

### 4. Log Analysis

DevOps Agent searches logs for:
- Error patterns
- Exception stack traces
- Performance issues
- Anomalies

**Example log queries**:
```bash
# Find all errors in last hour
aws logs filter-log-events \
  --log-group-name /ecs/devops-agent-demo-dev \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '1 hour ago' +%s)000

# Find memory-related logs
aws logs filter-log-events \
  --log-group-name /ecs/devops-agent-demo-dev \
  --filter-pattern "memory"

# Find timeout errors
aws logs filter-log-events \
  --log-group-name /ecs/devops-agent-demo-dev \
  --filter-pattern "timeout"
```

## Testing Deployment Correlation

### Trigger a Deployment

```bash
# Make a code change
echo "// Test change" >> app/src/index.js

# Commit and push
git add .
git commit -m "Test deployment correlation"
git push origin main
```

### Trigger Incident After Deployment

Wait for deployment to complete, then:
```bash
# Wait 2 minutes after deployment
sleep 120

# Trigger error spike
./scripts/trigger-incidents.sh error-spike
```

DevOps Agent should correlate the incident with the recent deployment.

## Advanced Testing

### Load Testing

```bash
# Install Apache Bench (if not installed)
# Ubuntu/Debian: apt-get install apache2-utils
# macOS: brew install httpd

ALB_URL=$(cd terraform && terraform output -raw alb_url)

# Run load test
ab -n 1000 -c 10 $ALB_URL/
```

### Chaos Engineering

```bash
# Stop a task (ECS will restart it)
TASK_ARN=$(aws ecs list-tasks --cluster devops-agent-demo-dev-cluster --service-name devops-agent-demo-dev-service --query 'taskArns[0]' --output text)

aws ecs stop-task \
  --cluster devops-agent-demo-dev-cluster \
  --task $TASK_ARN \
  --reason "Chaos engineering test"
```

### Custom Metrics

Add custom metrics to the application:

```javascript
// In app/src/index.js
const customMetric = new promClient.Counter({
  name: 'custom_business_metric',
  help: 'Custom business metric',
  registers: [register]
});

app.get('/business-event', (req, res) => {
  customMetric.inc();
  res.json({ success: true });
});
```

## Cleanup After Testing

```bash
# Restore application to healthy state
./scripts/trigger-incidents.sh cleanup

# Clear alarms
aws cloudwatch set-alarm-state \
  --alarm-name "devops-agent-demo-dev-high-5xx-errors" \
  --state-value OK \
  --state-reason "Manual reset after testing"
```

## Troubleshooting Tests

### Alarms Not Triggering

**Check alarm configuration**:
```bash
aws cloudwatch describe-alarms \
  --alarm-names "devops-agent-demo-dev-high-5xx-errors"
```

**Verify metrics are being published**:
```bash
aws cloudwatch list-metrics \
  --namespace AWS/ApplicationELB
```

### Application Not Responding

**Check task status**:
```bash
aws ecs describe-services \
  --cluster devops-agent-demo-dev-cluster \
  --services devops-agent-demo-dev-service \
  --query 'services[0].{Running:runningCount,Desired:desiredCount}'
```

**View recent logs**:
```bash
aws logs tail /ecs/devops-agent-demo-dev --since 5m
```

## Best Practices

1. **Test one scenario at a time** - Wait for alarms to clear between tests
2. **Monitor CloudWatch** - Keep dashboard open during testing
3. **Document findings** - Note investigation results for each scenario
4. **Clean up after testing** - Restore healthy state to avoid false alarms
5. **Use realistic scenarios** - Simulate actual production issues

## Next Steps

- Customize alarm thresholds based on your requirements
- Add custom metrics for business-specific monitoring
- Integrate with incident management tools (PagerDuty, Opsgenie)
- Set up automated remediation actions
- Create runbooks for common incidents
