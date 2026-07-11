################################################################################
# VPC Module — Multi-AZ VPC with Public, Private, and Database Subnets
################################################################################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

################################################################################
# Subnets
################################################################################

# Public Subnets (ALB, NAT Gateways, Bastion)
resource "aws_subnet" "public" {
  count = length(var.azs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-${var.azs[count.index]}"
    Tier = "public"
  }
}

# Private Subnets (ECS, Application workloads)
resource "aws_subnet" "private" {
  count = length(var.azs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.name_prefix}-private-${var.azs[count.index]}"
    Tier = "private"
  }
}

# Database Subnets (RDS, ElastiCache — no internet access)
resource "aws_subnet" "database" {
  count = length(var.azs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.name_prefix}-database-${var.azs[count.index]}"
    Tier = "database"
  }
}

################################################################################
# NAT Gateways (with Elastic IPs)
################################################################################

resource "aws_eip" "nat" {
  count  = var.nat_gateway_count
  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-nat-eip-${count.index}"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = var.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.name_prefix}-nat-${count.index}"
  }

  depends_on = [aws_internet_gateway.this]
}

################################################################################
# Route Tables
################################################################################

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.azs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (one per AZ for HA, or shared for cost savings)
resource "aws_route_table" "private" {
  count = var.nat_gateway_count

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = {
    Name = "${var.name_prefix}-private-rt-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.azs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index % var.nat_gateway_count].id
}

# Database Route Table (no internet route)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-database-rt"
  }
}

resource "aws_route_table_association" "database" {
  count = length(var.azs)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

################################################################################
# Database Subnet Group
################################################################################

resource "aws_db_subnet_group" "this" {
  name        = "${var.name_prefix}-db-subnet-group"
  description = "Database subnet group for ${var.name_prefix}"
  subnet_ids  = aws_subnet.database[*].id

  tags = {
    Name = "${var.name_prefix}-db-subnet-group"
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name        = "${var.name_prefix}-redis-subnet-group"
  description = "ElastiCache subnet group for ${var.name_prefix}"
  subnet_ids  = aws_subnet.database[*].id

  tags = {
    Name = "${var.name_prefix}-redis-subnet-group"
  }
}

################################################################################
# VPC Flow Logs
################################################################################

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  iam_role_arn             = var.flow_log_role_arn
  log_destination          = aws_cloudwatch_log_group.flow_logs[0].arn
  max_aggregation_interval = 60

  tags = {
    Name = "${var.name_prefix}-flow-logs"
  }
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/flow-logs/${var.name_prefix}"
  retention_in_days = var.flow_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = {
    Name = "${var.name_prefix}-flow-logs"
  }

  lifecycle {
    ignore_changes = [name]
  }
}

################################################################################
# Network ACLs — Defense in depth
################################################################################

# Public subnet NACL
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.public[*].id

  # Allow inbound HTTP
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Allow inbound HTTPS
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow inbound SSH (from allowed CIDRs — bastion)
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # Allow inbound ephemeral ports (return traffic)
  ingress {
    rule_no    = 140
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.name_prefix}-public-nacl"
  }
}

# Private subnet NACL
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.private[*].id

  # Allow inbound from VPC CIDR
  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  # Allow inbound ephemeral ports (return traffic from NAT)
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.name_prefix}-private-nacl"
  }
}

# Database subnet NACL
resource "aws_network_acl" "database" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.database[*].id

  # Allow inbound from private subnets only (PostgreSQL)
  dynamic "ingress" {
    for_each = aws_subnet.private[*].cidr_block
    content {
      rule_no    = 100 + ingress.key
      protocol   = "tcp"
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 5432
      to_port    = 5432
    }
  }

  # Allow inbound from private subnets only (Redis)
  dynamic "ingress" {
    for_each = aws_subnet.private[*].cidr_block
    content {
      rule_no    = 200 + ingress.key
      protocol   = "tcp"
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 6379
      to_port    = 6379
    }
  }

  # Allow return traffic to private subnets
  dynamic "egress" {
    for_each = aws_subnet.private[*].cidr_block
    content {
      rule_no    = 100 + egress.key
      protocol   = "tcp"
      action     = "allow"
      cidr_block = egress.value
      from_port  = 1024
      to_port    = 65535
    }
  }

  tags = {
    Name = "${var.name_prefix}-database-nacl"
  }
}
