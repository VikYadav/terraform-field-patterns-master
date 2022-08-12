variable "tags" {}
variable "aad_tenant_id" {}
variable "az_subscription_id" {}
variable "aad_application_id" {}
variable "aad_domain" {}
variable "test_password" {}
variable "prefix" {}
variable "vpc_id" {}
variable "aws_region" {}
variable "aws_zone" {}
variable "databricks_external_id" {}
variable "databricks_workspace_host" {}
variable "databricks_workspace_token" {}

provider "aws" {
  region = var.aws_region
}

provider "databricks" {
  host = var.databricks_workspace_host
  token = var.databricks_workspace_token
}

module "splunk" {
  source = "../../modules/aws-splunk-instance"
  name   = "${var.prefix}-splunk"
  vpc_id = var.vpc_id
  tags   = var.tags
}

module "splunk_forwarder" {
  source = "../../modules/cluster-logs/splunk-forwarder"
  splunk_host = module.splunk.private_ip
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
  cluster_name            = "${var.prefix} splunk renamed"
  spark_version           = "7.1.x-scala2.12"
  node_type_id            = "i3.xlarge"
  autotermination_minutes = 20

  autoscale {
    min_workers = 1
    max_workers = 10
  }

  ssh_public_keys = [file("~/.ssh/id_rsa.pub")]

  init_scripts {
    dbfs {
      destination = module.splunk_forwarder.dbfs_path
    }
  }

  depends_on = [module.splunk_forwarder]
}

output "ssh" {
  value = module.splunk.ssh_command
}

output "admin_password" {
  value = module.splunk.admin_password
}

output "splunk_ui" {
  value = module.splunk.splunk_ui
}