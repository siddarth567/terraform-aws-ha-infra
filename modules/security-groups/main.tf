################################################################################
# Security Groups Module — Chained SGs for Defense in Depth
################################################################################

# ─── ALB Security Group ──────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from anywhere"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from anywhere"
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound"
}

# ─── ECS Tasks Security Group ────────────────────────────────────────────────

resource "aws_security_group" "ecs" {
  name_prefix = "${var.name_prefix}-ecs-"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-ecs-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ecs_ingress_from_alb" {
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs.id
  description              = "Allow traffic from ALB only"
}

resource "aws_security_group_rule" "ecs_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
  description       = "Allow all outbound (ECR, Secrets Manager, etc.)"
}

# ─── RDS Security Group ──────────────────────────────────────────────────────

resource "aws_security_group" "rds" {
  name_prefix = "${var.name_prefix}-rds-"
  description = "Security group for Aurora RDS cluster"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "rds_ingress_from_ecs" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow PostgreSQL from ECS tasks only"
}

resource "aws_security_group_rule" "rds_ingress_from_bastion" {
  count = var.create_bastion_sg ? 1 : 0

  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion[0].id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow PostgreSQL from Bastion host"
}

resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound"
}

# ─── ElastiCache (Redis) Security Group ──────────────────────────────────────

resource "aws_security_group" "redis" {
  name_prefix = "${var.name_prefix}-redis-"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-redis-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "redis_ingress_from_ecs" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = aws_security_group.redis.id
  description              = "Allow Redis from ECS tasks only"
}

resource "aws_security_group_rule" "redis_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redis.id
  description       = "Allow all outbound"
}

# ─── Bastion Security Group ──────────────────────────────────────────────────

resource "aws_security_group" "bastion" {
  count = var.create_bastion_sg ? 1 : 0

  name_prefix = "${var.name_prefix}-bastion-"
  description = "Security group for Bastion host"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-bastion-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "bastion_ingress_ssh" {
  count = var.create_bastion_sg ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_bastion_cidrs
  security_group_id = aws_security_group.bastion[0].id
  description       = "Allow SSH from whitelisted CIDRs"
}

resource "aws_security_group_rule" "bastion_egress" {
  count = var.create_bastion_sg ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion[0].id
  description       = "Allow all outbound"
}
