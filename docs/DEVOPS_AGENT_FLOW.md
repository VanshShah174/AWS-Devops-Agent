# AWS DevOps Agent - Investigation Flow Diagram

## Complete Investigation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    INCIDENT OCCURS                               │
│                                                                  │
│  User triggers: make test-error-spike                           │
│  Application generates 20x 500 errors                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                 CLOUDWATCH ALARM TRIGGERS                        │
│                                                                  │
│  Alarm: high-5xx-errors                                         │
│  Threshold: > 10 errors in 2 evaluation periods                 │
│  State: OK → ALARM                                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              DEVOPS AGENT RECEIVES NOTIFICATION                  │
│                                                                  │
│  Agent Space: devops-agent-demo-dev                             │
│  Trigger: CloudWatch Alarm                                      │
│  Auto-create investigation: TRUE                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              INVESTIGATION STARTS AUTOMATICALLY                  │
│                                                                  │
│  Investigation ID: inv-abc123                                   │
│  Status: Active                                                 │
│  Created: 2024-01-15 14:23:45 UTC                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PHASE 1: DATA COLLECTION                      │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ CloudWatch Logs                                           │  │
│  │ - Fetch logs from /ecs/devops-agent-demo-dev            │  │
│  │ - Time range: Last 15 minutes                            │  │
│  │ - Filter: ERROR level logs                               │  │
│  │ - Result: 20 error messages found                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ ECS Task Information                                      │  │
│  │ - Describe cluster: devops-agent-demo-dev-cluster        │  │
│  │ - Describe service: devops-agent-demo-dev-service        │  │
│  │ - List tasks: 2 tasks running                            │  │
│  │ - Task health: Both healthy                              │  │
│  │ - CPU: 12%, Memory: 45%                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ CloudWatch Metrics                                        │  │
│  │ - HTTPCode_Target_5XX_Count: 20 (spike!)                │  │
│  │ - RequestCount: 25                                        │  │
│  │ - TargetResponseTime: 0.05s (normal)                     │  │
│  │ - CPUUtilization: 12% (normal)                           │  │
│  │ - MemoryUtilization: 45% (normal)                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Load Balancer Health                                      │  │
│  │ - Target group: devops-agent-demo-dev-tg                 │  │
│  │ - Healthy targets: 2/2                                    │  │
│  │ - Unhealthy targets: 0/2                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Deployment History (from SSM)                             │  │
│  │ - Latest deployment: 14:15 UTC                            │  │
│  │ - Commit: abc123def456                                    │  │
│  │ - Message: "Fix error handling"                           │  │
│  │ - Author: developer@example.com                           │  │
│  │ - Time since deployment: 8 minutes                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PHASE 2: LOG ANALYSIS                         │
│                                                                  │
│  AI analyzes collected logs:                                    │
│                                                                  │
│  Pattern Detection:                                             │
│  ✓ Found 20 ERROR level logs                                   │
│  ✓ All errors from same endpoint: /error/500                   │
│  ✓ Error message: "Intentional 500 error triggered"            │
│  ✓ Frequency: 10 errors/minute (baseline: 0.1/minute)          │
│  ✓ Duration: 2-minute spike                                     │
│                                                                  │
│  Stack Trace Analysis:                                          │
│  ✓ No actual exceptions found                                   │
│  ✓ Errors are intentionally generated                           │
│  ✓ No code crashes or unexpected errors                         │
│                                                                  │
│  Log Excerpt:                                                   │
│  {                                                              │
│    "level": "ERROR",                                            │
│    "message": "Intentional 500 error triggered",                │
│    "timestamp": "2024-01-15T14:23:45.123Z",                    │
│    "path": "/error/500",                                        │
│    "method": "GET"                                              │
│  }                                                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  PHASE 3: METRIC ANALYSIS                        │
│                                                                  │
│  AI analyzes metric trends:                                     │
│                                                                  │
│  Error Rate Analysis:                                           │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ Time    │ 5XX Count │ Total Requests │ Error Rate      │    │
│  ├─────────┼───────────┼────────────────┼─────────────────┤    │
│  │ 14:20   │ 0         │ 10             │ 0%              │    │
│  │ 14:21   │ 0         │ 12             │ 0%              │    │
│  │ 14:22   │ 0         │ 11             │ 0%              │    │
│  │ 14:23   │ 20        │ 25             │ 80% ← SPIKE!    │    │
│  │ 14:24   │ 0         │ 10             │ 0%              │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  Findings:                                                      │
│  ✓ Sudden spike from 0% to 80% error rate                      │
│  ✓ Spike lasted 1 minute                                        │
│  ✓ Returned to normal immediately after                         │
│  ✓ Pattern suggests external trigger, not gradual degradation   │
│                                                                  │
│  Resource Utilization:                                          │
│  ✓ CPU remained stable (12%)                                    │
│  ✓ Memory remained stable (45%)                                 │
│  ✓ No resource exhaustion                                       │
│  ✓ Container health remained good                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                PHASE 4: CODE CORRELATION                         │
│                                                                  │
│  AI correlates with recent deployments:                         │
│                                                                  │
│  Deployment Timeline:                                           │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ 14:00 - Deployment started                              │    │
│  │ 14:05 - New tasks launched                              │    │
│  │ 14:10 - Health checks passing                           │    │
│  │ 14:15 - Deployment complete ← 8 min before incident     │    │
│  │ 14:23 - Error spike detected ← INCIDENT                 │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  GitHub Commit Analysis:                                        │
│  Commit: abc123def456                                           │
│  Author: developer@example.com                                  │
│  Message: "Fix error handling"                                  │
│  Files Changed:                                                 │
│    - app/src/index.js (error handling logic)                   │
│                                                                  │
│  Correlation Confidence: MEDIUM                                 │
│  Reasoning:                                                     │
│  - Incident occurred 8 minutes after deployment                 │
│  - Recent code changes to error handling                        │
│  - However, error pattern suggests testing scenario             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              PHASE 5: CONTAINER INTROSPECTION                    │
│                                                                  │
│  AI analyzes ECS environment:                                   │
│                                                                  │
│  Service Status:                                                │
│  ✓ Desired count: 2                                            │
│  ✓ Running count: 2                                            │
│  ✓ Pending count: 0                                            │
│  ✓ Service stable: YES                                         │
│                                                                  │
│  Task Analysis:                                                 │
│  Task 1:                                                        │
│    - Status: RUNNING                                            │
│    - Health: HEALTHY                                            │
│    - CPU: 12%                                                   │
│    - Memory: 230MB / 512MB (45%)                               │
│    - Uptime: 8 minutes                                          │
│                                                                  │
│  Task 2:                                                        │
│    - Status: RUNNING                                            │
│    - Health: HEALTHY                                            │
│    - CPU: 11%                                                   │
│    - Memory: 225MB / 512MB (44%)                               │
│    - Uptime: 8 minutes                                          │
│                                                                  │
│  Task Definition:                                               │
│  ✓ Image: 123456789.dkr.ecr.us-east-1.amazonaws.com/app:abc123│
│  ✓ CPU: 256 units                                              │
│  ✓ Memory: 512 MB                                              │
│  ✓ Health check: Configured correctly                          │
│                                                                  │
│  Findings:                                                      │
│  ✓ No container restarts                                        │
│  ✓ No resource constraints                                      │
│  ✓ All health checks passing                                    │
│  ✓ Configuration appears correct                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              PHASE 6: ROOT CAUSE ANALYSIS                        │
│                                                                  │
│  AI synthesizes findings:                                       │
│                                                                  │
│  Primary Findings:                                              │
│  1. Error Spike Pattern                                         │
│     - 20 errors in 2-minute window                             │
│     - All from /error/500 endpoint                             │
│     - Intentional error messages in logs                        │
│     - No actual application failures                            │
│                                                                  │
│  2. System Health                                               │
│     - All containers running normally                           │
│     - No resource exhaustion                                    │
│     - Health checks passing                                     │
│     - No container restarts                                     │
│                                                                  │
│  3. Deployment Correlation                                      │
│     - Recent deployment 8 minutes before incident               │
│     - Code changes to error handling                            │
│     - However, error pattern suggests testing                   │
│                                                                  │
│  Root Cause Assessment:                                         │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ LIKELY CAUSE: Testing Scenario                          │    │
│  │                                                          │    │
│  │ Evidence:                                                │    │
│  │ • Error messages indicate intentional errors            │    │
│  │ • /error/500 is a test endpoint                         │    │
│  │ • No actual application failures                        │    │
│  │ • System health remains good                            │    │
│  │ • Pattern consistent with load testing                  │    │
│  │                                                          │    │
│  │ Confidence: HIGH (85%)                                   │    │
│  └────────────────────────────────────────────────────────┘    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                PHASE 7: RECOMMENDATIONS                          │
│                                                                  │
│  AI provides actionable recommendations:                        │
│                                                                  │
│  Immediate Actions:                                             │
│  ✓ No immediate action required                                │
│  ✓ This appears to be a testing scenario                       │
│  ✓ System is operating normally                                │
│                                                                  │
│  If This Were a Production Issue:                              │
│  1. Review recent deployment (commit abc123)                    │
│  2. Check if /error/500 endpoint should exist                  │
│  3. Consider adding rate limiting to error endpoints            │
│  4. Review error handling logic changes                         │
│  5. Consider rollback if errors persist                         │
│                                                                  │
│  Preventive Measures:                                           │
│  • Add monitoring for test endpoint usage                       │
│  • Implement separate alarms for test vs production            │
│  • Add request source tracking                                  │
│  • Consider removing test endpoints in production               │
│                                                                  │
│  Rollback Command (if needed):                                 │
│  aws ecs update-service \                                       │
│    --cluster devops-agent-demo-dev-cluster \                   │
│    --service devops-agent-demo-dev-service \                   │
│    --task-definition previous-version                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              INVESTIGATION COMPLETE                              │
│                                                                  │
│  Investigation ID: inv-abc123                                   │
│  Status: Completed                                              │
│  Duration: 2 minutes                                            │
│  Completed: 2024-01-15 14:25:45 UTC                            │
│                                                                  │
│  Summary:                                                       │
│  Error spike detected and analyzed. Determined to be a          │
│  testing scenario rather than a production issue. No action     │
│  required. System health is good.                               │
│                                                                  │
│  Related Resources:                                             │
│  • ECS Service: devops-agent-demo-dev-service                  │
│  • CloudWatch Logs: /ecs/devops-agent-demo-dev                 │
│  • GitHub Commit: abc123def456                                  │
│  • Alarm: high-5xx-errors                                       │
│                                                                  │
│  View in Console:                                               │
│  https://console.aws.amazon.com/devops-agent/investigations/... │
└─────────────────────────────────────────────────────────────────┘
```

## Time Savings Comparison

### Without DevOps Agent (Manual Investigation)
```
1. Receive alarm notification          → 1 minute
2. Log into AWS Console                → 1 minute
3. Navigate to CloudWatch Logs         → 2 minutes
4. Search for error patterns           → 5 minutes
5. Check ECS task status               → 3 minutes
6. Review recent deployments           → 3 minutes
7. Check GitHub commits                → 5 minutes
8. Correlate timing manually           → 5 minutes
9. Analyze metrics                     → 5 minutes
10. Determine root cause               → 10 minutes
11. Document findings                  → 5 minutes
────────────────────────────────────────────────
Total Time: 45 minutes
```

### With DevOps Agent (Automated Investigation)
```
1. Receive alarm notification          → 1 minute
2. DevOps Agent investigates (auto)    → 2 minutes
3. Review investigation report         → 3 minutes
4. Take action based on recommendations → 2 minutes
────────────────────────────────────────────────
Total Time: 8 minutes

