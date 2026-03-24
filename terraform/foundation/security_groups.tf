# =============================================================================
# security_groups.tf
# Baseline security groups
# =============================================================================

# ── Conjur EC2 ─────────────────────────────────────────────────────────────────

resource "aws_security_group" "conjur" {
  name        = "${var.project}-conjur-sg"
  description = "Conjur Enterprise leader node"
  vpc_id      = aws_vpc.main.id

  # SSH — admin access only (your IP)
  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr
  }

  # Conjur HTTPS API + UI (443)
  # Demo audiences access the UI from your IP; app EC2 accesses the API from within VPC
  ingress {
    description = "Conjur HTTPS from admin"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr
  }

  ingress {
    description = "Conjur HTTPS from VPC (app servers, Lambda, ECS)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Conjur also listens on 5432 for follower replication — not needed for single-node demo
  # but left as a comment for when you add followers

  # Unrestricted egress — Conjur needs to pull images, reach AWS APIs for authn-iam
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-conjur-sg" }
}

# ── Application EC2 ────────────────────────────────────────────────────────────
# This is the VM that will host the Flask app in Phase 1.
# For the "hardcoded credentials" demo it's intentionally wide open to HTTP —
# that's the point of the demo. We lock it down with Conjur in the next step.

resource "aws_security_group" "app" {
  name        = "${var.project}-app-sg"
  description = "Application EC2 (Flask demo app)"
  vpc_id      = aws_vpc.main.id

  # SSH from admin only (even in the insecure demo, we don't open SSH to the world)
  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr
  }

  # HTTP — open to admin for demo viewing
  # In Phase 1 we'll put an ALB in front; for now direct access is fine
  ingress {
    description = "HTTP from admin"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-app-sg" }
}

# ── RDS PostgreSQL ─────────────────────────────────────────────────────────────

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "RDS PostgreSQL - only accept connections from app and Conjur"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL from app EC2 — this is what the demo app uses to read data
  ingress {
    description     = "PostgreSQL from app EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # PostgreSQL from Conjur — needed for health checks and future secret rotation
  ingress {
    description     = "PostgreSQL from Conjur"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.conjur.id]
  }

  # No egress needed for RDS (AWS manages this, but explicit is cleaner)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-rds-sg" }
}
