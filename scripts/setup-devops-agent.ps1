# ============================================
# AWS DevOps Agent Setup Script (PowerShell)
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AWS DEVOPS AGENT SETUP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get Terraform outputs
Write-Host "[1/7] Getting Terraform outputs..." -ForegroundColor Yellow
cd terraform
$ACCOUNT_ID = terraform output -json | ConvertFrom-Json | Select-Object -ExpandProperty devops_agent_config | Select-Object -ExpandProperty value | Select-Object -ExpandProperty agent_space | Select-Object -ExpandProperty name
$AGENT_ROLE_ARN = terraform output -json | ConvertFrom-Json | Select-Object -ExpandProperty devops_agent_config | Select-Object -ExpandProperty value | Select-Object -ExpandProperty agent_space_role_arn
$OPERATOR_ROLE_ARN = terraform output -json | ConvertFrom-Json | Select-Object -ExpandProperty devops_agent_config | Select-Object -ExpandProperty value | Select-Object -ExpandProperty operator_role_arn
$AGENT_SPACE_NAME = terraform output -json | ConvertFrom-Json | Select-Object -ExpandProperty devops_agent_config | Select-Object -ExpandProperty value | Select-Object -ExpandProperty agent_space | Select-Object -ExpandProperty name
cd ..

$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text

Write-Host "  Account ID: $ACCOUNT_ID" -ForegroundColor White
Write-Host "  Agent Space Name: $AGENT_SPACE_NAME" -ForegroundColor White
Write-Host "  Agent Role: $AGENT_ROLE_ARN" -ForegroundColor White
Write-Host "  Operator Role: $OPERATOR_ROLE_ARN" -ForegroundColor White
Write-Host ""

# ============================================
# STEP 1: Download Service Model
# ============================================
Write-Host "[2/7] Downloading AWS DevOps Agent service model..." -ForegroundColor Yellow
if (Test-Path "devopsagent.json") {
    Write-Host "  Service model already exists, skipping download" -ForegroundColor Gray
} else {
    Invoke-WebRequest -Uri "https://d1co8nkiwcta1g.cloudfront.net/devopsagent.json" -OutFile "devopsagent.json"
    Write-Host "  ✅ Service model downloaded" -ForegroundColor Green
}
Write-Host ""

# ============================================
# STEP 2: Add Model to AWS CLI
# ============================================
Write-Host "[3/7] Adding DevOps Agent to AWS CLI..." -ForegroundColor Yellow
try {
    aws devopsagent help | Out-Null
    Write-Host "  Service model already configured" -ForegroundColor Gray
} catch {
    aws configure add-model --service-model "file://$PWD/devopsagent.json" --service-name devopsagent
    Write-Host "  ✅ Service model added to AWS CLI" -ForegroundColor Green
}
Write-Host ""

# ============================================
# STEP 3: Create Agent Space
# ============================================
Write-Host "[4/7] Creating Agent Space..." -ForegroundColor Yellow

