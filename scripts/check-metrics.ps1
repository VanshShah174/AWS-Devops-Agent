#!/usr/bin/env pwsh
# Check CloudWatch Metrics Script

Write-Host "=== CloudWatch Metrics Checker ===" -ForegroundColor Cyan
Write-Host ""

# Get Terraform outputs
Write-Host "Fetching infrastructure details..." -ForegroundColor Yellow
Set-Location terraform
$ALB_ARN = (terraform output -raw alb_dns_name 2>$null)
$CLUSTER_NAME = (terraform output -raw ecs_cluster_name 2>$null)
$SERVICE_NAME = (terraform output -raw ecs_service_name 2>$null)
$LOG_GROUP = (terraform output -raw cloudwatch_log_group 2>$null)
Set-Location ..

if (-not $ALB_ARN -or -not $CLUSTER_NAME) {
    Write-Host "❌ Failed to get Terraform outputs. Make sure infrastructure is deployed." -ForegroundColor Red
    exit 1
}

# Get AWS region
Set-Location terraform
$tfVars = Get-Content "terraform.tfvars" -ErrorAction SilentlyContinue
if ($tfVars) {
    $regionLine = $tfVars | Where-Object { $_ -match 'aws_region\s*=\s*"([^"]+)"' }
    if ($regionLine) {
        $AWS_REGION = $Matches[1]
    }
}
if (-not $AWS_REGION) {
    $AWS_REGION = (aws configure get region)
}
if (-not $AWS_REGION) {
    $AWS_REGION = "us-east-1"
}
Set-Location ..

Write-Host "Region: $AWS_REGION" -ForegroundColor Gray
Write-Host "Cluster: $CLUSTER_NAME" -ForegroundColor Gray
Write-Host "Service: $SERVICE_NAME" -ForegroundColor Gray
Write-Host ""

# Time range (last 10 minutes)
$EndTime = (Get-Date).ToUniversalTime()
$StartTime = $EndTime.AddMinutes(-10)

Write-Host "Checking metrics from $($StartTime.ToString('HH:mm:ss')) to $($EndTime.ToString('HH:mm:ss')) UTC" -ForegroundColor Gray
Write-Host ""

