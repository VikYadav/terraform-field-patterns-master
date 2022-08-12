data "databricks_node_type" "smallest" {
  local_disk = true
}

data "databricks_spark_version" "latest" {}

data "databricks_current_user" "me" {}

resource "databricks_cluster" "this" {
  cluster_name            = "docker test (${data.databricks_current_user.me.user_name})"
  spark_version           = data.databricks_spark_version.latest.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 20
  num_workers = 0

  spark_conf = {
    "spark.master" = "local[*]"
    "spark.databricks.cluster.profile" = "singleNode"
  }

  docker_image {
    url = docker_registry_image.this.name
    basic_auth {
      username = azurerm_container_registry.this.admin_username
      password = azurerm_container_registry.this.admin_password
    }
  }
}

output "cluster_url" {
  description = "URL to view cluster configuration in the browser"
  value = "${data.azurerm_databricks_workspace.this.workspace_url}/#setting/clusters/${databricks_cluster.this.id}/configuration"
}