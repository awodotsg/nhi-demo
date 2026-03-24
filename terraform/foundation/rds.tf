# =============================================================================
# rds.tf
# RDS PostgreSQL — the resource being "protected" in every demo phase.
# =============================================================================

# ── Subnet Group ───────────────────────────────────────────────────────────────
# RDS requires a subnet group with subnets in at least 2 AZs

resource "aws_db_subnet_group" "main" {
  name        = "${var.project}-db-subnet-group"
  description = "Subnet group for ${var.project} RDS"
  subnet_ids  = aws_subnet.private[*].id

  tags = { Name = "${var.project}-db-subnet-group" }
}

# ── Parameter Group ────────────────────────────────────────────────────────────
# Using a custom parameter group (rather than default) gives you control
# over PostgreSQL settings and is required if you want to enable logical
# replication later (useful for the CPM rotation demo).

resource "aws_db_parameter_group" "main" {
  name        = "${var.project}-pg17"
  description = "PostgreSQL 17 parameters for ${var.project}"
  family      = "postgres17"

  parameter {
    name  = "log_connections"
    value = "1"  # Log every connection — visible in CloudWatch, good for the demo
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = { Name = "${var.project}-pg17-params" }
}

# ── RDS Instance ───────────────────────────────────────────────────────────────

resource "aws_db_instance" "main" {
  identifier = "${var.project}-postgres"

  # Engine
  engine         = "postgres"
  engine_version = "17.6"
  instance_class = var.db_instance_class

  # Storage — gp2 is fine for demo, no need for provisioned IOPS
  allocated_storage     = 20
  max_allocated_storage = 50   # Enable autoscaling up to 50GB
  storage_type          = "gp2"
  storage_encrypted     = true  # Always encrypt at rest

  # Credentials — these are the credentials Conjur will eventually manage
  db_name  = var.db_name
  username = var.db_username
  password = local.db_password  # Set in terraform.tfvars, never committed

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false  # Private subnet only — never expose RDS publicly

  # Config
  parameter_group_name = aws_db_parameter_group.main.name
  multi_az             = false    # Single-AZ is fine for demo; saves cost

  # Backups — minimal retention for demo, increase for anything production-like
  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Deletion protection off so we can tear down cleanly after demos
  deletion_protection       = false
  skip_final_snapshot       = true
  delete_automated_backups  = true

  tags = { Name = "${var.project}-postgres" }
}
