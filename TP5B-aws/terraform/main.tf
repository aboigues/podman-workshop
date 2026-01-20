terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of SSH key pair"
  type        = string
  default     = "podman-workshop-key"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "workshop"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Data sources
data "aws_vpc" "default" {
  default = true
}

# AMI Amazon Linux 2023 (utilise dnf)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Security Group
resource "aws_security_group" "podman_sg" {
  name        = "podman-sg-${var.environment}"
  description = "Security group for Podman workshop"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Sortie internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "podman-sg-${var.environment}"
  }
}

# Instance EC2
resource "aws_instance" "podman" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.podman_sg.id]

  user_data = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "podman-workshop-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "ami_id" {
  description = "ID de l'AMI utilisée"
  value       = data.aws_ami.amazon_linux.id
}

output "vpc_id" {
  description = "ID du VPC"
  value       = data.aws_vpc.default.id
}

output "instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_instance.podman.id
}

output "public_ip" {
  description = "IP publique de l'instance"
  value       = aws_instance.podman.public_ip
}

output "ssh_command" {
  description = "Commande SSH pour se connecter"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_instance.podman.public_ip}"
}
