################################################################################
# Security groups
################################################################################

resource "aws_security_group" "alb" {
  name   = "${var.name}-sg-alb-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.name}-sg-alb-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs_tasks" {
  name   = "${var.name}-sg-task-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = var.container_port
    to_port          = var.container_port
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.name}-sg-task-${var.environment}"
    Environment = var.environment
  }
}

################################################################################
# Route 53
################################################################################

data "aws_route53_zone" "zone" {
  name         = var.dns_zone
  private_zone = false
}

resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.dns_cname
  type    = "CNAME"
  ttl     = "60"
  records = [aws_lb.main.dns_name]
}

################################################################################
# Load balancer
################################################################################

resource "aws_lb" "main" {
  name               = "${var.name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets

  enable_deletion_protection = false
}

resource "aws_alb_target_group" "main" {
  name        = "${var.name}-tg-${var.environment}"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
   healthy_threshold   = "3"
   interval            = "30"
   protocol            = "HTTP"
   matcher             = "200"
   timeout             = "3"
   path                = "/api/ping"
   unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "https" {
    load_balancer_arn = aws_lb.main.id
    port              = 443
    protocol          = "HTTPS"
    certificate_arn   = var.lb_certificate_arn

    default_action {
      target_group_arn = aws_alb_target_group.main.id
      type             = "forward"
    }
}

################################################################################
# ECS
################################################################################

resource "aws_ecs_cluster" "main" {
  name = "${var.name}-cluster-${var.environment}"

  tags = {
    Name        = "${var.name}-sg-task-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.name}-ecs-task-role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.name}-ecs-task-execution-role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "main" {
  name = "/ecs/${var.name}-task-${var.environment}"

  tags = {
    Name        = "${var.name}-task-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.name}-task-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions    = jsonencode([{
   name        = "${var.name}-container-${var.environment}"
   image       = var.container_image
   essential   = true
   portMappings = [{
     protocol      = "tcp"
     containerPort = var.container_port
     hostPort      = var.container_port
   }]
   environment: [
    { name = "TELEMETRY_INFLUXDB_URL", value = var.influxdb_url },
    { name = "TELEMETRY_INFLUXDB_TOKEN", value = var.influxdb_token }, # TODO: This should go as secret
    { name = "TELEMETRY_INFLUXDB_ORG", value = var.influxdb_org },
    { name = "TELEMETRY_INFLUXDB_BUCKET", value = var.influxdb_bucket },
    { name = "TELEMETRY_DB_HOST", value = var.database_address },
    { name = "TELEMETRY_DB_PORT", value = var.database_port },
    { name = "TELEMETRY_DB_USER", value = var.database_user },
    { name = "TELEMETRY_DB_PASSWORD", value = var.database_password },
    { name = "TELEMETRY_DB_NAME", value = var.database_name }
   ]
   logConfiguration = {
     logDriver = "awslogs"
     options = {
       awslogs-group         = aws_cloudwatch_log_group.main.name
       awslogs-stream-prefix = "ecs"
       awslogs-region        = var.region
     }
   }
  }])

  tags = {
    Name        = "${var.name}-sg-task-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "main" {
  name            = "${var.name}-ecs-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn

  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.id
    container_name   = "${var.name}-container-${var.environment}"
    container_port   = var.container_port
  }

  lifecycle {
   ignore_changes = [task_definition, desired_count]
 }
}