# Function to get metric statistics
function Get-MetricStats {
    param(
        [string]$Namespace,
        [string]$MetricName,
        [hashtable]$Dimensions,
        [string]$Statistic = "Sum"
    )
    
    $dimArgs = @()
    foreach ($key in $Dimensions.Keys) {
        $dimArgs += "Name=$key,Value=$($Dimensions[$key])"
    }
    
    $result = aws cloudwatch get-metric-statistics `
        --namespace $Namespace `
        --metric-name $MetricName `
        --dimensions $dimArgs `
        --start-time $StartTime.ToString("yyyy-MM-ddTHH:mm:ss") `
        --end-time $EndTime.ToString("yyyy-MM-ddTHH:mm:ss") `
        --period 60 `
        --statistics $Statistic `
        --region $AWS_REGION `
        --output json 2>$null | ConvertFrom-Json
    
    return $result
}

# Check ALB 5XX Errors
Write-Host "[METRICS] ALB Metrics:" -ForegroundColor Cyan
Write-Host "  Checking HTTPCode_Target_5XX_Count..." -ForegroundColor Yellow

# Get ALB and Target Group ARN suffixes
$albs = aws elbv2 describe-load-balancers --region $AWS_REGION --output json | ConvertFrom-Json
$alb = $albs.LoadBalancers | Where-Object { $_.DNSName -eq $ALB_ARN }

if ($alb) {
    $albArnSuffix = $alb.LoadBalancerArn -replace '.*loadbalancer/', ''
    
    $tgs = aws elbv2 describe-target-groups --load-balancer-arn $alb.LoadBalancerArn --region $AWS_REGION --output json | ConvertFrom-Json
    $tg = $tgs.TargetGroups[0]
    $tgArnSuffix = $tg.TargetGroupArn -replace '.*targetgroup/', ''
    
    $metrics5xx = Get-MetricStats -Namespace "AWS/ApplicationELB" -MetricName "HTTPCode_Target_5XX_Count" `
        -Dimensions @{LoadBalancer=$albArnSuffix; TargetGroup=$tgArnSuffix}
    
    if ($metrics5xx.Datapoints.Count -gt 0) {
        $total5xx = ($metrics5xx.Datapoints | Measure-Object -Property Sum -Sum).Sum
        Write-Host "  [OK] 5XX Errors: $total5xx" -ForegroundColor Green
        $metrics5xx.Datapoints | Sort-Object Timestamp | ForEach-Object {
            Write-Host "    $($_.Timestamp): $($_.Sum)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  [WARN] No 5XX errors recorded (or metrics not yet available)" -ForegroundColor Yellow
    }
    
    # Check 2XX for comparison
    $metrics2xx = Get-MetricStats -Namespace "AWS/ApplicationELB" -MetricName "HTTPCode_Target_2XX_Count" `
        -Dimensions @{LoadBalancer=$albArnSuffix; TargetGroup=$tgArnSuffix}
    
    if ($metrics2xx.Datapoints.Count -gt 0) {
        $total2xx = ($metrics2xx.Datapoints | Measure-Object -Property Sum -Sum).Sum
        Write-Host "  [OK] 2XX Success: $total2xx" -ForegroundColor Green
    }
    
    # Check Request Count
    $metricsReq = Get-MetricStats -Namespace "AWS/ApplicationELB" -MetricName "RequestCount" `
        -Dimensions @{LoadBalancer=$albArnSuffix; TargetGroup=$tgArnSuffix}
    
    if ($metricsReq.Datapoints.Count -gt 0) {
        $totalReq = ($metricsReq.Datapoints | Measure-Object -Property Sum -Sum).Sum
        Write-Host "  [OK] Total Requests: $totalReq" -ForegroundColor Green
    }
} else {
    Write-Host "  [ERROR] Could not find ALB" -ForegroundColor Red
}

Write-Host ""

# Check ECS Metrics
Write-Host "[METRICS] ECS Metrics:" -ForegroundColor Cyan

$metricsCPU = Get-MetricStats -Namespace "AWS/ECS" -MetricName "CPUUtilization" `
    -Dimensions @{ClusterName=$CLUSTER_NAME; ServiceName=$SERVICE_NAME} -Statistic "Average"

if ($metricsCPU.Datapoints.Count -gt 0) {
    $avgCPU = ($metricsCPU.Datapoints | Measure-Object -Property Average -Average).Average
    Write-Host "  [OK] CPU Utilization: $([math]::Round($avgCPU, 2))%" -ForegroundColor Green
} else {
    Write-Host "  [WARN] No CPU metrics available" -ForegroundColor Yellow
}

$metricsMemory = Get-MetricStats -Namespace "AWS/ECS" -MetricName "MemoryUtilization" `
    -Dimensions @{ClusterName=$CLUSTER_NAME; ServiceName=$SERVICE_NAME} -Statistic "Average"

if ($metricsMemory.Datapoints.Count -gt 0) {
    $avgMemory = ($metricsMemory.Datapoints | Measure-Object -Property Average -Average).Average
    Write-Host "  [OK] Memory Utilization: $([math]::Round($avgMemory, 2))%" -ForegroundColor Green
} else {
    Write-Host "  [WARN] No Memory metrics available" -ForegroundColor Yellow
}

Write-Host ""

# Check CloudWatch Alarms
Write-Host "[ALARMS] CloudWatch Alarms:" -ForegroundColor Cyan

$alarms = aws cloudwatch describe-alarms --region $AWS_REGION --output json | ConvertFrom-Json
$projectAlarms = $alarms.MetricAlarms | Where-Object { $_.AlarmName -like "*devops-agent-demo*" }

if ($projectAlarms.Count -gt 0) {
    foreach ($alarm in $projectAlarms) {
        $color = switch ($alarm.StateValue) {
            "OK" { "Green" }
            "ALARM" { "Red" }
            "INSUFFICIENT_DATA" { "Yellow" }
            default { "Gray" }
        }
        $icon = switch ($alarm.StateValue) {
            "OK" { "[OK]" }
            "ALARM" { "[ALARM]" }
            "INSUFFICIENT_DATA" { "[WARN]" }
            default { "[?]" }
        }
        Write-Host "  $icon $($alarm.AlarmName): $($alarm.StateValue)" -ForegroundColor $color
    }
} else {
    Write-Host "   No alarms found" -ForegroundColor Yellow
}

Write-Host ""

# Check Recent Logs
Write-Host "[LOGS] Recent Error Logs:" -ForegroundColor Cyan

$logs = aws logs filter-log-events `
    --log-group-name $LOG_GROUP `
    --filter-pattern "ERROR" `
    --start-time ([int64](($StartTime - [datetime]'1970-01-01').TotalMilliseconds)) `
    --limit 5 `
    --region $AWS_REGION `
    --output json 2>$null | ConvertFrom-Json

if ($logs.events.Count -gt 0) {
    Write-Host "  Found $($logs.events.Count) error log entries:" -ForegroundColor Yellow
    foreach ($event in $logs.events) {
        $timestamp = [DateTimeOffset]::FromUnixTimeMilliseconds($event.timestamp).ToString("HH:mm:ss")
        $message = $event.message -replace '\n', ' ' | Select-Object -First 100
        Write-Host "  [$timestamp] $message" -ForegroundColor Gray
    }
} else {
    Write-Host "  [WARN] No error logs found in the last 10 minutes" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Metrics Check Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "[TIPS] Tips:" -ForegroundColor Yellow
Write-Host "  - Metrics can take 1-5 minutes to appear in CloudWatch" -ForegroundColor Gray
Write-Host "  - Run ./trigger-incidents.ps1 to generate test incidents" -ForegroundColor Gray
Write-Host "  - Check the CloudWatch Dashboard in AWS Console for visualizations" -ForegroundColor Gray
