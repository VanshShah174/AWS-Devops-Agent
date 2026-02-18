# ============================================
# AWS DevOps Agent Configuration
# ============================================
# Note: AWS DevOps Agent is in preview and requires special setup
# This configuration creates the IAM roles needed for DevOps Agent

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# IAM Role for DevOps Agent Space
resource "aws_iam_role" "devops_agent" {
  name = "${local.name_prefix}-devops-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "aidevops.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:aidevops:${var.aws_region}:${data.aws_caller_identity.current.account_id}:agentspace/*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-devops-agent-role"
  }
}

# Attach AWS managed policy for DevOps Agent (if it exists)
# Note: This policy may not exist if DevOps Agent is not available in your region
resource "aws_iam_role_policy_attachment" "devops_agent_managed" {
  count      = 0 # Disabled until policy is available
  role       = aws_iam_role.devops_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AIOpsAssistantPolicy"
}

# Additional inline policy for DevOps Agent
resource "aws_iam_role_policy" "devops_agent_additional" {
  name = "${local.name_prefix}-devops-agent-additional-policy"
  role = aws_iam_role.devops_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAwsSupportActions"
        Effect = "Allow"
        Action = [
          "support:CreateCase",
          "support:DescribeCases"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowExpandedAIOpsAssistantPolicy"
        Effect = "Allow"
        Action = [
          "aidevops:GetKnowledgeItem",
          "aidevops:ListKnowledgeItems",
          "eks:AccessKubernetesApi",
          "synthetics:GetCanaryRuns",
          "route53:GetHealthCheckStatus",
          "resource-explorer-2:Search"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for DevOps Agent Operator App (Web Interface)
resource "aws_iam_role" "devops_agent_operator" {
  name = "${local.name_prefix}-devops-agent-operator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "aidevops.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:aidevops:${var.aws_region}:${data.aws_caller_identity.current.account_id}:agentspace/*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-devops-agent-operator-role"
  }
}

# Operator App inline policy
resource "aws_iam_role_policy" "devops_agent_operator" {
  name = "${local.name_prefix}-devops-agent-operator-policy"
  role = aws_iam_role.devops_agent_operator.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBasicOperatorActions"
        Effect = "Allow"
        Action = [
          "aidevops:GetAgentSpace",
          "aidevops:GetAssociation",
          "aidevops:ListAssociations",
          "aidevops:CreateBacklogTask",
          "aidevops:GetBacklogTask",
          "aidevops:UpdateBacklogTask",
          "aidevops:ListBacklogTasks",
          "aidevops:ListChildExecutions",
          "aidevops:ListJournalRecords",
          "aidevops:DiscoverTopology",
          "aidevops:InvokeAgent",
          "aidevops:ListGoals",
          "aidevops:ListRecommendations",
          "aidevops:ListExecutions",
          "aidevops:GetRecommendation",
          "aidevops:UpdateRecommendation",
          "aidevops:CreateKnowledgeItem",
          "aidevops:ListKnowledgeItems",
          "aidevops:GetKnowledgeItem",
          "aidevops:UpdateKnowledgeItem",
          "aidevops:ListPendingMessages",
          "aidevops:InitiateChatForCase",
          "aidevops:EndChatForCase",
          "aidevops:DescribeSupportLevel",
          "aidevops:SendChatMessage"
        ]
        Resource = "arn:aws:aidevops:${var.aws_region}:${data.aws_caller_identity.current.account_id}:agentspace/*"
      },
      {
        Sid    = "AllowSupportOperatorActions"
        Effect = "Allow"
        Action = [
          "support:DescribeCases",
          "support:InitiateChatForCase",
          "support:DescribeSupportLevel"
        ]
        Resource = "*"
      }
    ]
  })
}

# SSM Parameter for DevOps Agent Configuration
resource "aws_ssm_parameter" "devops_agent_config" {
  name        = "/${local.name_prefix}/devops-agent/config"
  description = "DevOps Agent configuration"
  type        = "String"

  value = jsonencode({
    agentSpace = {
      name        = local.name_prefix
      description = "DevOps Agent space for ${local.name_prefix}"
      resources = {
        ecsCluster   = aws_ecs_cluster.main.name
        ecsService   = aws_ecs_service.app.name
        logGroup     = aws_cloudwatch_log_group.app.name
        loadBalancer = aws_lb.main.arn
      }
    }
    integrations = {
      github = {
        repository = var.github_repo
        enabled    = var.github_repo != ""
      }
      cloudwatch = {
        logGroup = aws_cloudwatch_log_group.app.name
        alarms = [
          aws_cloudwatch_metric_alarm.cpu_high.alarm_name,
          aws_cloudwatch_metric_alarm.memory_high.alarm_name,
          aws_cloudwatch_metric_alarm.unhealthy_targets.alarm_name,
          aws_cloudwatch_metric_alarm.high_5xx_errors.alarm_name,
          aws_cloudwatch_metric_alarm.error_count_high.alarm_name
        ]
      }
    }
    roles = {
      agentSpaceRole = aws_iam_role.devops_agent.arn
      operatorRole   = aws_iam_role.devops_agent_operator.arn
    }
  })

  tags = {
    Name = "${local.name_prefix}-devops-agent-config"
  }
}

# Output for Agent Space configuration
output "devops_agent_config" {
  description = "DevOps Agent configuration"
  value = {
    agent_space_role_arn = aws_iam_role.devops_agent.arn
    operator_role_arn    = aws_iam_role.devops_agent_operator.arn
    config_param         = aws_ssm_parameter.devops_agent_config.name
    agent_space = {
      name        = local.name_prefix
      ecs_cluster = aws_ecs_cluster.main.name
      ecs_service = aws_ecs_service.app.name
      log_group   = aws_cloudwatch_log_group.app.name
      alb_arn     = aws_lb.main.arn
    }
    setup_instructions = <<-EOT
      To create the Agent Space, run:
      
      1. Download the service model:
         curl -o devopsagent.json https://d1co8nkiwcta1g.cloudfront.net/devopsagent.json
      
      2. Add to AWS CLI:
         aws configure add-model --service-model file://devopsagent.json --service-name devopsagent
      
      3. Create Agent Space:
         aws devopsagent create-agent-space \
           --name "${local.name_prefix}" \
           --description "DevOps Agent for ${local.name_prefix}" \
           --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" \
           --region us-east-1
      
      4. Associate AWS account (use the agent_space_id from step 3):
         aws devopsagent associate-service \
           --agent-space-id <AGENT_SPACE_ID> \
           --service-id aws \
           --configuration '{"aws":{"assumableRoleArn":"${aws_iam_role.devops_agent.arn}","accountId":"${data.aws_caller_identity.current.account_id}","accountType":"monitor","resources":[]}}' \
           --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" \
           --region us-east-1
      
      5. Enable Operator App:
         aws devopsagent enable-operator-app \
           --agent-space-id <AGENT_SPACE_ID> \
           --auth-flow iam \
           --operator-app-role-arn "${aws_iam_role.devops_agent_operator.arn}" \
           --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" \
           --region us-east-1
      
      6. Access the console:
         https://console.aws.amazon.com/devopsagent/
    EOT
  }
  sensitive = false
}
