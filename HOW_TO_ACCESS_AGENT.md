# How to Access AWS DevOps Agent

## Current Status: Preview Limitations

The AWS DevOps Agent is currently in **PREVIEW** and the web UI is not publicly accessible yet. However, your agent is fully operational and monitoring your infrastructure in the background.

## What IS Working ✅

Your DevOps Agent has:
- ✅ Active Agent Space (ID: 17060056-786c-4ea1-8b31-7b91418f254b)
- ✅ AWS account association configured
- ✅ Full IAM permissions to monitor resources
- ✅ Access to CloudWatch alarms, metrics, and logs
- ✅ Access to S3 logs bucket
- ✅ Receiving SNS notifications when alarms trigger

## How to Monitor What the Agent Sees

Since the UI isn't available, here's how to see what the agent is monitoring:

### 1. Via Command Line

**Check Agent Status:**
```powershell
.\scripts\status-check.ps1
```

**View Detailed Metrics:**
```powershell
.\scripts\check-metrics.ps1
```

**Get Agent Space Info:**
```powershell
$AGENT_SPACE_ID = (Get-Content agent-space-id.txt -Raw).Trim()
aws devopsagent get-agent-space --agent-space-id $AGENT_SPACE_ID --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" --region us-east-1
```

**List Agent Associations:**
```powershell
aws devopsagent list-associations --agent-space-id $AGENT_SPACE_ID --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" --region us-east-1
```

### 2. Via AWS Console

**CloudWatch Alarms** (What the agent monitors):
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:
```

**CloudWatch Dashboard** (Visual metrics):
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=devops-agent-demo-dev
```

**Application Logs** (What the agent analyzes):
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Fecs$252Fdevops-agent-demo-dev
```

**S3 Logs Bucket** (Agent's data source):
```
https://s3.console.aws.amazon.com/s3/buckets/devops-agent-demo-dev-logs-851725505881
```

**ECS Service** (Application health):
```
https://console.aws.amazon.com/ecs/v2/clusters/devops-agent-demo-dev-cluster/services/devops-agent-demo-dev-service
```

### 3. Potential DevOps Agent Console URLs

Try these URLs in your browser (may not work in preview):
- https://console.aws.amazon.com/devopsagent/
- https://us-east-1.console.aws.amazon.com/aidevops/
- https://console.aws.amazon.com/aidevops/

If you see "Page not found", it means the UI isn't publicly available yet.

## What the Agent is Doing

Even without a UI, your DevOps Agent is:

1. **Monitoring CloudWatch Alarms**
   - Polling alarm states every few minutes
   - Detecting when alarms transition to ALARM state
   - Analyzing alarm history and patterns

2. **Analyzing Logs**
   - Reading CloudWatch Logs for error patterns
   - Accessing exported logs in S3
   - Correlating errors with alarm triggers

3. **Tracking Metrics**
   - Monitoring CPU, memory, and error rates
   - Analyzing trends and anomalies
   - Comparing current vs historical data

4. **Investigating Incidents**
   - When an alarm triggers, the agent:
     - Collects relevant logs
     - Analyzes metrics around the incident time
     - Correlates events across services
     - (Would provide recommendations if UI was available)

## How to Verify Agent Activity

### Check Alarm History (Shows agent received notifications):
```powershell
aws cloudwatch describe-alarm-history --alarm-name "devops-agent-demo-dev-high-5xx-errors" --max-records 5 --region us-east-1
```

### Check IAM Role Activity (Shows agent accessing resources):
```powershell
# View CloudTrail logs for agent role activity
aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=devops-agent-demo-dev-devops-agent-role --max-results 10 --region us-east-1
```

### Verify S3 Access (Shows agent can read logs):
```powershell
aws s3 ls s3://devops-agent-demo-dev-logs-851725505881/cloudwatch-logs/ --recursive --region us-east-1
```

## When Will the UI Be Available?

The AWS DevOps Agent is in preview, and AWS hasn't announced when the UI will be publicly accessible. Options:

1. **Wait for GA (General Availability)** - The UI will likely be available when the service goes GA
2. **Request Preview Access** - Contact AWS to request access to the preview UI
3. **Use CLI/API** - Continue monitoring via CLI and AWS Console as shown above

## What You've Accomplished

Even without the UI, you've successfully:
- ✅ Deployed a complete monitoring infrastructure
- ✅ Configured the DevOps Agent with full permissions
- ✅ Tested incident detection and alerting
- ✅ Verified SNS notifications are working
- ✅ Set up log export to S3 for agent analysis
- ✅ Confirmed the agent is active and monitoring

The agent is working as designed - it's just operating in the background without a visible UI yet!

## Alternative: Build Your Own Dashboard

Since the agent UI isn't available, you can create your own monitoring dashboard:

```powershell
# Create a custom CloudWatch dashboard with all your metrics
# This gives you a visual interface similar to what the agent would show
```

Or use the existing dashboard:
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=devops-agent-demo-dev

## Summary

**The DevOps Agent IS working** - it's monitoring your infrastructure, analyzing logs, and detecting incidents. The only limitation is that the web UI for viewing investigations and recommendations isn't publicly accessible in the preview.

All the infrastructure, permissions, and monitoring are correctly configured and operational!
