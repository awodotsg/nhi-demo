# =============================================================================
# variables.tf
# All inputs for the foundation layer.
# Override via terraform.tfvars or -var flags.
# =============================================================================

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name — used in tags and resource names"
  type        = string
  default     = "staging"
}

variable "project" {
  description = "Project name prefix for all resource names"
  type        = string
  default     = "nhi-demo"
}

# ── Networking ─────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.22.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.22.1.0/24", "10.22.2.0/24", "10.22.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.22.10.0/24", "10.22.20.0/24", "10.22.30.0/24"]
}

variable "availability_zones" {
  description = "AZs to deploy subnets into — must match region"
  type        = list(string)
  default     = ["ap-southeast-1a","ap-southeast-1b", "ap-southeast-1c"]
}

# ── Access Control ─────────────────────────────────────────────────────────────

variable "admin_cidr" {
  description = "Your IP in CIDR notation — used to restrict SSH and Conjur UI access"
  type        = list(string)
  # No default — you MUST set this in terraform.tfvars
  # Example: ["1.2.3.4/32","5.6.7.8/32"]
}

# ── DNS ────────────────────────────────────────────────────────────────────────

variable "route53_zone_name" {
  description = "Your Route53 hosted zone name (e.g. example.com.)"
  type        = string  
}

variable "conjur_subdomain" {
  description = "Subdomain for Conjur (e.g. conjur → conjur.example.com)"
  type        = string
  default     = "conjur"
}

# ── RDS ────────────────────────────────────────────────────────────────────────

variable "db_name" {
  description = "Name of the demo PostgreSQL database"
  type        = string
  default     = "nhidemo"
}

variable "db_username" {
  description = "Master username for RDS — Conjur will manage the password"
  type        = string
  default     = "demouser"
}

variable "db_password_secret" {
  description = "Secret for RDS master password on AWSSM"
  type        = string
  default     = "nhi-demo/staging/db-password"
}

variable "db_instance_class" {
  description = "RDS instance size — db.t3.micro is free-tier eligible"
  type        = string
  default     = "db.t3.micro"
}

# ── EC2 ────────────────────────────────────────────────────────────────────────

variable "conjur_instance_type" {
  description = "EC2 instance type for Conjur Enterprise — needs reasonable memory"
  type        = string
  default     = "m6i.large"  # https://docs.cyberark.com/secrets-manager-sh/latest/en/content/deployment/platforms/dap-sysreqs-server.htm
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
  default     = "nhi-staging-key"
}
