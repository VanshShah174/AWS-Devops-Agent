#!/usr/bin/env pwsh
# Add CloudWatch permissions to DevOps Agent role

Write-Host "=== Adding CloudWatch Permissions to DevOps Agent ===" -ForegroundColor Cyan
Write-Host ""

$ROLE_NAME = "devops-agent-demo-dev-devops-agent-role"
$POLICY_NAME = "devops-agent-cloudwatch-monitoring"

$policy = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Sid = "CloudWatchMonitoring"
            Effect = "Allow"
            Action = @(
                "cloudwatch:DescribeAlarms",
                "cloudwatch:DescribeAlarmHistory",
                "cloudwatch:GetMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:FilterLogEvents",
                "logs:GetLogEvents",
                "ecs:DescribeClusters",
                "ecs:DescribeServices",
                "ecs:DescribeTasks",
                "ecs:ListTasks",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetHealth"
            )
            Resource = "*"
        }
    )
}

$policyJson = $policy | ConvertTo-Json -Depth 10

# Save to temp file
$tempFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tempFile, $policyJson, [System.Text.UTF8Encoding]::new($false))

Write-Host "Adding CloudWatch monitoring permissions to role: $ROLE_NAME" -ForegroundColor Yellow
Write-Host ""

try {
    aws iam put-role-policy `
        --role-name $ROLE_NAME `
        --policy-name $POLICY_NAME `
        --policy-document "file://$tempFile" `
        --region us-east-1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Permissions added successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "The DevOps Agent can now:" -ForegroundColor Cyan
        Write-Host "  - Read CloudWatch alarms and their history" -ForegroundColor White
        Write-Host "  - Query CloudWatch metrics" -ForegroundColor White
        Write-Host "  - Read CloudWatch Logs" -ForegroundColor White
        Write-Host "  - Describe ECS resources" -ForegroundColor White
        Write-Host "  - Check ALB target health" -ForegroundColor White
    } else {
        Write-Host "[ERROR] Failed to add permissions" -ForegroundColor Red
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
Write-Host "The DevOps Agent should now be able to monitor your resources." -ForegroundColor Green
Write-Host "It will detect alarm state changes and investigate automatically." -ForegroundColor Gray
Write-Host ""
