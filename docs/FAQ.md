# Frequently Asked Questions (FAQ)

## General Questions

### What is this project?

This is a comprehensive demonstration of AWS DevOps Agent capabilities for incident response and monitoring. It includes a complete containerized application on ECS with intentional error scenarios for testing.

### Who is this for?

- DevOps engineers learning AWS DevOps Agent
- Teams evaluating AWS monitoring solutions
- Developers wanting to understand ECS and Fargate
- Anyone interested in observability and incident response

### What does it cost?

Approximately $56-120/month depending on configuration:
- Minimum (1 AZ, 1 task): ~$56/month
- Standard (2 AZ, 2 tasks): ~$120/month

Remember to destroy resources when not in use!

### How long does setup take?

- Infrastructure deployment: 10-15 minutes
- Application deployment: 5 minutes
- Total: ~20 minutes

## Prerequisites

### Do I need an AWS account?

Yes, you need an AWS account with administrative access to create resources.

### What tools do I need installed?

Required:
- AWS CLI v2.x
- Terraform v1.0+
- Docker v20.x+
- Git

Optional:
- Node.js 18+ (for local development)
- jq (for JSON parsing in scripts)

### Can I use this on Windows?

Yes! The project includes:
- PowerShell scripts for Windows users
- Cross-platform Terraform code
- Docker Desktop for Windows support

Use `trigger-incidents.ps1` instead of `trigger-incidents.sh`.

### Do I need GitHub Actions?

No, GitHub Actions is optional. You can:
- Deploy manually with Terraform and Docker
- Use any CI/CD tool
- Skip CI/CD entirely for testing

## Deployment

### Why is deployment taking so long?

Infrastructure deployment (10-15 minutes) includes:
- VPC and networking setup
- NAT Gateways (slow to create)
- ECS cluster initialization
- Load balancer provisioning

This is normal for AWS infrastructure.

### Can I deploy to a different region?

Yes! Edit `terraform/terraform.tfvars`:
```hcl
aws_region = "us-west-2"
```

Then run `terraform apply`.

### Can I use an existing VPC?

Yes, but you'll need to modify the Terraform code to:
- Remove VPC creation
- Reference existing VPC ID
- Use existing subnets
- Update security groups

### How do I reduce costs?

1. Use single AZ:
   ```hcl
   availability_zones = ["us-east-1a"]
   ```

2. Reduce task count:
   ```hcl
   desired_count = 1
   ```

3. Use Fargate Spot:
   ```hcl
   capacity_providers = ["FARGATE_SPOT"]
   ```

4. Destroy when not in use:
   ```bash
   make destroy
   ```

## Application

### Why Node.js?

Node.js was chosen for:
- Lightweight containers
- Easy to understand code
- Good Prometheus client
- Fast startup time

You can replace it with any language.

### Can I modify the application?

Absolutely! The application is designed to be customized:
- Add new endpoints
- Change error scenarios
- Add business logic
- Integrate with databases

### How do I add a database?

You'll need to:
1. Add RDS or DynamoDB to Terraform
2. Update security groups
3. Add connection code to application
4. Update environment variables

See `docs/ARCHITECTURE.md` for guidance.

### Can I use this in production?

This is a demo project. For production:
- Add authentication
- Implement rate limiting
- Remove error testing endpoints
- Add proper error handling
- Implement secrets management
- Add comprehensive tests
- Configure CORS properly

## Monitoring

### Why aren't alarms triggering?

Common reasons:
- Not enough load (try `make test-all`)
- Evaluation periods not met (wait 2-5 minutes)
- Thresholds too high (check alarm configuration)
- Metrics not published (verify in CloudWatch)

### How do I view logs?

```bash
# Real-time
make logs

# Or directly
aws logs tail /ecs/devops-agent-demo-dev --follow

# Filter for errors
aws logs filter-log-events \
  --log-group-name /ecs/devops-agent-demo-dev \
  --filter-pattern "ERROR"
```

### Can I add custom metrics?

Yes! Edit `app/src/index.js`:

```javascript
const customMetric = new promClient.Counter({
  name: 'custom_business_metric',
  help: 'Custom business metric',
  registers: [register]
});

app.get('/business-event', (req, res) => {
  customMetric.inc();
  res.json({ success: true });
});
```

### How do I set up email alerts?

Uncomment in `terraform/cloudwatch.tf`:

```hcl
resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"
}
```

Then run `terraform apply`.

## DevOps Agent

### What is AWS DevOps Agent?

AWS DevOps Agent is a service that:
- Automatically investigates incidents
- Analyzes logs and metrics
- Correlates with code changes
- Provides root cause analysis

