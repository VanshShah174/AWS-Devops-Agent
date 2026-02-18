#!/usr/bin/env pwsh
# Export recent CloudWatch Logs to S3

Write-Host "=== Exporting CloudWatch Logs to S3 ===" -ForegroundColor Cyan
Write-Host ""

Set-Location terraform
$BUCKET_NAME = terraform output -raw logs_bucket_name
$LOG_GROUP = terraform output -raw cloudwatch_log_group
Set-Location ..

Write-Host "Bucket: $BUCKET_NAME" -ForegroundColor Gray
Write-Host "Log Group: $LOG_GROUP" -ForegroundColor Gray
Write-Host ""

# Calculate time range (last hour)
$now = Get-Date
$fromTime = [int64](($now.AddHours(-1) - [datetime]'1970-01-01').TotalMilliseconds)
$toTime = [int64](($now - [datetime]'1970-01-01').TotalMilliseconds)

Write-Host "Exporting logs from last hour..." -ForegroundColor Yellow
Write-Host "  From: $($now.AddHours(-1).ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "  To: $($now.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host ""

try {
    $result = aws logs create-export-task `
        --log-group-name $LOG_GROUP `
        --from $fromTime `
        --to $toTime `
        --destination $BUCKET_NAME `
        --destination-prefix "cloudwatch-logs" `
        --region us-east-1 2>&1 | ConvertFrom-Json
    
    if ($result.taskId) {
        $taskId = $result.taskId
        Write-Host "[OK] Export task created: $taskId" -ForegroundColor Green
        Write-Host ""
        
        # Wait for export to complete
        Write-Host "Waiting for export to complete..." -ForegroundColor Yellow
        $maxWait = 60
        $waited = 0
        
        while ($waited -lt $maxWait) {
            Start-Sleep -Seconds 5
            $waited += 5
            
            $status = aws logs describe-export-tasks `
                --task-id $taskId `
                --region us-east-1 2>&1 | ConvertFrom-Json
            
            $state = $status.exportTasks[0].status.code
            Write-Host "  Status: $state" -ForegroundColor Gray
            
            if ($state -eq "COMPLETED") {
                Write-Host "[OK] Export completed!" -ForegroundColor Green
                break
            } elseif ($state -eq "FAILED") {
                Write-Host "[ERROR] Export failed" -ForegroundColor Red
                break
            }
        }
        
        Write-Host ""
        Write-Host "Checking S3 bucket contents..." -ForegroundColor Yellow
        aws s3 ls "s3://$BUCKET_NAME/cloudwatch-logs/" --recursive --region us-east-1
        
    } else {
        Write-Host "[ERROR] Failed to create export task" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Export Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "The DevOps Agent can now access logs from:" -ForegroundColor Green
Write-Host "  s3://$BUCKET_NAME/cloudwatch-logs/" -ForegroundColor White
Write-Host ""
