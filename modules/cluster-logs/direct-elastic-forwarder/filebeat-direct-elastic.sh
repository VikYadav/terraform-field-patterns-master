#!/usr/bin/env bash

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install filebeat && sudo systemctl enable filebeat

ELASTICSEARCH_HOST="10.138.217.238"

# https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-reference-yml.html
cat > /etc/filebeat/filebeat.yml << EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /databricks/driver/logs/stdout
    - /databricks/driver/logs/stderr
    - /databricks/driver/eventlogs/*/eventlog

  fields:
    cluster_id: ${DB_CLUSTER_ID}
    review: ${DB_IS_DRIVER}

output.elasticsearch:
  hosts: ["${ELASTICSEARCH_HOST}:9200"]
  index: "filebeat-%{+yyyy-MM-dd}"
EOF

