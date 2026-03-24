# =============================================================================
# outputs.tf
# Foundation layer outputs.
# These are consumed by:
#   - Later Terraform layers (via remote state data source)
#   - Ansible inventory (via terraform output -json)
# =============================================================================

# ── Networking ─────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID — used by all subsequent Terraform layers"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs — used for app EC2, RDS, ECS"
  value       = aws_subnet.private[*].id
}

# ── Security Groups ────────────────────────────────────────────────────────────

output "conjur_sg_id" {
  description = "Conjur EC2 security group ID"
  value       = aws_security_group.conjur.id
}

output "app_sg_id" {
  description = "App EC2 security group ID"
  value       = aws_security_group.app.id
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

# ── Conjur EC2 ─────────────────────────────────────────────────────────────────

output "conjur_public_ip" {
  description = "Conjur EC2 public IP (EIP) — use for SSH and DNS"
  value       = aws_eip.conjur.public_ip
}

output "conjur_fqdn" {
  description = "Fully qualified domain name for Conjur"
  value       = "${var.conjur_subdomain}.${var.route53_zone_name}"
}

output "conjur_instance_id" {
  description = "Conjur EC2 instance ID — for SSM Session Manager access"
  value       = aws_instance.conjur.id
}

# ── RDS ────────────────────────────────────────────────────────────────────────

output "rds_endpoint" {
  description = "RDS connection endpoint (host:port) — used in app config"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_hostname" {
  description = "RDS hostname only (no port)"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "rds_db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

# ── IAM ────────────────────────────────────────────────────────────────────────

output "app_instance_profile_name" {
  description = "IAM instance profile name for app EC2 (used in Phase 1)"
  value       = aws_iam_instance_profile.app.name
}

output "app_role_arn" {
  description = "IAM role ARN for app EC2 — registered in Conjur authn-iam policy"
  value       = aws_iam_role.app.arn
}

# ── Key Pair ───────────────────────────────────────────────────────────────────

output "key_pair_name" {
  description = "EC2 key pair name"
  value       = aws_key_pair.main.key_name
}

output "ssh_private_key_ssm_path" {
  description = "SSM path to retrieve the SSH private key"
  value       = aws_ssm_parameter.ssh_private_key.name
}
