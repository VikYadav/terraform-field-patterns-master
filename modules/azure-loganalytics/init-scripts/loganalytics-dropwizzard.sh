#!/usr/bin/env bash

cp /dbfs/FileStore/jars/monitoring/* /mnt/driver-daemon/jars
echo "Copied Spark Monitoring jars successfully"

# Add your Log Analytics Workspace information below so all clusters use the same
# Log Analytics Workspace
# Also if it is available use AZ_* variables to include x-ms-AzureResourceId
# header as part of the request

cat >> /databricks/spark/conf/spark-env.sh << EOF
export DB_CLUSTER_ID=$DB_CLUSTER_ID
export LOG_ANALYTICS_WORKSPACE_ID=${LOG_ANALYTICS_WORKSPACE_ID}
export LOG_ANALYTICS_WORKSPACE_KEY=${LOG_ANALYTICS_WORKSPACE_KEY}
export AZ_RSRC_GRP_NAME=${AZ_RSRC_GRP_NAME}
export AZ_RSRC_PROV_NAMESPACE=Microsoft.Databricks
export AZ_RSRC_TYPE=workspaces
export AZ_RSRC_NAME=${AZ_RSRC_NAME}
EOF

# This variable configures the spark-monitoring library metrics sink.
# Any valid Spark metric.properties entry can be added here as well.
# It will get merged with the metrics.properties on the cluster.
cat > /databricks/spark/conf/metrics.properties << EOF
# This will enable the sink for all of the instances.
*.sink.loganalytics.class=org.apache.spark.metrics.sink.loganalytics.LogAnalyticsMetricsSink
*.sink.loganalytics.period=${SPARK_METRICS_PERIOD}
*.sink.loganalytics.unit=seconds

# Enable JvmSource for instance master, worker, driver and executor
master.source.jvm.class=org.apache.spark.metrics.source.JvmSource
worker.source.jvm.class=org.apache.spark.metrics.source.JvmSource
driver.source.jvm.class=org.apache.spark.metrics.source.JvmSource
executor.source.jvm.class=org.apache.spark.metrics.source.JvmSource
EOF

# This will enable master/worker metrics
cat << EOF >> /databricks/spark/conf/spark-defaults.conf
spark.metrics.conf /databricks/spark/conf/metrics.properties
EOF

cat << EOF > "/databricks/driver/conf/00-loganalytics-dropwizzard.conf"
[driver] {
    "spark.unifiedListener.sink" = "org.apache.spark.listeners.sink.loganalytics.LogAnalyticsListenerSink"
}
EOF
