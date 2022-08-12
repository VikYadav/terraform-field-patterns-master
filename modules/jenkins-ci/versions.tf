terraform {
  required_providers {
    jenkins = {
      source = "taiidani/jenkins"
      version = "0.7.0-beta2"
    }
    github = {
      source = "integrations/github"
      version = "4.5.1"
    }
  }
}