try {
    $AGENT_SPACE_RESPONSE = aws devopsagent create-agent-space `
      --name $AGENT_SPACE_NAME `
      --description "DevOps Agent Space for ECS demo application" `
      --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" `
      --region us-east-1 2>&1 | Out-String
    
    Write-Host "  Raw response:" -ForegroundColor Gray
    Write-Host "  $AGENT_SPACE_RESPONSE" -ForegroundColor Gray
    
    if ($AGENT_SPACE_RESPONSE -match '"agentSpaceId":\s*"([^"]+)"') {
        $AGENT_SPACE_ID = $matches[1]
        Write-Host "  ✅ Agent Space created!" -ForegroundColor Green
        Write-Host "  Agent Space ID: $AGENT_SPACE_ID" -ForegroundColor White
    } elseif ($AGENT_SPACE_RESPONSE -match "already exists" -or $AGENT_SPACE_RESPONSE -match "AlreadyExists") {
        Write-Host "  ⚠️  Agent Space already exists" -ForegroundColor Yellow
        Write-Host "  Listing existing Agent Spaces..." -ForegroundColor Gray
        
        $LIST_RESPONSE = aws devopsagent list-agent-spaces `
          --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" `
          --region us-east-1 | ConvertFrom-Json
        
        $EXISTING_SPACE = $LIST_RESPONSE.agentSpaces | Where-Object { $_.name -eq $AGENT_SPACE_NAME } | Select-Object -First 1
        
        if ($EXISTING_SPACE) {
            $AGENT_SPACE_ID = $EXISTING_SPACE.agentSpaceId
            Write-Host "  ✅ Found existing Agent Space!" -ForegroundColor Green
            Write-Host "  Agent Space ID: $AGENT_SPACE_ID" -ForegroundColor White
        } else {
            Write-Host "  ❌ Could not find existing Agent Space" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "  ❌ Failed to create Agent Space" -ForegroundColor Red
        Write-Host "  Response: $AGENT_SPACE_RESPONSE" -ForegroundColor Red
        
        Write-Host ""
        Write-Host "  Possible reasons:" -ForegroundColor Yellow
        Write-Host "  1. AWS DevOps Agent is not available in your account (preview access required)" -ForegroundColor Gray
        Write-Host "  2. Service endpoint is not accessible" -ForegroundColor Gray
        Write-Host "  3. IAM permissions are insufficient" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  To check if DevOps Agent is available:" -ForegroundColor Yellow
        Write-Host "  aws devopsagent list-agent-spaces --endpoint-url 'https://api.prod.cp.aidevops.us-east-1.api.aws' --region us-east-1" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }
} catch {
    Write-Host "  ❌ Exception occurred: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# ============================================
# STEP 4: Associate AWS Account
# ============================================
Write-Host "[5/7] Associating AWS account..." -ForegroundColor Yellow

$AWS_CONFIG = @"
{
  "aws": {
    "assumableRoleArn": "$AGENT_ROLE_ARN",
    "accountId": "$ACCOUNT_ID",
    "accountType": "monitor",
    "resources": []
  }
}
"@

aws devopsagent associate-service `
  --agent-space-id $AGENT_SPACE_ID `
  --service-id aws `
  --configuration $AWS_CONFIG `
  --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" `
  --region us-east-1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ AWS account associated!" -ForegroundColor Green
} else {
    Write-Host "  ❌ Failed to associate AWS account" -ForegroundColor Red
}
Write-Host ""

# ============================================
# STEP 5: Enable Operator App
# ============================================
Write-Host "[6/7] Enabling Operator App..." -ForegroundColor Yellow

aws devopsagent enable-operator-app `
  --agent-space-id $AGENT_SPACE_ID `
  --auth-flow iam `
  --operator-app-role-arn $OPERATOR_ROLE_ARN `
  --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" `
  --region us-east-1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Operator App enabled!" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Operator App may already be enabled" -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# STEP 6: Verify Setup
# ============================================
Write-Host "[7/7] Verifying Agent Space setup..." -ForegroundColor Yellow

$AGENT_SPACE_DETAILS = aws devopsagent get-agent-space `
  --agent-space-id $AGENT_SPACE_ID `
  --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" `
  --region us-east-1 | ConvertFrom-Json

Write-Host "  ✅ Agent Space verified!" -ForegroundColor Green
Write-Host "  Name: $($AGENT_SPACE_DETAILS.name)" -ForegroundColor White
Write-Host "  Status: $($AGENT_SPACE_DETAILS.status)" -ForegroundColor White
Write-Host ""

# ============================================
# SUCCESS
# ============================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ AWS DEVOPS AGENT SETUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Agent Space ID: $AGENT_SPACE_ID" -ForegroundColor White
Write-Host ""
Write-Host "📊 Access DevOps Agent Console:" -ForegroundColor Yellow
Write-Host "   https://console.aws.amazon.com/devopsagent/" -ForegroundColor Gray
Write-Host ""
Write-Host "🔍 View Your Agent Space:" -ForegroundColor Yellow
Write-Host "   aws devopsagent get-agent-space --agent-space-id $AGENT_SPACE_ID --endpoint-url 'https://api.prod.cp.aidevops.us-east-1.api.aws' --region us-east-1" -ForegroundColor Gray
Write-Host ""
Write-Host "🧪 Now trigger an incident to test:" -ForegroundColor Yellow
cd terraform
$ALB_URL = terraform output -raw alb_url
cd ..
Write-Host "   1..20 | ForEach-Object { Invoke-WebRequest -Uri '$ALB_URL/error/500' -UseBasicParsing -ErrorAction SilentlyContinue }" -ForegroundColor Gray
Write-Host ""
Write-Host "⏱️  Wait 3 minutes, then check for investigations in the console" -ForegroundColor Yellow
Write-Host ""

# Save Agent Space ID
$AGENT_SPACE_ID | Out-File -FilePath "agent-space-id.txt"
Write-Host "💾 Agent Space ID saved to: agent-space-id.txt" -ForegroundColor Green
Write-Host ""
