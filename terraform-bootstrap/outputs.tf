output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "backend_config" {
  description = "Backend configuration to use in main Terraform"
  value = <<-EOT
    terraform {
      backend "s3" {
        bucket  = "${aws_s3_bucket.terraform_state.id}"
        key     = "devops-agent/terraform.tfstate"
        region  = "${var.aws_region}"
        encrypt = true
      }
    }
  EOT
}