Time Saved: 37 minutes (82% reduction)
```

## Investigation Report Example

```
═══════════════════════════════════════════════════════════════
AWS DEVOPS AGENT - INVESTIGATION REPORT
═══════════════════════════════════════════════════════════════

Investigation ID: inv-abc123def456
Agent Space: devops-agent-demo-dev
Status: Completed
Created: 2024-01-15 14:23:45 UTC
Completed: 2024-01-15 14:25:45 UTC
Duration: 2 minutes

───────────────────────────────────────────────────────────────
TRIGGER
───────────────────────────────────────────────────────────────
Type: CloudWatch Alarm
Alarm: high-5xx-errors
State Change: OK → ALARM
Threshold: > 10 errors in 2 evaluation periods
Actual Value: 20 errors

───────────────────────────────────────────────────────────────
TIMELINE
───────────────────────────────────────────────────────────────
14:15:00 - Deployment completed (commit abc123)
14:23:00 - Error spike begins
14:23:45 - CloudWatch alarm triggers
14:23:45 - Investigation started
14:24:15 - Log analysis completed
14:24:45 - Code correlation completed
14:25:15 - Container analysis completed
14:25:45 - Investigation completed

───────────────────────────────────────────────────────────────
FINDINGS
───────────────────────────────────────────────────────────────

