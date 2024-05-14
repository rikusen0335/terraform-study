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

data "aws_iam_policy_document" "sample_iam_role_document" {
  version = "2012-10-17" 
  statement {
    actions = [
      "ecs:RunTask",
    ]
    resources = ["*"]
  }
}


resource "aws_iam_role" "sample_iam_role" {
  name = "sample_iam_role"

  assume_role_policy = data.aws_iam_policy_document.sample_iam_role_document.json 
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
      network_mode = "aws_vpc"
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

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

output "aws_vpc_id" {
  value = aws_vpc.example.id
}
