data "aws_rds_engine_version" "mysql" {
  engine             = var.engine
  preferred_versions = var.engine_version != "" ? [var.engine_version] : null
  latest             = var.engine_version == "" ? true : false
}

resource "random_password" "rds" {
  count  = var.password == "" ? 1 : 0
  length = 24
  special   = false
}

locals {
  password = var.password != "" ? var.password : random_password.rds[0].result
}

resource "random_id" "snapshot_suffix" {
  byte_length = 4
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-${var.identifier}-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.identifier}-subnet-group"
    Environment = var.environment
  })
}

resource "aws_db_parameter_group" "main" {
  name   = "${var.environment}-${var.identifier}-params"
  family = data.aws_rds_engine_version.mysql.parameter_group_family

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.identifier}-params"
    Environment = var.environment
  })
}

resource "aws_db_instance" "main" {
  identifier = "${var.environment}-${var.identifier}"
  engine         = data.aws_rds_engine_version.mysql.engine
  engine_version = data.aws_rds_engine_version.mysql.version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = var.storage_encrypted

  db_name  = var.db_name
  username = var.username
  password = local.password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  parameter_group_name   = aws_db_parameter_group.main.name
  publicly_accessible    = var.publicly_accessible

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot   = true
  skip_final_snapshot     = false
  final_snapshot_identifier = "${var.environment}-${var.identifier}-final-snapshot-${random_id.snapshot_suffix.hex}"

  deletion_protection = var.deletion_protection
  multi_az            = var.multi_az

  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced[0].arn : null

  auto_minor_version_upgrade = true

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
    ]
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.identifier}"
    Environment = var.environment
  })
}

resource "aws_iam_role" "rds_enhanced" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${var.environment}-rds-enhanced-monitoring"

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
}

resource "aws_iam_role_policy_attachment" "rds_enhanced" {
  count = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_enhanced[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_secretsmanager_secret" "rds" {
  name = "${var.environment}-${var.identifier}-password"

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.identifier}-password"
    Environment = var.environment
  })
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = var.username
    password = local.password
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    db_name  = var.db_name
  })
}
