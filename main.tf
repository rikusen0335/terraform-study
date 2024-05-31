

variable "common_tags" {
  type = map(string)
  default = {
    Terraform = "true"
  }
}

variable "repository_name" {
  type = string
  default = "nginx-repository"
}

module "nginx_repository" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  repository_name                 = var.repository_name
  repository_type                 = "private"
  repository_image_tag_mutability = "MUTABLE"
  create_lifecycle_policy         = true

  # 最新の3イメージのみを保持
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire images by count"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 3
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = merge(var.common_tags)
}

data "aws_caller_identity" "current" {}

module "iam_role_github_actions" {
  source = "./terraform/modules/github_actions"

  account_id   = data.aws_caller_identity.current.account_id
  github_org   = "rikusen0335"
  github_repo  = "terraform-study"
}

module "subnet" {
  source = "./terraform/modules/subnet"

  vpc_id = module.vpc.vpc_id
}

module "iam" {
  source = "./terraform/modules/iam"
}

module "ecs" {
  source = "./terraform/modules/ecs"

  repository_name = var.repository_name
  repository_url  = module.nginx_repository.repository_url
  iam_role_arn    = module.iam.sample_iam_role.arn
  security_group_ids = [aws_security_group.sample_security_group.id]
  elb_target_group_arn = aws_lb_target_group.sample.arn
  subnet_ids = [module.subnet.public1.id, module.subnet.public2.id]
}

module "vpc" {
  source = "./terraform/modules/vpc"
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

resource "aws_lb_target_group" "sample" {
  name        = "nginx-lb"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.sample.id
  target_type = "ip"
}


resource "aws_lb" "sample_lb" {
  name               = "sample-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.sample_security_group.id]

  subnets = [aws_subnet.public1.id, aws_subnet.public2.id]
}

resource "aws_lb_listener" "test_listener" {
  load_balancer_arn = aws_lb.sample_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sample.arn
  }
}

output "aws_lb_dns_name" {
  value = aws_lb.sample_lb.dns_name
}