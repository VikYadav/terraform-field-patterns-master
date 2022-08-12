variable "prefix" {}
variable "aws_region" {}
variable "aws_zone" {}
variable "consumed_datasets" { type = map(object({
  reader_policy_arn = string,
  bucket = string
})) }
//marketing = {
//  reader_policy_arn = module.marketing.reader_policy_arn
//  bucket = module.marketing.bucket
//}

variable "crossaccount_role_name" {}
variable "databricks_workspace_host" {}
variable "databricks_workspace_token" {}
variable "skip_validation" { default = false }

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources created"
}

module "instance_profile" {
  source = "../../aws-databricks-department/instance-profile"
  name = "${var.prefix}-consumers"
  description = "IAM Instance Profile that only reads data"
  databricks_workspace_host = var.databricks_workspace_host
  databricks_workspace_token = var.databricks_workspace_token
  crossaccount_role_name = var.crossaccount_role_name
  skip_validation = var.skip_validation
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "allow_reading" {
  for_each = var.consumed_datasets
  role       = module.instance_profile.role_for_s3_access_name
  policy_arn = each.value.reader_policy_arn
}

provider "databricks" {
  host  = var.databricks_workspace_host
  token = var.databricks_workspace_token
}

resource "databricks_group" "this" {
  display_name               = "Consumers"
  allow_cluster_create       = false
  allow_instance_pool_create = false
}

resource "databricks_group_instance_profile" "this" {
  group_id = databricks_group.this.id
  instance_profile_id = module.instance_profile.databricks_instance_profile_id
}

resource "databricks_cluster_policy" "fair_use" {
  name = "Fair Use Cluster Policy"
  definition = jsonencode({
    "dbus_per_hour" : {
      "type" : "range",
      "maxValue" : 10
    },
    "spark_conf.spark.databricks.cluster.profile" : {
      "type" : "fixed",
      "value" : "serverless",
      "hidden" : true
    },
    "instance_pool_id" : {
      "type" : "forbidden",
      "hidden" : true
    },
    "node_type_id" : {
      "type" : "whitelist",
      "values" : [
        "i3.xlarge",
        "i3.2xlarge",
        "i3.4xlarge"
      ],
      "defaultValue" : "i3.xlarge"
    },
    "driver_node_type_id" : {
      "type" : "fixed",
      "value" : "i3.2xlarge",
      "hidden" : true
    },
    "autoscale.min_workers" : {
      "type" : "fixed",
      "value" : 1,
      "hidden" : true
    },
    "autotermination_minutes" : {
      "type" : "fixed",
      "value" : 20,
      "hidden" : true
    },
    "aws_attributes.zone_id" : {
      "type" : "fixed",
      "value" : var.aws_zone,
      "hidden" : true
    },
    "aws_attributes.instance_profile_arn" : {
      "type" : "fixed",
      "value" : module.instance_profile.instance_profile_arn,
      "hidden" : true
    },
    "custom_tags.Team" : {
      "type" : "fixed",
      "value" : "Consumers"
    }
  })
}

resource "databricks_permissions" "can_use_instance_profile" {
  cluster_policy_id = databricks_cluster_policy.fair_use.id
  access_control {
    group_name       = databricks_group.this.display_name
    permission_level = "CAN_USE"
  }
}

resource "databricks_cluster" "shared_autoscaling" {
  cluster_name            = "Shared Autoscaling"
  spark_version           = "6.6.x-scala2.11"
  node_type_id            = "i3.xlarge"
  autotermination_minutes = 20

  autoscale {
    min_workers = 1
    max_workers = 10
  }

  aws_attributes {
    instance_profile_arn = module.instance_profile.instance_profile_arn
    availability         = "SPOT"
    zone_id              = var.aws_zone
  }

  custom_tags = merge(var.tags, {
    Team = "Consumers"
  })

  depends_on = [databricks_group_instance_profile.this]
}

resource "databricks_permissions" "can_use_team_cluster" {
  cluster_id = databricks_cluster.shared_autoscaling.id
  access_control {
    group_name       = databricks_group.this.display_name
    permission_level = "CAN_RESTART"
  }
}