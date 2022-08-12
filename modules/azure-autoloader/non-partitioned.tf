locals {
  non_partitioned = "${var.folder}-non-partitioned"
}

module "non_partitioned" {
  source = "../azure-autoloader-queue"
  container_name = azurerm_storage_container.this.name
  storage_account_name = azurerm_storage_account.this.name
  resource_group_name = data.azurerm_resource_group.this.name
  mount_name = databricks_azure_adls_gen2_mount.this.mount_name
  folder = local.non_partitioned
}

resource "databricks_notebook" "consume_non_partitioned" {
  content_base64 = base64encode(<<-EOT
    import pyspark.sql.functions as F
    checkin_schema = 'ts timestamp, name string, date date, job string, geo array<double>, metric int'
    autoloaderDf = (spark.readStream.format('cloudFiles')
      .option('cloudFiles.format', 'json')
      .schema(checkin_schema)
      .option("cloudFiles.connectionString", dbutils.secrets.get("${databricks_secret.connection_string.scope}", "${databricks_secret.connection_string.key}"))
      .option("cloudFiles.clientSecret", dbutils.secrets.get("${databricks_secret.spn_secret.scope}", "${databricks_secret.spn_secret.key}"))
      .option("cloudFiles.resourceGroup", spark.conf.get('experiment.resource_group'))
      .option("cloudFiles.subscriptionId", spark.conf.get('experiment.subscription_id'))
      .option("cloudFiles.tenantId", spark.conf.get('experiment.tenant_id'))
      .option("cloudFiles.clientId", spark.conf.get('experiment.client_id'))
      .option('cloudFiles.partitionColumns', 'year,month,day')
      .option('cloudFiles.includeExistingFiles', False)
      .option('cloudFiles.queueName', '${module.non_partitioned.queue_name}')
      .option('cloudFiles.useNotifications', True)
      .load('${module.non_partitioned.path}'))
    display(autoloaderDf.select(F.count(F.lit(1))),
      processingTime='5 seconds')

    # COMMAND ----------

    # it's too difficult for spark to figure out nested folder structure
    display(spark.read.json('${module.non_partitioned.path}', schema=checkin_schema))
    EOT
  )
  path = "${data.databricks_current_user.me.home}/ConsumeNonPartitionedFiles"
  language = "PYTHON"
}

resource "local_file" "make_dummy_data_non_partitioned" {
  filename = "${path.cwd}/make-dummy-data-non-partitioned.sh"
  content = <<-EOT
    rm -fr ${var.folder}
    python3 ${path.module}/dummy-data.py ${local.non_partitioned} not_partitioned
    az storage blob upload-batch \
      --account-name ${azurerm_storage_account.this.name} \
      -s ${local.non_partitioned} \
      -d ${databricks_azure_adls_gen2_mount.this.mount_name}/${local.non_partitioned}
  EOT
}