terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "id_rsa"
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" {
    command = "rm -rf ./id_rsa.pem; echo '${tls_private_key.pk.private_key_pem}' > ./id_rsa.pem && chmod 400 ./id_rsa.pem"
  }
}

resource "aws_instance" "app_server" {
  ami           = "ami-0e21d4d9303512b8e"
  instance_type = var.instance_type
  key_name      = aws_key_pair.kp.key_name

  tags = {
    Name = var.instance_name
  }

  root_block_device {
    volume_size = 32
  }
}

# generate inventory file for Ansible
resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/templates/hosts.tpl",
    {
      ips = aws_instance.app_server.public_ip
      key_path = abspath(path.root)
    }
  )
  filename = "../ansible/etc/hosts"
}
