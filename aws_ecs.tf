####################################################
# ECS IAM Role
####################################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name                = "ecs_task_execution_role"
  assume_role_policy  = jsonencode({
    Version           = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
   managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
}

resource "aws_iam_role_policy" "kms_decrypt_policy" {
  name = "ecs_task_execution_role_policy_kms"
  role = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Action": [
          "kms:Decrypt"
        ],
        "Resource": ["*"]
      }
    ]
  })
}

####################################################
# ECS cluster
####################################################
resource "aws_ecs_cluster" "service" {
  name = "service"
}

####################################################
# service
####################################################
resource "aws_ecs_task_definition" "frontend" {
  family                    = "frontend"
  cpu                       = 512
  memory                    = 1024
  network_mode              = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  execution_role_arn        = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn             = aws_iam_role.ecs_task_execution_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  container_definitions = <<EOL
  [
    {
      "name": "nextjs",
      "image": "234660340542.dkr.ecr.ap-northeast-1.amazonaws.com/next_app:latest",
      "cpu": 512,
      "memory": 1024,
      "essential": true,
      "network_mode": "awsvpc",
      "portMappings": [{"containerPort": 3000}],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "ap-northeast-1",
          "awslogs-stream-prefix": "nextjs",
          "awslogs-group": "/ecs/nextjs"
        }
      },
      "environment": [
        {
          "name": "NEXT_PUBLIC_END_POINT",
          "value": "https://command-style.com/query"
        }
      ]
    }
  ]
  EOL
}

resource "aws_ecs_task_definition" "api" {
  family                    = "api"
  cpu                       = 2048
  memory                    = 4096
  network_mode              = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  execution_role_arn        = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn             = aws_iam_role.ecs_task_execution_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  container_definitions = <<EOL
  [
    {
      "name": "api",
      "image": "234660340542.dkr.ecr.ap-northeast-1.amazonaws.com/go_api:latest",
      "cpu": 512,
      "memory": 1024,
      "essential": true,
      "network_mode": "awsvpc",
      "portMappings": [{"containerPort": 8080}],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "ap-northeast-1",
          "awslogs-stream-prefix": "api",
          "awslogs-group": "/ecs/api"
        }
      },
      "environment": [
        {
          "name": "DB_SOURCE",
          "value": "postgresql://root:secret@localhost:5432/command_style?sslmode=disable"
        }
      ]
    },
    {
      "name": "postgres",
      "image": "234660340542.dkr.ecr.ap-northeast-1.amazonaws.com/postgres:latest",
      "cpu": 512,
      "memory": 1024,
      "essential": false,
      "network_mode": "awsvpc",
      "portMappings": [{"containerPort": 5432}],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "ap-northeast-1",
          "awslogs-stream-prefix": "postgres",
          "awslogs-group": "/ecs/postgres"
        }
      },
      "environment": [
        {
          "name": "POSTGRES_DB",
          "value": "command-style"
        },
        {
          "name": "POSTGRES_USER",
          "value": "root"
        },
        {
          "name": "POSTGRES_PASSWORD",
          "value": "secret"
        },
        {
          "name": "POSTGRES_URL",
          "value": "postgresql://root:secret@127.0.0.1:5432/command_style?sslmode=disable"
        }
      ]
    },
    {
      "name": "redis",
      "image": "redis",
      "cpu": 512,
      "memory": 1024,
      "essential": false,
      "network_mode": "awsvpc",
      "portMappings": [{"containerPort": 6379}],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "ap-northeast-1",
          "awslogs-stream-prefix": "redis",
          "awslogs-group": "/ecs/redis"
        }
      }
    }
  ]
  EOL
}

####################################################
# ALB -> frontend
####################################################
resource "aws_ecs_service" "frontend" {
  name = "frontend"
  cluster = aws_ecs_cluster.service.name
  launch_type = "FARGATE"
  desired_count = 1
  task_definition = aws_ecs_task_definition.frontend.arn
  network_configuration {
    subnets = [aws_subnet.public_1a.id]
    security_groups = [aws_security_group.app.id]
    # ECR S3 bucket get
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "nextjs"
    container_port   = "3000"
  }
}

resource "aws_lb_target_group" "frontend" {
  name_prefix = "alb"
  vpc_id = aws_vpc.this.id
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  health_check {
    port = 3000
    path = "/"
  }
  lifecycle {
    create_before_destroy = true
  }
  stickiness {
    type = "app_cookie"
    cookie_name = "cookey"
    enabled = true
  }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.https.arn
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
  condition {
    path_pattern {
      values = [
        "/",
        "/login",
        "/signup",
        "/manage"
      ]
    }
  }
}

####################################################
# ALB -> api
####################################################
resource "aws_ecs_service" "api" {
  name = "api"
  cluster = aws_ecs_cluster.service.name
  launch_type = "FARGATE"
  desired_count = 1
  task_definition = aws_ecs_task_definition.api.arn
  network_configuration {
    subnets = [aws_subnet.public_1a.id]
    security_groups = [aws_security_group.app.id]
    # ECR S3 bucket get
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8080
  }
}

resource "aws_lb_target_group" "api" {
  name_prefix = "alb"
  vpc_id = aws_vpc.this.id
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  health_check {
    port = 8080
    path = "/api/health_check"
  }
  lifecycle {
    create_before_destroy = true
  }
  stickiness {
    type = "app_cookie"
    cookie_name = "cookey"
    enabled = true
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
  condition {
    path_pattern {
      values = [
        "/query",
        "/admin/query"
      ]
    }
  }
}
