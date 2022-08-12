#! /bin/bash

# increase partition size
sudo growpart /dev/xvda 1
sudo resize2fs /dev/xvda1

sudo apt-get install apt-transport-https

echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt update
sudo apt install elasticsearch kibana
sudo systemctl enable elasticsearch
sudo systemctl enable kibana

cat > /etc/elasticsearch/elasticsearch.yml << EOF
network.host: 0.0.0.0
discovery.seed_hosts: [${HOSTNAME}]

cluster:
  name: ${HOSTNAME}
  initial_master_nodes: 1

path:
  logs: /var/log/elasticsearch
  data: /var/lib/elasticsearch

index.number_of_replicas: 0
EOF

cat > /etc/kibana/kibana.yml << EOF
server.host: 0.0.0.0
EOF

sudo systemctl start elasticsearch
sudo systemctl start kibana