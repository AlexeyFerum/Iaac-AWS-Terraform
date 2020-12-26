terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

provider "aws" {
  profile = "default"
  region = "us-east-2"
}

provider "docker" {
  host = "tcp://127.0.0.1:2375/"
}

resource "aws_security_group" "hw3_sg" {
  name = "hw3_sg"
  description = "Allow HTTP, HTTPS and SSH traffic"

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "hw3_ec2" {
    ami = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, world" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF

    vpc_security_group_ids = [
      aws_security_group.hw3_sg.id
    ]
}

resource "aws_db_instance" "hw3_db" {
  name = "hw3_db"
  allocated_storage = 20
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  username = "AlexFerum"
  password = "Ghbdtn77!"
  parameter_group_name = "default.mysql5.7"

  vpc_security_group_ids = [aws_security_group.hw3_sg.id]
}

resource "aws_api_gateway_rest_api" "hw3_api" {
  name = "hw3_api"
  description = "My API"
}

resource "aws_api_gateway_resource" "hw3_api_r1" {
  rest_api_id = aws_api_gateway_rest_api.hw3_api.id
  parent_id = aws_api_gateway_rest_api.hw3_api.root_resource_id
  path_part = "test"
}

resource "aws_api_gateway_method" "hw3_api_r1_m1" {
  rest_api_id = aws_api_gateway_rest_api.hw3_api.id
  resource_id = aws_api_gateway_resource.hw3_api_r1.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "hw3_api_r1_m1_integration" {
  rest_api_id = aws_api_gateway_rest_api.hw3_api.id
  resource_id = aws_api_gateway_resource.hw3_api_r1.id
  http_method = aws_api_gateway_method.hw3_api_r1_m1.http_method
  type = "HTTP_PROXY"
  integration_http_method = "GET"
  uri = "http://${aws_instance.hw3_ec2.public_ip}:8080/"
}

resource "docker_container" "hw3_zap-container" {
  name  = "hw3_zap"
  image = docker_image.hw3_zap_image.latest
  command = ["python", "autostart.py",
             "-f", "python zap-full-scan.py -t http://${aws_instance.hw3_ec2.public_ip}/"]
}

resource "docker_image" "hw3_zap_image" {
  name = "hw3_zap_image"
  build {
    path = "docker"
  }
}

output "public_ec2_ip" {
  value = aws_instance.hw3_ec2.public_ip
  description = "Public server IP"
}

output "db_address" {
  value = aws_db_instance.hw3_db.address
  description = "Database adress"
}

output "db_password" {
  value = aws_db_instance.hw3_db.password
  description = "Database password"
}
