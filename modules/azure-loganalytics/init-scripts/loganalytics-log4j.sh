#!/usr/bin/env bash

set -e
#set -o pipefail

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

log4jDirectories=( "executor" "driver" "master-worker" )

for log4jDirectory in "$${log4jDirectories[@]}"; do

# TODO: conf or dbconf
LOG4J_CONFIG_FILE="/databricks/spark/dbconf/log4j/$log4jDirectory/log4j.properties"
echo "BEGIN: Updating $LOG4J_CONFIG_FILE with Log Analytics appender"
sed -i 's/log4j.rootCategory=.*/&, logAnalyticsAppender/g' $${LOG4J_CONFIG_FILE}

cat >> $LOG4J_CONFIG_FILE << EOF
# logAnalytics
log4j.appender.logAnalyticsAppender=com.microsoft.pnp.logging.loganalytics.LogAnalyticsAppender
log4j.appender.logAnalyticsAppender.filter.spark=com.microsoft.pnp.logging.SparkPropertyEnricher
EOF

echo "END: Updating $LOG4J_CONFIG_FILE with Log Analytics appender"

done

# The spark.extraListeners property has an entry from Databricks by default.
# We have to read it here because we did not find a way to get this setting when the init script is running.
# If Databricks changes the default value of this property, it needs to be changed here.
cat << EOF > "/databricks/driver/conf/00-loganalytics-log4j.conf"
[driver] {
    "spark.extraListeners" = "com.databricks.backend.daemon.driver.DBCEventLoggingListener,org.apache.spark.listeners.UnifiedSparkListener"
}
EOF
