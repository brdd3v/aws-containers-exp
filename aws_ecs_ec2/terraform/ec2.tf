variable "image_tag" {
  default = "v1"
}

variable "cluster_name" {
  default = "cluster-exp"
}

data "aws_ecr_repository" "ecr_repo" {
  name = "flask-app"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_iam_role" "ecs_task_exec_role" {
  name = "ecs_task_exec_role"
  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_rpa" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs_instance_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_rpa" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance-profile-exp"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_launch_template" "template" {
  name          = "template-exp"
  image_id      = "ami-0b5009e7f102539b1" # Amazon ECS-Optimized Amazon Linux 2 (AL2) x86_64 AMI
  instance_type = "t2.small"  # 1 vCPU, 2 GiB Memory
  user_data     = base64encode("#!/bin/bash\necho ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config")

  vpc_security_group_ids = [aws_security_group.sg.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/"
}

resource "aws_security_group" "sg" {
  name   = "ecs-app-access-exp"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "asg" {
  name                = "asg-exp"
  vpc_zone_identifier = data.aws_subnets.all.ids

  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"

  launch_template {
    id = aws_launch_template.template.id
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

resource "aws_ecs_capacity_provider" "provider" {
  name = "provider-exp"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.asg.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster_providers" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = [aws_ecs_capacity_provider.provider.name]
}

resource "aws_ecs_task_definition" "task_def" {
  family                   = "task-exp"
  execution_role_arn       = aws_iam_role.ecs_task_exec_role.arn
  requires_compatibilities = ["EC2"]
  container_definitions = jsonencode([
    {
      name      = "flask-app-container"
      image     = "${data.aws_ecr_repository.ecr_repo.repository_url}:${var.image_tag}"
      essential = true
      memory    = 1024
      cpu       = 512
      portMappings = [
        {
          protocol      = "tcp"
          hostPort      = 5000
          containerPort = 5000
        }
      ]
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "${aws_cloudwatch_log_group.log_group.name}",
          "awslogs-region" : "eu-central-1",
          "awslogs-stream-prefix" : "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "svc" {
  name            = "service-exp"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task_def.arn
  desired_count   = 1
  launch_type     = "EC2"  # default
}
