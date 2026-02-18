# PowerShell version of trigger-incidents.sh for Windows users
# Incident Trigger Script for Testing DevOps Agent

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('error-spike', 'memory-leak', 'cpu-spike', 'health-failure', 'timeout', 'status', 'cleanup', 'all')]
    [string]$Scenario = 'help'
)

# Get ALB URL from Terraform output
Push-Location terraform
try {
    $ALB_URL = terraform output -raw alb_url 2>$null
} catch {
    $ALB_URL = ""
} finally {
    Pop-Location
}

if ([string]::IsNullOrEmpty($ALB_URL)) {
    Write-Host "Error: Could not retrieve ALB URL from Terraform" -ForegroundColor Red
    Write-Host "Please ensure infrastructure is deployed"
    exit 1
}

Write-Host "=== DevOps Agent Incident Trigger ===" -ForegroundColor Green
Write-Host "Application URL: $ALB_URL"
Write-Host ""

function Trigger-ErrorSpike {
    Write-Host "Triggering error spike..." -ForegroundColor Yellow
    1..20 | ForEach-Object {
        Start-Job -ScriptBlock {
            param($url)
            Invoke-WebRequest -Uri "$url/error/500" -UseBasicParsing -ErrorAction SilentlyContinue
        } -ArgumentList $ALB_URL | Out-Null
        Write-Host "." -NoNewline
    }
    Get-Job | Wait-Job | Remove-Job
    Write-Host ""
    Write-Host "[OK] Error spike triggered (20 requests)" -ForegroundColor Green
    Write-Host "Expected: High 5XX error alarm should trigger"
}

function Trigger-MemoryLeak {
    Write-Host "Triggering memory leak..." -ForegroundColor Yellow
    1..5 | ForEach-Object {
        Invoke-WebRequest -Uri "$ALB_URL/error/memory-leak" -UseBasicParsing | Out-Null
        Write-Host "Memory leak iteration $_/5"
        Start-Sleep -Seconds 2
    }
    Write-Host "[OK] Memory leak triggered" -ForegroundColor Green
    Write-Host "Expected: High memory utilization alarm should trigger"
}

function Trigger-CpuSpike {
    Write-Host "Triggering CPU spike..." -ForegroundColor Yellow
    1..3 | ForEach-Object {
        Start-Job -ScriptBlock {
            param($url)
            Invoke-WebRequest -Uri "$url/error/cpu-spike" -UseBasicParsing -ErrorAction SilentlyContinue
        } -ArgumentList $ALB_URL | Out-Null
        Write-Host "CPU spike iteration $_/3"
    }
    Get-Job | Wait-Job | Remove-Job
    Write-Host "[OK] CPU spike triggered" -ForegroundColor Green
    Write-Host "Expected: High CPU utilization alarm should trigger"
}

function Trigger-HealthFailure {
    Write-Host "Triggering health check failure..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "$ALB_URL/error/disable-health" -UseBasicParsing | Out-Null
    Write-Host "[OK] Health check disabled" -ForegroundColor Green
    Write-Host "Expected: Unhealthy targets alarm should trigger"
    Write-Host ""
    Write-Host "Waiting 60 seconds for health checks to fail..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60
    Write-Host ""
    Write-Host "To restore health:"
    Write-Host "  Invoke-WebRequest -Uri $ALB_URL/error/enable-health"
}

function Trigger-Timeout {
    Write-Host "Triggering database timeout..." -ForegroundColor Yellow
    Start-Job -ScriptBlock {
        param($url)
        Invoke-WebRequest -Uri "$url/error/timeout" -UseBasicParsing -ErrorAction SilentlyContinue
    } -ArgumentList $ALB_URL | Out-Null
    Write-Host "[OK] Timeout triggered (will complete in 30s)" -ForegroundColor Green
    Write-Host "Expected: Increased response time metrics"
}

function Show-Status {
    Write-Host "Current Application Status:" -ForegroundColor Yellow
    Write-Host ""
    
    # Health check
    try {
        $health = Invoke-RestMethod -Uri "$ALB_URL/health" -UseBasicParsing
        $status = $health.status
        if ($status -eq "healthy") {
            Write-Host "Health: $status" -ForegroundColor Green
        } else {
            Write-Host "Health: $status" -ForegroundColor Red
        }
    } catch {
        Write-Host "Health: unknown" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Metrics endpoint: $ALB_URL/metrics"
    Write-Host ""
    
    # Recent alarms
    Write-Host "Checking CloudWatch alarms..." -ForegroundColor Yellow
    try {
        aws cloudwatch describe-alarms `
            --alarm-name-prefix "devops-agent-demo" `
            --state-value ALARM `
            --query 'MetricAlarms[*].[AlarmName,StateValue,StateReason]' `
            --output table
    } catch {
        Write-Host "No alarms in ALARM state"
    }
}

function Invoke-Cleanup {
    Write-Host "Cleaning up..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "$ALB_URL/error/enable-health" -UseBasicParsing | Out-Null
    Invoke-WebRequest -Uri "$ALB_URL/error/clear-memory" -UseBasicParsing | Out-Null
    Write-Host "[OK] Cleanup complete" -ForegroundColor Green
}

# Main execution
switch ($Scenario) {
    'error-spike' {
        Trigger-ErrorSpike
    }
    'memory-leak' {
        Trigger-MemoryLeak
    }
    'cpu-spike' {
        Trigger-CpuSpike
    }
    'health-failure' {
        Trigger-HealthFailure
    }
    'timeout' {
        Trigger-Timeout
    }
    'status' {
        Show-Status
    }
    'cleanup' {
        Invoke-Cleanup
    }
    'all' {
        Write-Host "Running all incident scenarios..." -ForegroundColor Yellow
        Write-Host ""
        Trigger-ErrorSpike
        Start-Sleep -Seconds 10
        Trigger-CpuSpike
        Start-Sleep -Seconds 10
        Trigger-MemoryLeak
        Write-Host ""
        Write-Host "All scenarios triggered" -ForegroundColor Green
    }
    default {
        Write-Host "Usage: .\trigger-incidents.ps1 -Scenario <scenario>"
        Write-Host ""
        Write-Host "Scenarios:"
        Write-Host "  error-spike     - Trigger multiple 500 errors"
        Write-Host "  memory-leak     - Cause memory leak in application"
        Write-Host "  cpu-spike       - Cause CPU utilization spike"
        Write-Host "  health-failure  - Disable health checks"
        Write-Host "  timeout         - Trigger database timeout"
        Write-Host "  status          - Show current application status"
        Write-Host "  cleanup         - Restore application to healthy state"
        Write-Host "  all             - Run all scenarios (except health-failure)"
        exit 1
    }
}

Write-Host ""
Write-Host "Monitor the investigation in AWS DevOps Agent console" -ForegroundColor Yellow
Write-Host "CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/`$252Fecs`$252Fdevops-agent-demo-dev"
