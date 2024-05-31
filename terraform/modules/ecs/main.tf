variable "repository_name" {}
variable "repository_url" {}
variable "iam_role_arn" {}
variable "security_group_ids" {
  type = list(string)
}
variable "elb_target_group_arn" {}
variable "subnet_ids" {
  type = list(string)
}

resource "aws_ecs_cluster" "sample_ecs_cluster" {
  name = "sample_ecs_cluster" 
}

resource "aws_ecs_task_definition" "sample_ecs_task" {
  family = "sample_ecs_task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  container_definitions = jsonencode([
    {
      name = var.repository_name
      image = "${var.repository_url}:latest"
      network_mode = "awsvpc"
      requires_compatibilities = ["FARGATE"]
      cpu = 256
      memory = 256
      portMappings = [
        {
          containerPort = 80
          hostPort = 80
        }
      ]
    }
  ])
  execution_role_arn = var.iam_role_arn
}

resource "aws_ecs_service" "service" {
  name          = "ecs_service"
  cluster       = aws_ecs_cluster.sample_ecs_cluster.id
  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.elb_target_group_arn
    container_name   = var.repository_name
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