1. ERROR SPIKE PATTERN
   • 20 errors in 2-minute window
   • All from /error/500 endpoint
   • Baseline: 0.1 errors/minute
   • Spike: 10 errors/minute
   • Duration: 2 minutes
   • Pattern: Sudden spike, immediate recovery

2. LOG ANALYSIS
   • Found "Intentional 500 error triggered" messages
   • No actual exception stack traces
   • No code crashes
   • Pattern suggests testing scenario

3. SYSTEM HEALTH
   • All containers: RUNNING and HEALTHY
   • CPU utilization: 12% (normal)
   • Memory utilization: 45% (normal)
   • No container restarts
   • Health checks: All passing

4. CODE CORRELATION
   • Recent deployment: 8 minutes before incident
   • Commit: abc123 - "Fix error handling"
   • Files changed: app/src/index.js
   • Correlation confidence: MEDIUM

5. RESOURCE ANALYSIS
   • No resource exhaustion
   • No configuration issues
   • Load balancer: All targets healthy
   • Network: No connectivity issues

───────────────────────────────────────────────────────────────
ROOT CAUSE
───────────────────────────────────────────────────────────────
ASSESSMENT: Testing Scenario (Not a Production Issue)

EVIDENCE:
✓ Error messages indicate intentional errors
✓ /error/500 is a test endpoint
✓ No actual application failures
✓ System health remains good
✓ Pattern consistent with load testing

