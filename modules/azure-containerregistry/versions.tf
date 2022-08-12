terraform {
  required_providers {
    databricks = {
      source  = "databrickslabs/databricks"
    }
    docker = {
      source = "kreuzwerker/docker"
      version = "2.11.0"
    }
  }
}