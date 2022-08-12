variable "splunk_host" {}


resource "databricks_dbfs_file" "variables" {
  content = base64encode("export SPLUNK_DEPLOYMENT_HOST=${var.splunk_host}")
  path = "/databricks/scripts/splunk-host2.sh"
  overwrite = true
  mkdirs = true
  validate_remote_file = true
}

resource "databricks_dbfs_file" "init_script" {
  content = base64encode(file("${path.module}/splunk-forwarder.sh"))
  path = "/databricks/scripts/splunk-forwarder.sh"
  overwrite = true
  mkdirs = true
  validate_remote_file = true
  // more complicated TF file is better than unreadable bash
  depends_on = [databricks_dbfs_file.variables]
}

output "dbfs_path" {
  value = databricks_dbfs_file.init_script.path
}