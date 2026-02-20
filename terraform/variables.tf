variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devops-agent-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"] # Two AZs required for ALB
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 3000
}

variable "container_cpu" {
  description = "Container CPU units"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Container memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1 # Single task for cost optimization
}

variable "github_repo" {
  description = "GitHub repository (owner/repo)"
  type        = string
  default     = "VanshShah174/AWS-Devops-Agent"
}

# ARN of an existing ACM certificate for the ALB. When empty the
# listener remains HTTP-only (useful for local/dev).  You can request a
# certificate in the console and paste the ARN here or through env var.
variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (optional)"
  type        = string
  default     = ""
}

# If you already have a WAFv2 WebACL you can supply its ARN to attach
# it to the ALB.  Leave empty to skip.
variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN to associate with the ALB (optional)"
  type        = string
  default     = ""
}
