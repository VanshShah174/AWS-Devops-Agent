#!/usr/bin/env pwsh
# Subscribe to SNS Topic for Alarm Notifications

param(
    [Parameter(Mandatory=$true)]
    [string]$Email
)

Write-Host "=== Subscribing to SNS Alarm Notifications ===" -ForegroundColor Cyan
Write-Host ""

$TOPIC_ARN = "arn:aws:sns:us-east-1:851725505881:devops-agent-demo-dev-alerts"

Write-Host "Topic: $TOPIC_ARN" -ForegroundColor Gray
Write-Host "Email: $Email" -ForegroundColor Gray
Write-Host ""

Write-Host "Creating subscription..." -ForegroundColor Yellow

try {
    $result = aws sns subscribe `
        --topic-arn $TOPIC_ARN `
        --protocol email `
        --notification-endpoint $Email `
        --region us-east-1 | ConvertFrom-Json
    
    if ($result.SubscriptionArn) {
        Write-Host "[OK] Subscription created!" -ForegroundColor Green
        Write-Host ""
        Write-Host "IMPORTANT: Check your email inbox!" -ForegroundColor Yellow
        Write-Host "  1. AWS will send a confirmation email to: $Email" -ForegroundColor White
        Write-Host "  2. Click the 'Confirm subscription' link in the email" -ForegroundColor White
        Write-Host "  3. Once confirmed, you'll receive alarm notifications" -ForegroundColor White
        Write-Host ""
        Write-Host "Subscription ARN: $($result.SubscriptionArn)" -ForegroundColor Gray
        
        if ($result.SubscriptionArn -eq "pending confirmation") {
            Write-Host ""
            Write-Host "Status: Pending confirmation" -ForegroundColor Yellow
            Write-Host "The subscription will be active after you confirm via email." -ForegroundColor Gray
        }
    } else {
        Write-Host "[ERROR] Failed to create subscription" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "To verify subscription status:" -ForegroundColor Yellow
Write-Host "  aws sns list-subscriptions-by-topic --topic-arn $TOPIC_ARN --region us-east-1" -ForegroundColor Gray
Write-Host ""
Write-Host "To test notifications after confirming:" -ForegroundColor Yellow
Write-Host "  .\scripts\trigger-incidents.ps1 -Scenario error-spike" -ForegroundColor Gray
Write-Host ""
