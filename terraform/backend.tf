# Terraform Remote State Backend Configuration
# Bucket created by terraform-bootstrap

terraform {
  backend "s3" {
    bucket  = "devops-agent-demo-tfstate-851725505881"
    key     = "devops-agent/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
