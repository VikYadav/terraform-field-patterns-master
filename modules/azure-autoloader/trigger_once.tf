locals {
  mount_point = "/mnt/${databricks_azure_adls_gen2_mount.this.mount_name}"
}

resource "databricks_notebook" "trigger_once" {
  content_base64 = base64encode(<<-EOT
    import pyspark.sql.functions as F

    def capture_bronze_lineage(df):
      # array, because we'll be recapturing files afterwards
      return df.withColumn('__file__', F.array(F.input_file_name()))

    # COMMAND ----------

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
      .transform(capture_bronze_lineage)
      .writeStream
      .trigger(once=True)
      .format('delta')
      .outputMode("append")
      .option('checkpointLocation', '${local.mount_point}/_checkpoints/${module.attempt.queue_name}-triggeronce-bronze')
      .option('path', '${local.mount_point}/delta/${var.folder}_to')
      .table('${var.folder}_to')
    )
    EOT
  )
  path = "${data.databricks_current_user.me.home}/Production/TriggerOnce"
  language = "PYTHON"
}

resource "databricks_job" "trigger_once" {
  name = "Bronze (Trigger Once)"

  new_cluster {
    num_workers   = 1
    spark_version = data.databricks_spark_version.latest.id
    node_type_id  = data.databricks_node_type.smallest.id

    spark_conf = {
      "experiment.resource_group" = data.azurerm_resource_group.this.name,
      "experiment.subscription_id" = data.azurerm_client_config.this.subscription_id,
      "experiment.tenant_id" = data.azurerm_client_config.this.tenant_id,
      "experiment.client_id" = data.azurerm_client_config.this.client_id
    }
  }

  notebook_task {
    notebook_path = databricks_notebook.trigger_once.path
  }

  email_notifications {}
}