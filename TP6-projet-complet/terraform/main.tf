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
  default     = "eu-west-3"
}

variable "instance_type" {
  description = "EC2 instance type (t3.medium recommandé pour la stack complète)"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of SSH key pair"
  type        = string
  default     = "taskplatform-key"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "git_repo" {
  description = "Git repository URL for the workshop"
  type        = string
  default     = "https://github.com/aboigues/podman-workshop.git"
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
resource "aws_security_group" "taskplatform_sg" {
  name        = "taskplatform-sg-${var.environment}"
  description = "Security group for TaskPlatform stack"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # Application (Nginx reverse proxy)
  ingress {
    description = "Application HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana
  ingress {
    description = "Grafana"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
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
    Name = "taskplatform-sg-${var.environment}"
  }
}

# Instance EC2
resource "aws_instance" "taskplatform" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.taskplatform_sg.id]

  user_data = templatefile("${path.module}/user-data.sh", {
    git_repo = var.git_repo
  })

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name        = "taskplatform-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "podman-workshop-tp6"
  }
}

# Outputs
output "ami_id" {
  description = "ID de l'AMI utilisée"
  value       = data.aws_ami.amazon_linux.id
}

output "instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_instance.taskplatform.id
}

output "public_ip" {
  description = "IP publique de l'instance"
  value       = aws_instance.taskplatform.public_ip
}

output "app_url" {
  description = "URL de l'application"
  value       = "http://${aws_instance.taskplatform.public_ip}:8080"
}

output "grafana_url" {
  description = "URL de Grafana"
  value       = "http://${aws_instance.taskplatform.public_ip}:3001"
}

output "prometheus_url" {
  description = "URL de Prometheus"
  value       = "http://${aws_instance.taskplatform.public_ip}:9090"
}

output "ssh_command" {
  description = "Commande SSH pour se connecter"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_instance.taskplatform.public_ip}"
}
