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

resource "aws_vpc" "sample" {
  cidr_block = "10.0.0.0/16"
}

output "aws_vpc_id" {
  value = aws_vpc.example.id
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.sample.cidr_block, 8, 1)
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.sample.id
  tags = {
    Name = "internet_gateway"
  }
}

resource "aws_lb" "sample_lb" {
  name               = "sample-lb"
  internal           = false
  load_balancer_type = "network"

  subnets = [for subnet in aws_subnet.public : subnet.id]
}