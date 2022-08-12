/**
 * Single-node ELK Stack (ElasticSearch + FileBeat + Kibana in this case) on AWS
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

data "aws_ami" "ubuntu" {
  most_recent      = true
  // https://cloud-images.ubuntu.com/locator/ec2/
  name_regex       = "^ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-.*"
  // Canonical
  owners           = ["099720109477"]
}

variable "instance_type" {
  default = "i3.large"
}

data "http" "this_ip" {
  // retrieve this IP address for firewall opening
  url = "https://ifconfig.me"
}

data "aws_subnet_ids" "this" {
  vpc_id = var.vpc_id
}

data "aws_security_group" "worker" {
  vpc_id = var.vpc_id
  name = "*-worker"
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

  ingress {
    from_port = 5601
    protocol = "TCP"
    to_port = 5601
    cidr_blocks = ["${data.http.this_ip.body}/32"]
    description = "Allow ${data.http.this_ip.body} to access Kibana"
  }

  ingress {
    from_port = 9200
    protocol = "TCP"
    to_port = 9200
    security_groups = [data.aws_security_group.worker.id]
    description = "Allow ${data.aws_security_group.worker.name} to forward logs to ElasticSearch directly"
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
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.this.id]
  subnet_id = element(tolist(data.aws_subnet_ids.this.ids), 0)
  associate_public_ip_address = true
  key_name = aws_key_pair.local.key_name
  user_data = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size = 20
    delete_on_termination = true
    volume_type = "gp2"
  }

  connection {
    host = aws_instance.sandbox.public_ip
    user = "ubuntu"
  }

  # add to elasticsearch.yml
  #network.host: 0.0.0.0
  # discovery.seed_hosts, discovery.seed_providers, cluster.initial_master_nodes

  provisioner "remote-exec" {
    inline = [
      "echo '[*] Waiting for ElasticSearch to be up'",
      "while ! nc -z localhost 9200; do sleep 1; done",
      "echo '[*] Waiting for Kibana to be up'",
      "while ! nc -z localhost 5601; do sleep 1; done",
      "echo '[*] DONE'"
    ]
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

output "private_ip" {
  value = aws_instance.sandbox.private_ip
}

output "ssh_command" {
  value = "ssh ubuntu@${aws_instance.sandbox.public_ip}"
}

output "kibana_url" {
  value = "http://${aws_instance.sandbox.public_ip}:5601"
}