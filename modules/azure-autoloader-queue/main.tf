/**
 * Creates Azure Databricks Autoloader for ADLSv2
 * Relies on the assumption that container is mounted and administrators want to pre-provision queues.
 *
 * This module replicates [setUpNotificationServices]( https://docs.microsoft.com/en-us/azure/databricks/spark/latest/structured-streaming/auto-loader#cloud-resource-management).
 */
variable "folder" {
  description = "Path on the container to create queue from"
}

variable "container_name" {
  description = "Name of storage container"
}

variable "storage_account_name" {
  description = "Name of storage account"
}

variable "resource_group_name" {
  description = "Name of resource group"
}

variable "mount_name" {
  description = "Name of the mount"
}

data "azurerm_storage_account" "this" {
  name = var.storage_account_name
  resource_group_name = var.resource_group_name
}

resource "time_static" "this" {}

locals {
  trimmed_folder = trimsuffix(var.folder, "/")
  streamId = replace(replace(local.trimmed_folder, "/", "-"), "_", "-")
  queue_name = lower("databricks-${local.streamId}")
  path = "/mnt/${var.mount_name}/${local.trimmed_folder}"
}

output "path" {
  description = "Path that is expected to be consumed from"
  value = local.path
}

resource "azurerm_storage_queue" "this" {
  name                 = local.queue_name
  storage_account_name = data.azurerm_storage_account.this.name
  metadata = {
    streamid = local.streamId
    path = "/${local.trimmed_folder}/"
    vendor = "Databricks"
  }
}

resource "azurerm_eventgrid_event_subscription" "this" {
  name  = local.queue_name
  scope = data.azurerm_storage_account.this.id

  storage_queue_endpoint {
    storage_account_id = data.azurerm_storage_account.this.id
    queue_name         = azurerm_storage_queue.this.name
  }

  subject_filter {
    subject_begins_with = "/blobServices/default/containers/${var.container_name}/blobs/${local.trimmed_folder}/"
  }

  advanced_filter {
    string_contains {
      key = "data.api"
      values = ["CopyBlob", "PutBlob", "PutBlockList",
        "DeleteBlob", "FlushWithClose", "DeleteFile"
      ]
    }
  }

  labels = [jsonencode({
    streamId = local.queue_name
    path = local.path
    creationTime = time_static.this.unix
    vendor = "Databricks"
    resourceTags = {}
  })]

  included_event_types = [
    "Microsoft.Storage.BlobCreated",
    "Microsoft.Storage.BlobDeleted"]

  retry_policy {
    event_time_to_live = 60*24
    max_delivery_attempts = 30
  }
}

output "queue_name" {
  value = azurerm_eventgrid_event_subscription.this.name
}
