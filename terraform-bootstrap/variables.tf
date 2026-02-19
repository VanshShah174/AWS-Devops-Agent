variable "aws_region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_prefix" {
  description = "Prefix for the state bucket name"
  type        = string
  default     = "devops-agent-demo-tfstate"
}
