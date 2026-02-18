# Lambda Function for Automated Remediation (Playbook)

# IAM Role for Lambda
resource "aws_iam_role" "playbook_lambda" {
  name = "${local.name_prefix}-playbook-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-playbook-lambda-role"
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "playbook_lambda" {
  name = "${local.name_prefix}-playbook-lambda-policy"
  role = aws_iam_role.playbook_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid    = "ECSRemediation"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricStatistics"
        ]
        Resource = "*"
      },
      {
        Sid    = "SNSPublish"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

# Lambda Function Code
data "archive_file" "playbook_lambda" {
  type        = "zip"
  output_path = "${path.module}/playbook-lambda.zip"

  source {
    content  = <<-EOF
const AWS = require('aws-sdk');
const ecs = new AWS.ECS();
const cloudwatch = new AWS.CloudWatch();
const sns = new AWS.SNS();

const CLUSTER_NAME = process.env.CLUSTER_NAME;
const SERVICE_NAME = process.env.SERVICE_NAME;
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;

exports.handler = async (event) => {
    console.log('Playbook triggered:', JSON.stringify(event, null, 2));
    
    // Parse SNS message
    const message = JSON.parse(event.Records[0].Sns.Message);
    const alarmName = message.AlarmName;
    const newState = message.NewStateValue;
    const reason = message.NewStateReason;
    
    console.log(`Alarm: $${alarmName}, State: $${newState}`);
    
    // Only act on ALARM state
    if (newState !== 'ALARM') {
        console.log('Not in ALARM state, skipping remediation');
        return { statusCode: 200, body: 'No action needed' };
    }
    
    let action = '';
    let result = '';
    
    try {
        // Determine action based on alarm
        if (alarmName.includes('high-5xx-errors')) {
            action = 'Restart ECS Service';
            result = await restartECSService();
        } else if (alarmName.includes('cpu-high')) {
            action = 'Scale ECS Service';
            result = await scaleECSService();
        } else if (alarmName.includes('unhealthy-targets')) {
            action = 'Force New Deployment';
            result = await forceNewDeployment();
        } else {
            action = 'No automated action';
            result = 'Alarm type not configured for auto-remediation';
        }
        
        // Send notification
        await sendNotification(alarmName, action, result, 'SUCCESS');
        
        return {
            statusCode: 200,
            body: JSON.stringify({ action, result })
        };
        
    } catch (error) {
        console.error('Playbook execution failed:', error);
        await sendNotification(alarmName, action, error.message, 'FAILED');
        throw error;
    }
};

async function restartECSService() {
    console.log('Restarting ECS service...');
    
    const params = {
        cluster: CLUSTER_NAME,
        service: SERVICE_NAME,
        forceNewDeployment: true
    };
    
    const result = await ecs.updateService(params).promise();
    console.log('Service restart initiated');
    
    return `Restarted service $${SERVICE_NAME}. Deployment ID: $${result.service.deployments[0].id}`;
}

async function scaleECSService() {
    console.log('Scaling ECS service...');
    
    // Get current desired count
    const describeParams = {
        cluster: CLUSTER_NAME,
        services: [SERVICE_NAME]
    };
    
    const current = await ecs.describeServices(describeParams).promise();
    const currentCount = current.services[0].desiredCount;
    const newCount = currentCount + 1; // Scale up by 1
    
    const updateParams = {
        cluster: CLUSTER_NAME,
        service: SERVICE_NAME,
        desiredCount: newCount
    };
    
    await ecs.updateService(updateParams).promise();
    console.log(`Scaled from $${currentCount} to $${newCount} tasks`);
    
    return `Scaled service from $${currentCount} to $${newCount} tasks`;
}

async function forceNewDeployment() {
    console.log('Forcing new deployment...');
    
    const params = {
        cluster: CLUSTER_NAME,
        service: SERVICE_NAME,
        forceNewDeployment: true
    };
    
    await ecs.updateService(params).promise();
    console.log('New deployment forced');
    
    return 'Forced new deployment to replace unhealthy tasks';
}

async function sendNotification(alarmName, action, result, status) {
    const emoji = status === 'SUCCESS' ? '✅' : '❌';
    const message = `
$${emoji} Playbook Execution Report

Alarm: $${alarmName}
Action: $${action}
Result: $${result}
Status: $${status}
Timestamp: $${new Date().toISOString()}

This was an automated remediation action.
    `.trim();
    
    const params = {
        TopicArn: SNS_TOPIC_ARN,
        Subject: `$${emoji} Playbook: $${action}`,
        Message: message
    };
    
    await sns.publish(params).promise();
    console.log('Notification sent');
}
EOF
    filename = "index.js"
  }
}

# Lambda Function
resource "aws_lambda_function" "playbook" {
  filename         = data.archive_file.playbook_lambda.output_path
  function_name    = "${local.name_prefix}-playbook"
  role            = aws_iam_role.playbook_lambda.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.playbook_lambda.output_base64sha256
  runtime         = "nodejs18.x"
  timeout         = 60

  environment {
    variables = {
      CLUSTER_NAME   = aws_ecs_cluster.main.name
      SERVICE_NAME   = aws_ecs_service.app.name
      SNS_TOPIC_ARN  = aws_sns_topic.alerts.arn
    }
  }

  tags = {
    Name = "${local.name_prefix}-playbook"
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "playbook_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.playbook.function_name}"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-playbook-logs"
  }
}

# SNS Subscription for Lambda
resource "aws_sns_topic_subscription" "playbook_lambda" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.playbook.arn
}

# Lambda Permission for SNS
resource "aws_lambda_permission" "playbook_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.playbook.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

# Output
output "playbook_lambda_arn" {
  description = "Playbook Lambda function ARN"
  value       = aws_lambda_function.playbook.arn
}
