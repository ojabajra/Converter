# ── VPC Endpoints ─────────────────────────────────────────────────────────────
# Allows Fargate tasks to reach ECR and CloudWatch without a public IP or NAT Gateway.
# Traffic to these services stays entirely within the AWS network.

# ── Endpoint Security Group ───────────────────────────────────────────────────

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.app_name}-vpce-sg"
  description = "Allow HTTPS from ECS tasks to VPC interface endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTPS from ECS tasks"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_name}-vpce-sg" }
}

# ── ECR API Endpoint ──────────────────────────────────────────────────────────

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = { Name = "${var.app_name}-vpce-ecr-api" }
}

# ── ECR Docker Endpoint ───────────────────────────────────────────────────────

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = { Name = "${var.app_name}-vpce-ecr-dkr" }
}

# ── S3 Gateway Endpoint ───────────────────────────────────────────────────────
# ECR stores image layers in S3; without this endpoint, layer pulls would attempt
# to route through the internet gateway, which fails when tasks have no public IP.

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = { Name = "${var.app_name}-vpce-s3" }
}

# ── CloudWatch Logs Endpoint ──────────────────────────────────────────────────

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = { Name = "${var.app_name}-vpce-logs" }
}
