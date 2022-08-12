provider "docker" {
  registry_auth {
    address = azurerm_container_registry.this.login_server
    username = azurerm_container_registry.this.admin_username
    password = azurerm_container_registry.this.admin_password
  }
}

resource "docker_registry_image" "this" {
  name = "${azurerm_container_registry.this.login_server}/sample:latest"
  build {
    context = abspath(path.module)
  }
}

