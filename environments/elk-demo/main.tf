variable "tags" {}
variable "prefix" {}
variable "vpc_id" {}
variable "aws_region" {}
variable "aws_zone" {}
variable "databricks_workspace_host" {}
variable "databricks_workspace_token" {}

provider "aws" {
  region = var.aws_region
}

provider "databricks" {
  host = var.databricks_workspace_host
  token = var.databricks_workspace_token
}

module "elk" {
  source = "../../modules/aws-elk-instance"
  name   = "${var.prefix}-elk"
  vpc_id = var.vpc_id
  tags   = var.tags
}

data "http" "this_ip" {
  // retrieve this IP address for firewall opening
  url = "https://ifconfig.me"
}

data "aws_security_group" "worker" {
  vpc_id = var.vpc_id
  name = "*-worker"
}

resource "aws_security_group_rule" "allow_spark_ssh" {
  security_group_id = data.aws_security_group.worker.id

  type = "ingress"
  from_port = 2200
  protocol = "TCP"
  to_port = 2200

  cidr_blocks = ["${data.http.this_ip.body}/32"]
  description = "Allow ${data.http.this_ip.body} to SSH into Spark Nodes"
}

resource "databricks_cluster" "shared_autoscaling" {
  cluster_name            = "${var.prefix} elk forwarding demo"
  spark_version           = "6.6.x-scala2.11"
  node_type_id            = "i3.xlarge"
  autotermination_minutes = 20

  autoscale {
    min_workers = 1
    max_workers = 10
  }

  ssh_public_keys = [file("~/.ssh/id_rsa.pub")]
}

data "aws_instances" "workers" {
  instance_tags = {
    ClusterId = databricks_cluster.shared_autoscaling.id
  }
  instance_state_names = ["running", "pending"]
}

output "worker_ssh" {
  value = [for v in data.aws_instances.workers.public_ips: "ssh -p 2200 ubuntu@${v}"]
}

output "elastic_private_ip" {
  value = module.elk.private_ip
}

output "ssh" {
  value = module.elk.ssh_command
}

output "kibana" {
  value = module.elk.kibana_url
}