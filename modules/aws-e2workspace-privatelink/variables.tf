variable "databricks_account_username" {}
variable "databricks_account_password" {}
variable "databricks_account_id" {}

variable "tags" {
  default = {}
}

variable "region" {
  default = "eu-west-1"
}

variable "cidr_block_private" {
  default = "10.1.0.0/16"
}

variable "cidr_block_public" {
  default = "10.2.0.0/16"
}

variable "vpce_subnet_cidr" {
  default = "10.3.0.0/16"
}

variable "workspace_vpce_service" {}

variable "relay_vpce_service" {}

variable "private_dns_enabled" { default = false }

variable "project_subnets_range_private" {
  default     = 3
  description = "3 for small, 6 for medium and 8 for large for a /16 cidr_block"
}

variable "project_subnets_range_public" {
  default     = 3
  description = "3 for small, 6 for medium and 8 for large for a /16 cidr_block"
}

variable "project_name" {
  default = "demo"
}
variable "project_env" {
  default = "dev"
  type    = list(string)
}

variable "team" {
  default     = "tf"
  description = "Team that performs the work"
}

locals {
  prefix = "demo"
}