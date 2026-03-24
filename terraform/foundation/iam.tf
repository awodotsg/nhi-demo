# =============================================================================
# iam.tf
# IAM roles and instance profiles for EC2 instances.
# =============================================================================

# ── Conjur EC2 Role ────────────────────────────────────────────────────────────

resource "aws_iam_role" "conjur" {
  name        = "${var.project}-conjur-role"
  description = "Role for the Conjur Enterprise EC2 instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Conjur needs to call STS to verify incoming authn-iam requests from app workloads
resource "aws_iam_role_policy" "conjur_sts" {
  name = "${var.project}-conjur-sts-policy"
  role = aws_iam_role.conjur.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSTSForAuthnIAM"
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"  # Conjur uses this to verify app identity
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "conjur" {
  name = "${var.project}-conjur-profile"
  role = aws_iam_role.conjur.name
}

# ── Application EC2 Role ───────────────────────────────────────────────────────

resource "aws_iam_role" "app" {
  name        = "${var.project}-app-role"
  description = "Role for app EC2 - used by Conjur authn-iam to authenticate the workload"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# App needs STS to sign its own identity for Conjur authn-iam
resource "aws_iam_role_policy" "app_sts" {
  name = "${var.project}-app-sts-policy"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSTSSelfIdentity"
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

# SSM Session Manager — allows shell access without opening SSH to the world.
# Useful as a backup access method and good security practice.
resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project}-app-profile"
  role = aws_iam_role.app.name
}

# ── EC2 Key Pair ───────────────────────────────────────────────────────────────
# Generates a key pair and stores the private key in SSM Parameter Store.
# This avoids committing private keys to the repo.

resource "aws_key_pair" "main" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.main.public_key_openssh

  tags = { Name = "${var.project}-keypair" }
}

resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private key in SSM — retrieve with:
# # aws ssm get-parameter --name /nhi-demo/staging/ssh-private-key --with-decryption --query Parameter.Value --output text
resource "aws_ssm_parameter" "ssh_private_key" {
  name        = "/${var.project}/${var.environment}/ssh-private-key"
  description = "EC2 SSH private key for ${var.project}/${var.environment}"
  type        = "SecureString"
  value       = tls_private_key.main.private_key_pem

  tags = { Name = "${var.project}/${var.environment}/-ssh-key" }
}