#! /bin/bash

# increase partition size
sudo growpart /dev/xvda 1
sudo resize2fs /dev/xvda1

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo BEGIN
sudo apt-get update
sudo apt-get upgrade -y
cd /tmp && wget -O splunk-8.0.3-a6754d8441bf-linux-2.6-amd64.deb 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.0.3&product=splunk&filename=splunk-8.0.3-a6754d8441bf-linux-2.6-amd64.deb&wget=true'
cd /opt
sudo dpkg -i /tmp/splunk-8.0.3-a6754d8441bf-linux-2.6-amd64.deb

export SPLUNK_HOME=/opt/splunk

cat > ${SPLUNK_HOME}/etc/apps/dbr/local/props.conf << EOF
[default]
TRUNCATE = 0
EOF

mkdir -p ${SPLUNK_HOME}/etc/apps/dbr/local
cat > ${SPLUNK_HOME}/etc/apps/dbr/local/indexes.conf << EOF
[cluster_logs]
coldPath = \$SPLUNK_DB/\$_index_name/colddb
homePath = \$SPLUNK_DB/\$_index_name/db
maxTotalDataSizeMB = 4096
thawedPath = \$SPLUNK_DB/\$_index_name/thaweddb
EOF

cat > ${SPLUNK_HOME}/etc/apps/dbr/local/inputs.conf << EOF
[splunktcp://9997]
connection_host = ip
EOF

mkdir -p ${SPLUNK_HOME}/etc/apps/dbr/local
cat > ${SPLUNK_HOME}/etc/apps/dbr/local/serverclass.conf << EOF
[serverClass:dbr_hosts:app:dbr]
restartSplunkWeb = 0
restartSplunkd = 1
stateOnClient = enabled

[serverClass:dbr_hosts]
machineTypesFilter = linux-x86_64
whitelist.0 = dbr-*
EOF

# /databricks/driver/logs/active.log - log4j + json occasionally
# /databricks/driver/logs/usage.json - JSON
# /databricks/driver/logs/stdout - random - > GC logs
# /databricks/driver/logs/stderr - everything from notebooks
# /databricks/driver/eventlogs/*/eventlog - JSON, event log, USEFUL, may be sensitive!!! :)
# /databricks/spark/work/*/0/stderr - log4j
# /databricks/spark/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-0714-183412-meats4-10-138-233-255.out - log4j
# /databricks/driver/logs/log4j-active.log - log4j
#

mkdir -p ${SPLUNK_HOME}/etc/deployment-apps/dbr/default
cat > ${SPLUNK_HOME}/etc/deployment-apps/dbr/default/inputs.conf << EOF
[monitor:///databricks/driver/logs]
disabled = false
index = cluster_logs

[monitor:///databricks/spark/work]
disabled = false
index = cluster_logs

[monitor:///databricks/spark/logs]
disabled = false
index = cluster_logs

[monitor:///databricks/driver/eventlogs]
disabled = false
index = cluster_logs

[monitor:///databricks/driver/derby.log]
disabled = false
sourcetype = derby
index = cluster_logs

[monitor:///databricks/init_scripts/*.log]
disabled = false
sourcetype = init_scripts
index = cluster_logs

[monitor:///databricks/data/logs]
disabled = false
index = cluster_logs
EOF

cat > ${SPLUNK_HOME}/etc/deployment-apps/dbr/default/outputs.conf << EOF
[tcpout]
defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = ${HOSTNAME}:9997

[tcpout-server://${HOSTNAME}:9997]
connection_host = ip
EOF

cd splunk/
/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --gen-and-print-passwd
cd -


echo "{\"password\": \"$(grep -A1 password /var/log/user-data.log | tail -n1)\"}" > /home/ubuntu/admin.json

echo END