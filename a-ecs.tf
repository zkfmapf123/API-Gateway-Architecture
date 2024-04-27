module "a-ecs" {
  source = "zkfmapf123/ecs-fargate/lee"
  prefix = "a"

  vpc_attr = {
    vpc_id         = module.vpc.vpc.vpc_id
    alb_subnet_ids = values(module.vpc.vpc.webserver_subnets)
  }

  lb_attr = {
    internal             = false
    deregistration_delay = 60
  }

  lb_health = {
    path                = "/health"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }

  is_create_cluster = {
    is_enable           = false
    exists_cluster_name = aws_ecs_cluster.name
  }

  is_create_ecr = {
    is_enable       = false
    exists_ecr_name = ""
  }

  ecs_attr = {
    port          = 3000
    cpu           = 256
    memory        = 512
    desired_count = 1
    subnet_ids    = values(module.vpc.vpc.was_subnets)
  }

  task_def = [{
    name      = "ecs-a-server-container"
    image     = "zkfmapf123/donggyu-friends:latest"
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
        awslogs-group         = "ecs-a-server-container"
        awslogs-create-group  = "true"
        awslogs-region        = "ap-northeast-2"
        awslogs-stream-prefix = "ecs"
      }
    }
  }]

  depends_on = [module.vpc, aws_ecs_cluster.ecs_cluster]
}
