#!/usr/bin/env pwsh
# Configure DevOps Agent to Monitor Resources

Write-Host "=== Configuring DevOps Agent Monitoring ===" -ForegroundColor Cyan
Write-Host ""

# Get Agent Space ID
$AGENT_SPACE_ID = (Get-Content agent-space-id.txt -Raw).Trim()
Write-Host "Agent Space ID: $AGENT_SPACE_ID" -ForegroundColor Gray
Write-Host ""

# Get Terraform outputs
Write-Host "Getting infrastructure details..." -ForegroundColor Yellow
Set-Location terraform
$outputs = terraform output -json | ConvertFrom-Json

$AGENT_ROLE_ARN = $outputs.devops_agent_config.value.agent_space_role_arn
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
$ECS_CLUSTER = $outputs.ecs_cluster_name.value
$ECS_SERVICE = $outputs.ecs_service_name.value
$LOG_GROUP = $outputs.cloudwatch_log_group.value
$ALB_ARN = (terraform output -raw alb_url)

Set-Location ..

Write-Host "  Account: $ACCOUNT_ID" -ForegroundColor Gray
Write-Host "  ECS Cluster: $ECS_CLUSTER" -ForegroundColor Gray
Write-Host "  ECS Service: $ECS_SERVICE" -ForegroundColor Gray
Write-Host "  Log Group: $LOG_GROUP" -ForegroundColor Gray
Write-Host ""

# Get CloudWatch alarm ARNs
Write-Host "Getting CloudWatch alarms..." -ForegroundColor Yellow
$alarms = aws cloudwatch describe-alarms `
    --alarm-name-prefix "devops-agent-demo" `
    --region us-east-1 `
    --output json | ConvertFrom-Json

$alarmArns = @()
foreach ($alarm in $alarms.MetricAlarms) {
    $alarmArn = "arn:aws:cloudwatch:us-east-1:${ACCOUNT_ID}:alarm:$($alarm.AlarmName)"
    $alarmArns += $alarmArn
    Write-Host "  Found: $($alarm.AlarmName)" -ForegroundColor Gray
}
Write-Host ""

# Build configuration with empty resources (agent will auto-discover)
$config = @{
    aws = @{
        assumableRoleArn = $AGENT_ROLE_ARN
        accountId = $ACCOUNT_ID
        accountType = "monitor"
        resources = @()
    }
}

$configJson = $config | ConvertTo-Json -Depth 10 -Compress

# Save to temp file to avoid PowerShell escaping issues
$tempFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tempFile, $configJson, [System.Text.UTF8Encoding]::new($false))

Write-Host "Updating Agent Space association..." -ForegroundColor Yellow
Write-Host "Note: Agent will auto-discover resources through IAM permissions" -ForegroundColor Gray
Write-Host ""

# Update the association
try {
    $result = aws devopsagent associate-service `
        --agent-space-id $AGENT_SPACE_ID `
        --service-id aws `
        --configuration "file://$tempFile" `
        --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" `
        --region us-east-1 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Agent Space updated successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "The DevOps Agent will automatically discover and monitor:" -ForegroundColor Cyan
        Write-Host "  - CloudWatch Alarms (via IAM permissions)" -ForegroundColor White
        Write-Host "  - ECS Cluster: $ECS_CLUSTER" -ForegroundColor White
        Write-Host "  - ECS Service: $ECS_SERVICE" -ForegroundColor White
        Write-Host "  - CloudWatch Logs: $LOG_GROUP" -ForegroundColor White
        Write-Host ""
        Write-Host "The agent uses the IAM role to discover resources in your account." -ForegroundColor Gray
    } else {
        Write-Host "[ERROR] Failed to update Agent Space" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Exception: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Clean up temp file
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -Force
    }
}

Write-Host ""
Write-Host "=== Configuration Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Trigger incidents: .\scripts\trigger-incidents.ps1 -Scenario error-spike" -ForegroundColor Gray
Write-Host "  2. Wait 2-3 minutes for alarms to trigger" -ForegroundColor Gray
Write-Host "  3. Check DevOps Agent console: https://console.aws.amazon.com/devopsagent/" -ForegroundColor Gray
Write-Host ""
