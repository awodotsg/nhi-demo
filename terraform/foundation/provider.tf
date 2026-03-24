# =============================================================================
# provider.tf
# Terraform version constraints, AWS provider, and S3 remote state backend.
#
# BEFORE running terraform init:
#   1. Run scripts/bootstrap-state.sh
# =============================================================================

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ── Remote State Backend ───────────────────────────────────────────────────
  # The bucket is created by scripts/bootstrap-state.sh
  # You cannot use variables here — these must be literal strings.
  backend "s3" {
    bucket         = "awodotsg-nhi-demo-tfstate-staging"  
    key            = "foundation/terraform.tfstate"
    region         = "ap-southeast-1"                     # ← match your AWS_REGION
    use_lockfile   = true
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  # Applied to every resource created by this provider — no need to repeat tags
  default_tags {
    tags = {
      Project     = "nhi-demo"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
