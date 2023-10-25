terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "TF4640" {
  cidr_block = "10.55.0.0/16"
  tags = {
    Name = "TF4640_VPC"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.TF4640.id
  availability_zone = "us-west-2a"
  cidr_block        = "10.55.10.0/24"
  tags = {
    Name = "TF4640_SUBNET"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.TF4640.id

  tags = {
    Name = "TF4640_IGW"
  }
}

resource "aws_route_table" "routes" {
  vpc_id = aws_vpc.TF4640.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "TF4640_RTBL"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.routes.id
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.TF4640.id

  ingress {
    description = "SSH to EC2"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP to EC2"
    from_port   = 80
    to_port     = 80
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
    Name = "allow_ssh_http"
  }
}

resource "aws_security_group" "allow_ssh_http_mysql" {
  name        = "allow_ssh_http_mysql"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.TF4640.id

  ingress {
    description = "SSH to EC2"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP to EC2"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MYSQL to EC2"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.subnet.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http_mysql"
  }
}

resource "aws_instance" "app_server" {
  subnet_id                   = aws_subnet.subnet.id
  ami                         = "ami-017fecd1353bcc96e"
  key_name                    = "PEM_KEY"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]

  tags = {
    Name = "APP"
    Service = "APP"
  }
}

resource "aws_instance" "DB_server" {
  subnet_id                   = aws_subnet.subnet.id
  ami                         = "ami-017fecd1353bcc96e"
  key_name                    = "PEM_KEY"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http_mysql.id]

  tags = {
    Name = "DB"
    Service = "DB"
  }
}

output "ip_addr" {
  value = aws_instance.app_server.public_ip
}