CONFIDENCE: HIGH (85%)

───────────────────────────────────────────────────────────────
RECOMMENDATIONS
───────────────────────────────────────────────────────────────

IMMEDIATE ACTIONS:
• No action required - this is a testing scenario
• System is operating normally

IF THIS WERE A PRODUCTION ISSUE:
1. Review recent deployment (commit abc123)
2. Check if /error/500 endpoint should exist
3. Consider rollback if errors persist
4. Review error handling logic changes

PREVENTIVE MEASURES:
• Add monitoring for test endpoint usage
• Implement separate alarms for test vs production
• Consider removing test endpoints in production

───────────────────────────────────────────────────────────────
RELATED RESOURCES
───────────────────────────────────────────────────────────────
• ECS Cluster: devops-agent-demo-dev-cluster
• ECS Service: devops-agent-demo-dev-service
• CloudWatch Log Group: /ecs/devops-agent-demo-dev
• Load Balancer: devops-agent-demo-dev-alb
• GitHub Commit: abc123def456
• Alarm: high-5xx-errors

───────────────────────────────────────────────────────────────
INVESTIGATION METADATA
───────────────────────────────────────────────────────────────
Agent Version: 2.0
Analysis Engine: AI-powered
Data Sources: CloudWatch, ECS, ALB, GitHub
Confidence Score: 85%
Investigation Type: Automatic

═══════════════════════════════════════════════════════════════
```

This investigation flow demonstrates how AWS DevOps Agent automatically analyzes incidents, correlates data from multiple sources, and provides actionable insights - all without manual intervention!
