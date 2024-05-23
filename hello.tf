terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  # default_tags {
  #   tags = {
  #     Environment = "dev"
  #     Owner       = "DevOps Team"
  #   }
  # }
}

resource "aws_iam_role" "sample_iam_role" {
  name = "sample_iam_role"

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
      },
    ]
  })
}

resource "aws_iam_role_policy" "sample_iam_role_policy" {
  name = "sample_iam_role_policy"
  role = aws_iam_role.sample_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17" 
    Statement = [
      {
        Action = [
          "ecs:RunTask",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_ecs_cluster" "sample_ecs_cluster" {
  name = "sample_ecs_cluster" 
}

resource "aws_ecs_task_definition" "sample_ecs_task" {
  family = "sample_ecs_cluster"
  container_definitions = jsonencode([
    {
      name = "nginx"
      image = "nginx:latest"
      network_mode = "awsvpc"
      requires_compatibilities = ["FARGATE"]
      cpu = 1
      memory = 256
      portMappings = [
        {
          containerPort = 80
          hostPort = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "service" {
  name          = "ecs_service"
  cluster       = aws_ecs_cluster.sample_ecs_cluster.id
  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.public1,
      aws_subnet.public2
    ]
    security_groups  = [aws_security_group.sample_security_group.id]
    assign_public_ip = true
  }

  load_balancer {
    container_name   = "nginx"
    container_port   = "80"
  }

  task_definition = aws_ecs_task_definition.sample_ecs_task.arn

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
    ]
  }
}

resource "aws_vpc" "sample" {
  cidr_block = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
}

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.sample.id
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.sample.id
  cidr_block              = "10.10.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.sample.id
  tags = {
    Name = "internet_gateway"
  }
}

resource "aws_route_table" "alb_route_table" {
  vpc_id = aws_vpc.sample.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

# resource "aws_route" "public-route" {
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.internet_gateway.id
#   route_table_id         = aws_route_table.alb_route_table.id
# }

resource "aws_route_table_association" "alb_table_association_1a" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.alb_route_table.id
}

resource "aws_route_table_association" "alb_table_association_1c" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.alb_route_table.id
}

resource "aws_security_group" "sample_security_group" {
  name   = "ecs-security-group"
  vpc_id = aws_vpc.sample.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    description = "any"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "sample_lb" {
  name               = "sample-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.sample_security_group.id]

  subnets = [aws_subnet.public1.id, aws_subnet.public2.id]
}

output "aws_lb_dns_name" {
  value = aws_lb.sample_lb.dns_name
}