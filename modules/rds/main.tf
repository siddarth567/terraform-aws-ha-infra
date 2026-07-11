################################################################################
# RDS Module — PostgreSQL (Standard RDS for free tier, Aurora for prod)
################################################################################

# ─── Random password for DB master user ──────────────────────────────────────

resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}|:,.<>?"
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.name_prefix}/rds/master-password"
  description             = "Master password for ${var.name_prefix} database"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.environment == "dev" ? 0 : 7

  tags = {
    Name = "${var.name_prefix}-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    engine   = "postgres"
    host     = aws_db_instance.this.address
    port     = 5432
    dbname   = var.database_name
  })
}

# ─── RDS PostgreSQL Instance ─────────────────────────────────────────────────

resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-postgres"
  engine         = "postgres"
  engine_version = var.engine_version

  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"

  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result

  # Networking
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.security_group_id]
  port                   = 5432
  publicly_accessible    = false
  multi_az               = var.environment != "dev"

  # Encryption
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  # Backup & Recovery
  backup_retention_period      = var.backup_retention_period
  backup_window                = "03:00-04:00"
  maintenance_window           = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot        = true
  final_snapshot_identifier    = "${var.name_prefix}-final-snapshot"
  skip_final_snapshot          = var.environment == "dev" ? true : false

  # Protection
  deletion_protection = var.deletion_protection

  # Monitoring
  performance_insights_enabled    = true
  performance_insights_kms_key_id = var.kms_key_arn
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  auto_minor_version_upgrade = true

  tags = {
    Name = "${var.name_prefix}-postgres"
  }

  lifecycle {
    ignore_changes = [password]
  }
}

# ─── Enhanced Monitoring Role ────────────────────────────────────────────────

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
