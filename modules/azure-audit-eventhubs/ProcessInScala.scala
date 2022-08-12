// Databricks notebook source
// MAGIC %md # Transforming event hub entries to flat schema

// COMMAND ----------

import org.apache.spark.sql._
def databricksAudit(df: DataFrame): DataFrame = {
  import org.apache.spark.sql.types._
  import org.apache.spark.sql.functions._
  import org.apache.spark.sql._
  df.withColumn("payload", from_json('body.cast("string"), StructType(Seq(StructField("records", ArrayType(StructType(Seq(
    StructField("properties", StructType(Seq(
      StructField("logId", StringType),
      StructField("requestId", StringType),
      StructField("requestParams", StringType),
      StructField("response", StringType),
      StructField("serviceName", StringType),
      StructField("sessionId", StringType),
      StructField("sourceIPAddress", StringType),
      StructField("userAgent", StringType)
    ))),
    StructField("Host", StringType),
    StructField("category", StringType),
    StructField("identity", StringType),
    StructField("operationName", StringType),
    StructField("operationVersion", StringType),
    StructField("resourceId", StringType),
    StructField("time", StringType)
  ))))))))
    .drop("body")
    .withColumn("_", explode($"payload.records"))
    .select($"_.*")
    .transform(df => df.select(Seq($"properties.*") ++ df.columns.map(c => new ColumnName(c)):_*))
    .withColumn("requestParams", from_json('requestParams, MapType(StringType, StringType)))
    .withColumn("response", from_json('response, MapType(StringType, StringType)))
    .withColumn("identity", from_json('identity, MapType(StringType, StringType)))
    .withColumn("workspace", expr("lower(split(resourceId, '/')[8])"))
    .withColumn("time", 'time.cast("timestamp"))
    .withColumn("operationName", expr("split(operationName, '/')[2]"))
    .drop("properties", "Host", "sessionId", "logId", "requestId", "resourceId", "operationVersion")
}

// COMMAND ----------

// MAGIC %md # Reading stream with connection string supplied through secret `databricks_secret.this` from `azurerm_eventhub_authorization_rule.listen.primary_connection_string`

// COMMAND ----------

import org.apache.spark.eventhubs.{ ConnectionStringBuilder, EventHubsConf, EventPosition }
display(spark.readStream
  .format("eventhubs")
  .options(
    EventHubsConf(dbutils.secrets.get("eventhub", "connection-string"))
      .setStartingPosition(EventPosition.fromStartOfStream)
      .toMap)
  .load()
  .transform(databricksAudit))
