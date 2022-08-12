#!/usr/bin/env bash

#SPLUNK_DEPLOYMENT_HOST="${splunk_host}"
. /dbfs/databricks/scripts/splunk-host.sh

DBFS_SPLUNK_DOWNLOAD="/dbfs/tmp"
SPLUNK_FORWARDER_ARTIFACT="https://download.splunk.com/products/universalforwarder/releases/8.0.3/linux/splunkforwarder-8.0.3-a6754d8441bf-Linux-x86_64.tgz"

set -e
SPLUNK_FORWARDER_ARTIFACT_NAME=$(basename "${SPLUNK_FORWARDER_ARTIFACT}")
SPLUNK_FORWARDER_DOWNLOADED_FILE="${DBFS_SPLUNK_DOWNLOAD}/${SPLUNK_FORWARDER_ARTIFACT_NAME}"
LCKFILE="${DBFS_SPLUNK_DOWNLOAD}/.LOCK"

SPLUNK_FORWARDER_INSTALL="/opt"
SPLUNK_HOME="${SPLUNK_FORWARDER_INSTALL}/splunkforwarder"

echo "export SPLUNK_HOME=${SPLUNK_HOME}" >> /home/ubuntu/.profile

# sleep if download lock file exists
sleep 0.$[ ( $RANDOM % 1000 ) ]s
i=0
while [ -e ${LCKFILE} ] && [ $i -lt 30 ]; do
  echo "[*] Lock file exists. Sleeping while ${SPLUNK_FORWARDER_ARTIFACT_NAME} " \
       "is downloaded to ${DBFS_SPLUNK_DOWNLOAD} by $(cat ${LCKFILE})####"
  let i=i+1
  sleep 1
done

# If the splunk unervisal forwarder installer does not exist, download it from the splunk website
if ! [ -e ${SPLUNK_FORWARDER_DOWNLOADED_FILE} ]; then
  mkdir -p ${DBFS_SPLUNK_DOWNLOAD}
  printf $(hostname) > ${LCKFILE}
  echo "[*] Downloading ${SPLUNK_FORWARDER_ARTIFACT_NAME} to ${DBFS_SPLUNK_DOWNLOAD}"
  set +e
  curl -s "${SPLUNK_FORWARDER_ARTIFACT}" -o ${SPLUNK_FORWARDER_DOWNLOADED_FILE} || { rm ${LCKFILE}; exit 1; }
  curl -s "${SPLUNK_FORWARDER_ARTIFACT}.md5" -o ${SPLUNK_FORWARDER_DOWNLOADED_FILE}.md5 || { rm ${LCKFILE}; exit 1; }
  rm ${LCKFILE}
  set -e
fi

echo "[*] Installing from ${SPLUNK_FORWARDER_DOWNLOADED_FILE}"
(cd ${DBFS_SPLUNK_DOWNLOAD} && md5sum -c "${SPLUNK_FORWARDER_ARTIFACT_NAME}.md5")
mkdir -p "${SPLUNK_FORWARDER_INSTALL}"
[ -e "${SPLUNK_HOME}" ] && rm -rf "${SPLUNK_HOME}"
tar -xzf ${SPLUNK_FORWARDER_DOWNLOADED_FILE} -C "${SPLUNK_FORWARDER_INSTALL}"

#Configure deployment client
mkdir -p ${SPLUNK_HOME}/etc/apps/local/default
cat > ${SPLUNK_HOME}/etc/apps/local/default/deploymentclient.conf << EOF
[deployment-client]
clientName = dbr-${HOSTNAME}

[target-broker:deploymentServer]
targetUri = ${SPLUNK_DEPLOYMENT_HOST}:8089
EOF

#Add DB_CLUSTER_ID & DB_IS_DRIVER as indexed fields/meta data to the events
cat > ${SPLUNK_HOME}/etc/apps/local/default/inputs.conf << EOF
[default]
_meta = DB_CLUSTER_ID::${DB_CLUSTER_ID} DB_IS_DRIVER::${DB_IS_DRIVER}
EOF

${SPLUNK_HOME}/bin/splunk start --accept-license --answer-yes --no-prompt