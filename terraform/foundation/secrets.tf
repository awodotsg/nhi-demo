# =============================================================================
# secrets.tf
# Used to reference secrets onboarded on AWS Secrets Manager
# =============================================================================

data "aws_secretsmanager_secret" "db_password" {
    name = var.db_password_secret
}

data "aws_secretsmanager_secret_version" "db_password" {
    secret_id = data.aws_secretsmanager_secret.db_password.id
}

locals {
    db_password = data.aws_secretsmanager_secret_version.db_password.secret_string
}