module "attempt" {
  source = "../azure-autoloader-queue"
  container_name = azurerm_storage_container.this.name
  storage_account_name = azurerm_storage_account.this.name
  resource_group_name = data.azurerm_resource_group.this.name
  mount_name = databricks_azure_adls_gen2_mount.this.mount_name
  folder = var.folder
}

resource "databricks_notebook" "cloudfiles_init" {
  content_base64 = base64encode(<<-EOT
    import com.databricks.sql.CloudFilesAzureResourceManager
    val manager = CloudFilesAzureResourceManager.newManager
      .option("cloudFiles.connectionString", dbutils.secrets.get("${databricks_secret.connection_string.scope}", "${databricks_secret.connection_string.key}"))
      .option("cloudFiles.clientSecret", dbutils.secrets.get("${databricks_secret.spn_secret.scope}", "${databricks_secret.spn_secret.key}"))
      .option("cloudFiles.resourceGroup", spark.conf.get("experiment.resource_group"))
      .option("cloudFiles.subscriptionId", spark.conf.get("experiment.subscription_id"))
      .option("cloudFiles.tenantId", spark.conf.get("experiment.tenant_id"))
      .option("cloudFiles.clientId", spark.conf.get("experiment.client_id"))
      // path is required only for setUpNotificationServices
      .option("path", "${module.attempt.path}")
      .create()

    // COMMAND ----------

    display(manager.listNotificationServices())
    EOT
  )
  path = "${data.databricks_current_user.me.home}/CloudFilesInit"
  language = "SCALA"
}

resource "local_file" "make_dummy_data" {
  filename = "${path.cwd}/make-dummy-data.sh"
  content = <<-EOT
    rm -fr ${var.folder}
    python3 ${path.module}/dummy-data.py ${var.folder}
    az storage blob upload-batch \
      --account-name ${azurerm_storage_account.this.name} \
      -s ${var.folder} \
      -d ${databricks_azure_adls_gen2_mount.this.mount_name}/${var.folder}
  EOT
}

resource "databricks_notebook" "dummy-data" {
  source = "${path.module}/dummy-data.py"
  path = "${data.databricks_current_user.me.home}/FakeData"
}

resource "databricks_notebook" "consume_sample" {
  content_base64 = base64encode(<<-EOT
    import pyspark.sql.functions as F

    def capture_bronze_lineage(df):
      # array, because we'll be recapturing files afterwards
      return df.withColumn('__file__', F.array(F.input_file_name()))

    checkin_schema = 'ts timestamp, name string, date date, job string, geo array<double>, metric int'
    autoloaderDf = (spark.readStream.format('cloudFiles')
      .option('cloudFiles.format', 'json')
      .schema(checkin_schema + ', year int, month int, day int')
      .option("cloudFiles.connectionString", dbutils.secrets.get("${databricks_secret.connection_string.scope}", "${databricks_secret.connection_string.key}"))
      .option("cloudFiles.clientSecret", dbutils.secrets.get("${databricks_secret.spn_secret.scope}", "${databricks_secret.spn_secret.key}"))
      .option("cloudFiles.resourceGroup", spark.conf.get('experiment.resource_group'))
      .option("cloudFiles.subscriptionId", spark.conf.get('experiment.subscription_id'))
      .option("cloudFiles.tenantId", spark.conf.get('experiment.tenant_id'))
      .option("cloudFiles.clientId", spark.conf.get('experiment.client_id'))
      .option('cloudFiles.partitionColumns', 'year,month,day')
      .option('cloudFiles.includeExistingFiles', False)
      .option('cloudFiles.queueName', '${module.attempt.queue_name}')
      .option('cloudFiles.useNotifications', True)
      .load('${module.attempt.path}')
      .transform(capture_bronze_lineage))
    display(autoloaderDf.select(F.count(F.lit(1))),
      processingTime='5 seconds')
    EOT
  )
  path = "${data.databricks_current_user.me.home}/ConsumeFiles"
  language = "PYTHON"
}

