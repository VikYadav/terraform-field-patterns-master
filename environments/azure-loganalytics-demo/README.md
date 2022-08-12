# azure-loganalytics-demo

This demo environment creates 

* [Azure Databricks workspace in custom VNet](https://github.com/databricks/terraform-field-patterns/tree/master/modules/azure-vnet-injection)
* [Azue LogAnalytics workspace and all forwarding infrastructure](https://github.com/databricks/terraform-field-patterns/tree/master/modules/azure-loganalytics) for Spark application logs, VM utilization metrics (CPU, Mem, Network...), Diagnostic (Audit) logs
* [Audit for Databricks workspace sent through EventHubs and consumed in a streaming notebook](https://github.com/databricks/terraform-field-patterns/tree/master/modules/azure-audit-eventhubs)

If you'll see an error in the middle of deployment related to node type not foud, please repeat the `terraform apply` again.

#### You will need the following dependencies installed:
* terraform 0.13.x+
* Azure CLI
* To build https://github.com/mspnp/spark-monitoring (https://docs.microsoft.com/en-us/azure/architecture/databricks-monitoring/databricks-observability), you'd need:
    * JDK 1.8
    * Scala SDK 2.11
    * Maven 3.5.4
    * coreutils package (for `realpath` command)

[azure-log-analytics-integration](modules/azure-log-analytics-integration):
* Sends the oms agent init script to DBFS. 
* Enables diagnostic logging for databricks, sent to both ADLS and Log Analytics workspace.
* Creates log analytics workspace.
* Sends init script for spark application logs. Sends logs to Log Analytics workspace.
* The user may also configure this module to send certain logs to ADLS.
* Creates the necessary storage resources for logs to be sent to (or general-purpose storage).

#### IMPORTANT MANUAL STEP post-deployment
* In order for the logging agent installed by the init script to function properly, the following settings within the Log Analytics workspace must be manually changed in the Azure portal:
    * Enable Linux performance logging in "Advanced Settings"
    * Enable Syslog logging in "Advanced Settings"
* These are one-time changes required per Log Analytics workspace. Follow the below documentation:
    * Docs: https://docs.microsoft.com/en-us/azure/azure-monitor/learn/quick-collect-linux-computer#collect-event-and-performance-data
* Note: This may be able to be automated. Since not many Log Analytics workspaces will likely be spun up, it may not matter to the user. This is not needed if sending logs to ADLS.


Useful Documentation:
* Databricks Terraform Provider: https://registry.terraform.io/providers/databrickslabs/databricks/latest
* Azure Terraform Provider: https://www.terraform.io/docs/providers/azurerm/index.html
* Cluster Policies: https://docs.microsoft.com/en-us/azure/databricks/administration-guide/clusters/policies
