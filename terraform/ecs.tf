# ── ECS Cluster ───────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"

  tags = { Name = "${var.app_name}-cluster" }
}

# ── Task Definition ───────────────────────────────────────────────────────────

resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name  = var.app_name
    image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.app_name}:latest"

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    essential = true

    healthCheck = {
      command     = ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 15
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = { Name = "${var.app_name}-task" }
}

# ── ECS Service ───────────────────────────────────────────────────────────────

resource "aws_ecs_service" "app" {
  name                              = "${var.app_name}-service"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.app.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  # Ensure the listener, IAM role, and VPC endpoints are all ready before tasks start.
  # Without the endpoints, tasks with no public IP cannot reach ECR or CloudWatch.
  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_execution,
    aws_vpc_endpoint.ecr_api,
    aws_vpc_endpoint.ecr_dkr,
    aws_vpc_endpoint.s3,
    aws_vpc_endpoint.cloudwatch_logs,
  ]

  tags = { Name = "${var.app_name}-service" }
}
