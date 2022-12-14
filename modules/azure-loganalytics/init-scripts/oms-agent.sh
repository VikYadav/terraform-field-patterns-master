#!/bin/bash

sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d
wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh
sh onboard_agent.sh -w ${LOG_ANALYTICS_WORKSPACE_ID} -s ${LOG_ANALYTICS_WORKSPACE_KEY}
sudo su omsagent -c 'python /opt/microsoft/omsconfig/Scripts/PerformRequiredConfigurationChecks.py'
/opt/microsoft/omsagent/bin/service_control restart ${LOG_ANALYTICS_WORKSPACE_ID}
