output "databricks_host" {
  value = databricks_mws_workspaces.this.workspace_url

}

output "crossaccount_role_name" {
  value = aws_iam_role.cross_account_role.name
}