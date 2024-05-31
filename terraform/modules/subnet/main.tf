variable "vpc_id" {}

resource "aws_subnet" "public1" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "public2" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.10.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
}

output "ids" {
  value = [aws_subnet.public1.id, aws_subnet.public2.id]
}

output "public1" {
  value = aws_subnet.public1
}

output "public2" {
  value = aws_subnet.public2
}