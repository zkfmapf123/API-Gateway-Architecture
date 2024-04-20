#############################################################################
## ALB 
#############################################################################
resource "aws_security_group" "alb_sg" {
  name        = "ecs_server_alb_sg"
  description = "ecs server alb to sg"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs_server_sg"
  }
}

resource "aws_lb" "ecs_alb" {
  name               = "ecs-sever-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = values(local.webserver_subnets)

  enable_deletion_protection = false

  tags = {
    Name = "ecs_server_alb"
  }
}

#############################################################################
## ALB Target Group
#############################################################################
resource "aws_lb_target_group" "ecs_tg_server" {
  name                 = "ecs-server-tg"
  port                 = 3000 ## ECS Port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = local.vpc_id
  deregistration_delay = 10 // 이거때문에 배포시간 늦어짐 ... Default 300 적절하게 수정

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "3000"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }
}

#############################################################################
## ALB Listener
#############################################################################
resource "aws_lb_listener" "ecs_80" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg_server.arn
  }
}

#############################################################################
## ECR Repository
#############################################################################
resource "aws_ecr_repository" "server_ecr" {
  name = "ecs-server-repo"
}


resource "aws_ecs_task_definition" "ecs_server_task_def" {
  family = "ecs-server-container-family"

  cpu    = 256
  memory = 512

  container_definitions = jsonencode([
    {
      name      = "ecs-server-container"
      image     = "${aws_ecr_repository.server_ecr.repository_url}:2"
      cpu       = 256
      memory    = 512
      essential = true,

      environment = [
        {
          name  = "PORT",
          value = "3000"
        }
      ],
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        },
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "server-container"
          awslogs-create-group  = "true"
          awslogs-region        = "ap-northeast-2"
          awslogs-stream-prefix = "ecs"
        }
      }
  }])

  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc" ## Only FARGATE
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}

resource "aws_security_group" "ecs_server_sg" {
  name        = "ecs_server_sg"
  description = "ecs to sg"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs_server_sg"
  }
}

resource "aws_ecs_service" "ecs_service" {
  launch_type            = "FARGATE"
  name                   = "ecs-server-container"
  cluster                = aws_ecs_cluster.ecs_cluster.id
  task_definition        = aws_ecs_task_definition.ecs_server_task_def.arn
  desired_count          = 1
  enable_execute_command = true

  network_configuration {
    assign_public_ip = false
    subnets          = values(local.was_subnets)
    security_groups  = [aws_security_group.ecs_server_sg.id]
  }

  force_new_deployment = false

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg_server.arn
    container_name   = "ecs-server-container"
    container_port   = "3000"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_iam_role.ecs_task_role]
}

data "aws_iam_policy" "ecs_task_execution" {
  for_each = toset(["AmazonECSTaskExecutionRolePolicy", "AWSCodeDeployFullAccess", "AWSCodeDeployRoleForECS"])
  name     = each.value
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "ecs_task_policy" {
  name = "ecs-execution-list"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:Describe*",
          "ecs:List*",
          "ecs:RunTask",
          "ecs:StopTask",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:CreateLogGroup", ## Log Group...
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ]
        Effect = "Allow"
        Resource = [
          "*"
        ]
      },
      {
        "Effect" : "Allow",
        "Resource" : "*",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attach" {
  for_each = data.aws_iam_policy.ecs_task_execution

  role       = aws_iam_role.ecs_task_role.name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attach_2" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}
