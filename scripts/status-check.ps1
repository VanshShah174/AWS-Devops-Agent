#!/usr/bin/env pwsh
# Quick Status Check

Write-Host "=== AWS DevOps Agent Demo - Status Check ===" -ForegroundColor Cyan
Write-Host ""

# 1. Check Alarms
Write-Host "[1] CloudWatch Alarms Status:" -ForegroundColor Yellow
aws cloudwatch describe-alarms --region us-east-1 --query "MetricAlarms[?contains(AlarmName, 'devops-agent-demo')].{Name:AlarmName, State:StateValue}" --output table
Write-Host ""

# 2. Application Health
Write-Host "[2] Application Health:" -ForegroundColor Yellow
Set-Location terraform
$ALB_URL = terraform output -raw alb_url
Set-Location ..

try {
    $response = Invoke-RestMethod -Uri "$ALB_URL/health" -TimeoutSec 5
    Write-Host "  URL: $ALB_URL" -ForegroundColor Gray
    Write-Host "  Status: $($response.status)" -ForegroundColor Green
    Write-Host "  Uptime: $([math]::Round($response.uptime, 2)) seconds" -ForegroundColor White
} catch {
    Write-Host "  Status: Unhealthy or Unreachable" -ForegroundColor Red
}
Write-Host ""

# 3. DevOps Agent
Write-Host "[3] DevOps Agent Status:" -ForegroundColor Yellow
$AGENT_SPACE_ID = (Get-Content agent-space-id.txt -Raw).Trim()
Write-Host "  Agent Space ID: $AGENT_SPACE_ID" -ForegroundColor White

$agentInfo = aws devopsagent get-agent-space --agent-space-id $AGENT_SPACE_ID --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" --region us-east-1 2>&1 | ConvertFrom-Json
if ($agentInfo.agentSpace) {
    Write-Host "  Name: $($agentInfo.agentSpace.name)" -ForegroundColor White
    Write-Host "  Status: Active" -ForegroundColor Green
} else {
    Write-Host "  Status: Unknown" -ForegroundColor Yellow
}
Write-Host ""

# 4. S3 Logs
Write-Host "[4] S3 Log Storage:" -ForegroundColor Yellow
Set-Location terraform
$BUCKET = terraform output -raw logs_bucket_name
Set-Location ..

$files = aws s3 ls "s3://$BUCKET/cloudwatch-logs/" --recursive --region us-east-1
$fileCount = ($files | Measure-Object).Count

Write-Host "  Bucket: $BUCKET" -ForegroundColor White
Write-Host "  Log Files: $fileCount" -ForegroundColor Gray
if ($fileCount -gt 1) {
    Write-Host "  Latest files:" -ForegroundColor Gray
    $files | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
}
Write-Host ""

# 5. Recent Errors
Write-Host "[5] Recent Error Count:" -ForegroundColor Yellow
Set-Location terraform
$LOG_GROUP = terraform output -raw cloudwatch_log_group
Set-Location ..

$recentErrors = aws logs filter-log-events --log-group-name $LOG_GROUP --filter-pattern "ERROR" --start-time ([int64](((Get-Date).AddMinutes(-10) - [datetime]'1970-01-01').TotalMilliseconds)) --region us-east-1 2>&1 | ConvertFrom-Json

if ($recentErrors.events) {
    Write-Host "  Last 10 minutes: $($recentErrors.events.Count) errors" -ForegroundColor White
} else {
    Write-Host "  Last 10 minutes: 0 errors" -ForegroundColor Green
}
Write-Host ""

Write-Host "=== Status Check Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "To view more details:" -ForegroundColor Yellow
Write-Host "  - Full metrics: .\scripts\check-metrics.ps1" -ForegroundColor Gray
Write-Host "  - AWS Console: https://console.aws.amazon.com/cloudwatch/" -ForegroundColor Gray
Write-Host "  - Test results: cat TEST_RESULTS.md" -ForegroundColor Gray
Write-Host ""
