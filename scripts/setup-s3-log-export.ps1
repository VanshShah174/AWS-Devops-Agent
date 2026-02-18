#!/usr/bin/env pwsh
# Setup S3 Log Export and DevOps Agent Monitoring

Write-Host "=== Setting up S3 Log Export for DevOps Agent ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Apply Terraform changes to create S3 bucket
Write-Host "[1/4] Creating S3 bucket for logs..." -ForegroundColor Yellow
Set-Location terraform

terraform apply -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create S3 bucket" -ForegroundColor Red
    Set-Location ..
    exit 1
}

$BUCKET_NAME = terraform output -raw logs_bucket_name
$BUCKET_ARN = terraform output -raw logs_bucket_arn
$LOG_GROUP = terraform output -raw cloudwatch_log_group

Set-Location ..

Write-Host "[OK] S3 bucket created: $BUCKET_NAME" -ForegroundColor Green
Write-Host ""

# Step 2: Create CloudWatch Logs export task
Write-Host "[2/4] Setting up CloudWatch Logs export to S3..." -ForegroundColor Yellow

# Note: CloudWatch Logs export is a one-time task, not continuous
# For continuous export, we'll set up a scheduled task

$timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$fromTime = $timestamp - 3600000  # Last hour in milliseconds
$toTime = $timestamp

Write-Host "  Creating export task for recent logs..." -ForegroundColor Gray

try {
    $exportTask = aws logs create-export-task `
        --log-group-name $LOG_GROUP `
        --from $fromTime `
        --to $toTime `
        --destination $BUCKET_NAME `
        --destination-prefix "cloudwatch-logs" `
        --region us-east-1 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Export task created" -ForegroundColor Green
        Write-Host "  Logs will be exported to: s3://$BUCKET_NAME/cloudwatch-logs/" -ForegroundColor Gray
    } else {
        Write-Host "[WARN] Export task may have failed: $exportTask" -ForegroundColor Yellow
        Write-Host "  This is normal if there are no logs to export yet" -ForegroundColor Gray
    }
} catch {
    Write-Host "[WARN] Could not create export task: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Step 3: Update DevOps Agent to monitor S3 bucket
Write-Host "[3/4] Configuring DevOps Agent to monitor S3 bucket..." -ForegroundColor Yellow

$AGENT_SPACE_ID = (Get-Content agent-space-id.txt -Raw).Trim()
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)

Set-Location terraform
$AGENT_ROLE_ARN = terraform output -raw devops_agent_role_arn
Set-Location ..

# Build configuration with S3 bucket as monitored resource
$config = @{
    aws = @{
        assumableRoleArn = $AGENT_ROLE_ARN
        accountId = $ACCOUNT_ID
        accountType = "monitor"
        resources = @(
            @{
                resourceArn = $BUCKET_ARN
                resourceType = "AWS::S3::Bucket"
            }
        )
    }
}

$configJson = $config | ConvertTo-Json -Depth 10

# Save to temp file
$tempFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tempFile, $configJson, [System.Text.UTF8Encoding]::new($false))

try {
    $result = aws devopsagent associate-service `
        --agent-space-id $AGENT_SPACE_ID `
        --service-id aws `
        --configuration "file://$tempFile" `
        --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" `
        --region us-east-1 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] DevOps Agent configured to monitor S3 bucket" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Association already exists, this is expected" -ForegroundColor Gray
    }
} catch {
    Write-Host "[WARN] $($_.Exception.Message)" -ForegroundColor Yellow
} finally {
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -Force
    }
}

Write-Host ""

# Step 4: Add S3 permissions to DevOps Agent role
Write-Host "[4/4] Adding S3 read permissions to DevOps Agent..." -ForegroundColor Yellow

$s3Policy = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Sid = "S3LogsRead"
            Effect = "Allow"
            Action = @(
                "s3:GetObject",
                "s3:ListBucket",
                "s3:GetBucketLocation"
            )
            Resource = @(
                $BUCKET_ARN,
                "$BUCKET_ARN/*"
            )
        }
    )
}

$s3PolicyJson = $s3Policy | ConvertTo-Json -Depth 10
$s3TempFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($s3TempFile, $s3PolicyJson, [System.Text.UTF8Encoding]::new($false))

try {
    aws iam put-role-policy `
        --role-name "devops-agent-demo-dev-devops-agent-role" `
        --policy-name "devops-agent-s3-logs-access" `
        --policy-document "file://$s3TempFile" `
        --region us-east-1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] S3 permissions added" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] Failed to add S3 permissions: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if (Test-Path $s3TempFile) {
        Remove-Item $s3TempFile -Force
    }
}

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration Summary:" -ForegroundColor Yellow
Write-Host "  S3 Bucket: $BUCKET_NAME" -ForegroundColor White
Write-Host "  Log Prefix: cloudwatch-logs/" -ForegroundColor White
Write-Host "  Agent Space: $AGENT_SPACE_ID" -ForegroundColor White
Write-Host ""
Write-Host "The DevOps Agent is now monitoring the S3 bucket for logs." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Trigger incidents to generate logs" -ForegroundColor Gray
Write-Host "  2. Logs will be exported to S3 (may take a few minutes)" -ForegroundColor Gray
Write-Host "  3. DevOps Agent will analyze logs from S3" -ForegroundColor Gray
Write-Host ""
Write-Host "To manually export logs:" -ForegroundColor Yellow
Write-Host "  aws logs create-export-task --log-group-name $LOG_GROUP --from <timestamp> --to <timestamp> --destination $BUCKET_NAME --destination-prefix cloudwatch-logs" -ForegroundColor Gray
Write-Host ""