### How do I access DevOps Agent?

1. Open AWS Console
2. Navigate to DevOps Agent service
3. Find your Agent Space
4. View investigations

### Why isn't DevOps Agent creating investigations?

Check:
- Agent Space is configured (`make setup-agent`)
- Alarms are triggering
- IAM permissions are correct
- CloudWatch integration is enabled

### Can I integrate with GitHub?

Yes! Set in `terraform/terraform.tfvars`:

```hcl
github_repo = "your-username/your-repo"
```

This enables deployment correlation.

## Testing

### How do I trigger incidents?

Use the provided scripts:

```bash
# Bash (Linux/Mac)
./scripts/trigger-incidents.sh error-spike

# PowerShell (Windows)
.\scripts\trigger-incidents.ps1 -Scenario error-spike

# Or use Make
make test-error-spike
```

### What scenarios are available?

1. **error-spike**: Multiple 500 errors
2. **memory-leak**: Memory exhaustion
3. **cpu-spike**: CPU saturation
4. **health-failure**: Failed health checks
5. **timeout**: Slow responses

### How do I restore after testing?

```bash
make cleanup
```

Or manually:
```bash
curl $(make url)/error/enable-health
curl $(make url)/error/clear-memory
```

### Can I run load tests?

Yes! Use Apache Bench:

```bash
ab -n 1000 -c 10 $(make url)/
```

Or any load testing tool (JMeter, Locust, k6).

## Troubleshooting

### Tasks keep restarting

Check:
- Container logs: `make logs`
- Task definition: CPU/memory limits
- Health check configuration
- Application errors

### Can't access application

Verify:
- ALB is active
- Security groups allow traffic
- Tasks are healthy
- DNS is resolving

```bash
make status
```

### Terraform errors

Common issues:
- AWS credentials not configured
- Insufficient permissions
- Resource limits exceeded
- State file locked

Try:
```bash
terraform refresh
terraform plan
```

### High AWS costs

Check:
- NAT Gateways (most expensive)
- Running tasks
- Load balancer
- CloudWatch logs

Use AWS Cost Explorer to identify costs.

### Docker build fails

Ensure:
- Docker is running
- Sufficient disk space
- Network connectivity
- Valid Dockerfile syntax

### ECR push fails

Check:
- AWS credentials
- ECR repository exists
- Logged in to ECR
- Image tagged correctly

```bash
aws ecr get-login-password | docker login --username AWS --password-stdin <ECR_URL>
```

## Advanced

### Can I use multiple environments?

Yes! Create separate tfvars files:

```bash
# Dev
terraform apply -var-file=dev.tfvars

# Prod
terraform apply -var-file=prod.tfvars
```

### How do I implement blue-green deployment?

Modify `terraform/ecs.tf`:

```hcl
deployment_configuration {
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}
```

ECS supports blue-green natively.

### Can I add auto-scaling?

Yes! Add to `terraform/ecs.tf`:

```hcl
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
```

### How do I add HTTPS?

1. Get SSL certificate (ACM)
2. Add HTTPS listener to ALB
3. Update security groups
4. Redirect HTTP to HTTPS

See AWS documentation for details.

### Can I use this with Kubernetes?

The application can run on Kubernetes, but you'll need to:
- Create Kubernetes manifests
- Replace ECS-specific code
- Update monitoring configuration
- Modify deployment scripts

### How do I backup data?

This is a stateless application, but for production:
- Backup Terraform state (S3 backend)
- Export CloudWatch logs
- Backup container images (ECR)
- Document configuration

## Support

### Where can I get help?

1. Check documentation in `docs/`
2. Review CloudWatch logs
3. Run validation script: `./scripts/validate-setup.sh`
4. Check GitHub Issues
5. Review AWS documentation

### How do I report bugs?

1. Check existing GitHub Issues
2. Gather information:
   - Error messages
   - CloudWatch logs
   - Terraform output
   - Steps to reproduce
3. Create detailed issue

### Can I contribute?

Yes! Contributions welcome:
- Bug fixes
- New features
- Documentation improvements
- Additional test scenarios

### Is this production-ready?

No, this is a demo project. For production:
- Add comprehensive tests
- Implement security best practices
- Add proper error handling
- Configure monitoring alerts
- Set up backup and recovery
- Add authentication/authorization
- Implement rate limiting
- Review and harden configuration

## Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Express.js Guide](https://expressjs.com/en/guide/routing.html)
- [Prometheus Metrics](https://prometheus.io/docs/concepts/metric_types/)
- [CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)

---

**Didn't find your answer?** Check the other documentation files or create a GitHub Issue!
