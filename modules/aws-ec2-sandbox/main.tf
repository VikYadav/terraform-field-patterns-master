/**
 * Creates EC2 instance with Terraform installed on it
 */

variable "name" {
  description = "Name of the resources"
}

variable "vpc_id" {
  description = "AWS VPC to launch EC2 instance"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources created"
}

variable "ami" {
  default = "ami-02ae530dacc099fc9"
  description = "AWS AMI to launch with. Defaults to Ubuntu 20.04 LTS"
}

variable "instance_type" {
  default = "t2.xlarge"
}

data "http" "this_ip" {
  // retrieve this IP address for firewall opening
  url = "https://ifconfig.me"
}

resource "aws_security_group" "this" {
  vpc_id = var.vpc_id
  name = "${var.name}-ssh-access"
  description = "Allows work laptop (${data.http.this_ip.body}) to SSH"
  revoke_rules_on_delete = true

  ingress {
    from_port = 22
    protocol = "TCP"
    to_port = 22
    cidr_blocks = ["${data.http.this_ip.body}/32"]
    description = "Allow ${data.http.this_ip.body} to SSH"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_key_pair" "local" {
  key_name   = "${var.name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "sandbox" {
  ami = var.ami
  instance_type = var.instance_type
  security_groups = [aws_security_group.this.name]
  key_name = aws_key_pair.local.key_name

  user_data = <<EOF
  TER_VER=`curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1'`
  wget https://releases.hashicorp.com/terraform/$TER_VER/terraform_$(TER_VER)_linux_amd64.zip
  gunzip -S .zip terraform_$(TER_VER)_linux_amd64.zip
  sudo mv terraform_$(TER_VER)_linux_amd64 /usr/local/bin/terraform
  chmod +x /usr/local/bin/terraform

  sudo apt-get update
  sudo apt-get install make golang -y
  EOF

  tags = merge(var.tags, {
    Name = var.name
  })
}

output "ssh_command" {
  value = "ssh ubuntu@${aws_instance.sandbox.public_ip}"
}