terraform {
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

locals {
  rs = "${random_string.suffix.id}"
}

# Random string for resources
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "tls_private_key" "n8n" {
  algorithm = "RSA"
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "n8b-${local.rs}"
  public_key = tls_private_key.n8n.public_key_openssh
}

# write ssh key to file
resource "local_file" "ssh_key" {
    content  = tls_private_key.n8n.private_key_pem
    filename = "${path.module}/ssh_key.pem"
    file_permission = "0700"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "n8n_gpu_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = module.key_pair.key_pair_name

  vpc_security_group_ids = [aws_security_group.n8n_sg.id]

  user_data = file("${path.module}/user_data.sh")

  root_block_device {
    volume_size = 300
    volume_type = "gp3"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.private_key.private_key_pem
    host        = self.public_ip
  }

  tags = {
    Name = "gpu-ai-playground"
  }
}

resource "aws_ebs_volume" "n8n_data" {
  availability_zone = aws_instance.n8n_gpu_node.availability_zone
  size              = var.ebs_volume_size
  type              = "gp3"

  tags = {
    Name = "n8n-data-volume"
  }
}

resource "aws_volume_attachment" "n8n_data_attach" {
  device_name = "/dev/sdf"
  instance_id = aws_instance.n8n_gpu_node.id
  volume_id   = aws_ebs_volume.n8n_data.id
}
