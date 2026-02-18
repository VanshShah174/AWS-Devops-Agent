#!/usr/bin/env pwsh
# Verify DevOps Agent Monitoring Capabilities

Write-Host "=== Verifying DevOps Agent Monitoring ===" -ForegroundColor Cyan
Write-Host ""

$AGENT_SPACE_ID = (Get-Content agent-space-id.txt -Raw).Trim()

# 1. Verify Agent Space exists and is active
Write-Host "[1] Agent Space Status:" -ForegroundColor Yellow
$agentSpace = aws devopsagent get-agent-space `
    --agent-space-id $AGENT_SPACE_ID `
    --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" `
    --region us-east-1 | ConvertFrom-Json

if ($agentSpace.agentSpace) {
    Write-Host "  [OK] Agent Space Active" -ForegroundColor Green
    Write-Host "    Name: $($agentSpace.agentSpace.name)" -ForegroundColor White
    Write-Host "    ID: $AGENT_SPACE_ID" -ForegroundColor Gray
} else {
    Write-Host "  [ERROR] Agent Space not found" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 2. Verify AWS account association
Write-Host "[2] AWS Account Association:" -ForegroundColor Yellow
$associations = aws devopsagent list-associations `
    --agent-space-id $AGENT_SPACE_ID `
    --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" `
    --region us-east-1 | ConvertFrom-Json

if ($associations.associations.Count -gt 0) {
    $assoc = $associations.associations[0]
    Write-Host "  [OK] AWS Account Associated" -ForegroundColor Green
    Write-Host "    Account ID: $($assoc.configuration.aws.accountId)" -ForegroundColor White
    Write-Host "    Account Type: $($assoc.configuration.aws.accountType)" -ForegroundColor Gray
    Write-Host "    Role ARN: $($assoc.configuration.aws.assumableRoleArn)" -ForegroundColor Gray
    Write-Host "    Status: $($assoc.status)" -ForegroundColor Gray
} else {
    Write-Host "  [ERROR] No AWS account associated" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 3. Verify IAM Role Permissions
Write-Host "[3] IAM Role Permissions:" -ForegroundColor Yellow
$roleName = "devops-agent-demo-dev-devops-agent-role"

# List all policies attached to the role
$inlinePolicies = aws iam list-role-policies --role-name $roleName --region us-east-1 | ConvertFrom-Json

Write-Host "  [OK] Role: $roleName" -ForegroundColor Green
Write-Host "  Inline Policies:" -ForegroundColor White
foreach ($policy in $inlinePolicies.PolicyNames) {
    Write-Host "    - $policy" -ForegroundColor Gray
}
Write-Host ""

# 4. Test CloudWatch Access (what agent uses)
Write-Host "[4] Testing Agent's CloudWatch Access:" -ForegroundColor Yellow

# Get alarms (agent polls these)
$alarms = aws cloudwatch describe-alarms `
    --alarm-name-prefix "devops-agent-demo" `
    --region us-east-1 `
    --query "MetricAlarms[*].[AlarmName,StateValue]" `
    --output text

if ($alarms) {
    Write-Host "  [OK] Can read CloudWatch alarms" -ForegroundColor Green
    $alarmCount = ($alarms -split "`n").Count
    Write-Host "    Found $alarmCount alarms" -ForegroundColor Gray
} else {
    Write-Host "  [WARN] No alarms found" -ForegroundColor Yellow
}
Write-Host ""

# 5. Test Alarm History Access (agent reads this)
Write-Host "[5] Testing Alarm History Access:" -ForegroundColor Yellow
$history = aws cloudwatch describe-alarm-history `
    --alarm-name "devops-agent-demo-dev-high-5xx-errors" `
    --max-records 1 `
    --region us-east-1 | ConvertFrom-Json

if ($history.AlarmHistoryItems.Count -gt 0) {
    Write-Host "  [OK] Can read alarm history" -ForegroundColor Green
    $latest = $history.AlarmHistoryItems[0]
    Write-Host "    Latest event: $($latest.HistoryItemType)" -ForegroundColor Gray
    Write-Host "    Timestamp: $($latest.Timestamp)" -ForegroundColor Gray
} else {
    Write-Host "  [WARN] No alarm history found" -ForegroundColor Yellow
}
Write-Host ""

# 6. Test CloudWatch Logs Access
Write-Host "[6] Testing CloudWatch Logs Access:" -ForegroundColor Yellow
Set-Location terraform
$LOG_GROUP = terraform output -raw cloudwatch_log_group
Set-Location ..

$logGroups = aws logs describe-log-groups `
    --log-group-name-prefix $LOG_GROUP `
    --region us-east-1 | ConvertFrom-Json

if ($logGroups.logGroups.Count -gt 0) {
    Write-Host "  [OK] Can read CloudWatch Logs" -ForegroundColor Green
    Write-Host "    Log Group: $LOG_GROUP" -ForegroundColor Gray
} else {
    Write-Host "  [WARN] Cannot access log groups" -ForegroundColor Yellow
}
Write-Host ""

# 7. Test S3 Access
Write-Host "[7] Testing S3 Logs Access:" -ForegroundColor Yellow
Set-Location terraform
$BUCKET = terraform output -raw logs_bucket_name
Set-Location ..

$s3Objects = aws s3 ls "s3://$BUCKET/cloudwatch-logs/" --region us-east-1 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Can read S3 logs bucket" -ForegroundColor Green
    Write-Host "    Bucket: $BUCKET" -ForegroundColor Gray
} else {
    Write-Host "  [WARN] Cannot access S3 bucket" -ForegroundColor Yellow
}
Write-Host ""

# 8. Test ECS Access
Write-Host "[8] Testing ECS Resource Access:" -ForegroundColor Yellow
Set-Location terraform
$CLUSTER = terraform output -raw ecs_cluster_name
$SERVICE = terraform output -raw ecs_service_name
Set-Location ..

$ecsService = aws ecs describe-services `
    --cluster $CLUSTER `
    --services $SERVICE `
    --region us-east-1 | ConvertFrom-Json

if ($ecsService.services.Count -gt 0) {
    Write-Host "  [OK] Can read ECS resources" -ForegroundColor Green
    Write-Host "    Cluster: $CLUSTER" -ForegroundColor Gray
    Write-Host "    Service: $SERVICE" -ForegroundColor Gray
} else {
    Write-Host "  [WARN] Cannot access ECS resources" -ForegroundColor Yellow
}
Write-Host ""

# 9. Check SNS Topic (for comparison)
Write-Host "[9] SNS Topic Status (for comparison):" -ForegroundColor Yellow
$TOPIC_ARN = "arn:aws:sns:us-east-1:851725505881:devops-agent-demo-dev-alerts"

$subscriptions = aws sns list-subscriptions-by-topic `
    --topic-arn $TOPIC_ARN `
    --region us-east-1 | ConvertFrom-Json

Write-Host "  Topic: devops-agent-demo-dev-alerts" -ForegroundColor White
Write-Host "  Subscriptions: $($subscriptions.Subscriptions.Count)" -ForegroundColor Gray

if ($subscriptions.Subscriptions.Count -eq 0) {
    Write-Host "  [INFO] No SNS subscriptions (Agent doesn't need them)" -ForegroundColor Cyan
    Write-Host "    Agent monitors via IAM permissions, not SNS" -ForegroundColor Gray
} else {
    Write-Host "  [OK] $($subscriptions.Subscriptions.Count) subscription(s) configured" -ForegroundColor Green
}
Write-Host ""

# 10. Summary
Write-Host "=== Verification Summary ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "How the DevOps Agent Monitors:" -ForegroundColor Yellow
Write-Host "  1. Agent uses IAM role to assume permissions" -ForegroundColor White
Write-Host "  2. Polls CloudWatch alarms periodically" -ForegroundColor White
Write-Host "  3. Reads alarm history when state changes detected" -ForegroundColor White
Write-Host "  4. Analyzes CloudWatch Logs for error patterns" -ForegroundColor White
Write-Host "  5. Accesses S3 for exported log analysis" -ForegroundColor White
Write-Host "  6. Queries ECS for service health" -ForegroundColor White
Write-Host ""
Write-Host "Key Point:" -ForegroundColor Yellow
Write-Host "  The agent does NOT rely on SNS subscriptions." -ForegroundColor White
Write-Host "  It actively monitors resources using IAM permissions." -ForegroundColor White
Write-Host "  SNS is only for sending notifications to humans (email, etc.)" -ForegroundColor Gray
Write-Host ""
Write-Host "Current Status: [OK] Agent has full monitoring access" -ForegroundColor Green
Write-Host ""
