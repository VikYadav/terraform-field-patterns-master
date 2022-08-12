terraform {
  required_providers {
    databricks = {
      source = "databrickslabs/databricks"
    }
  }
}

variable "databricks_resource_id" {
  description = "The Azure resource ID for the databricks workspace deployment."
}

locals {
  resource_regex            = "(?i)subscriptions/.+/resourceGroups/(.+)/providers/Microsoft.Databricks/workspaces/(.+)"
  resource_group            = regex(local.resource_regex, var.databricks_resource_id)[0]
  databricks_workspace_name = regex(local.resource_regex, var.databricks_resource_id)[1]
}

data "azurerm_databricks_workspace" "this" {
  name                = local.databricks_workspace_name
  resource_group_name = local.resource_group
}

data "azurerm_resource_group" "this" {
  name = local.resource_group
}

resource "azurerm_public_ip" "this" {
  name                = replace(data.azurerm_resource_group.this.name, "rg", "sandbox-ip")
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  tags                = data.azurerm_resource_group.this.tags

  allocation_method = "Dynamic"
}

data "http" "this_ip" {
  // retrieve this IP address for firewall opening
  url = "https://ifconfig.me"
}

resource "azurerm_network_security_group" "this" {
  name                = replace(data.azurerm_resource_group.this.name, "rg", "sandbox-nsg")
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  tags                = data.azurerm_resource_group.this.tags

  security_rule {
    name                       = "${data.http.this_ip.body} to SSH"
    description                = "Allows work laptop (${data.http.this_ip.body}) to SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${data.http.this_ip.body}/32"
    destination_address_prefix = "*"
  }
}

variable "vnet_cidr" {
  default = "10.5.0.0/26"
}

resource "azurerm_virtual_network" "this" {
  name                = replace(data.azurerm_resource_group.this.name, "rg", "sandbox-vnet")
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  tags                = data.azurerm_resource_group.this.tags
  address_space       = [var.vnet_cidr]
}

resource "azurerm_subnet" "public" {
  name                 = replace(data.azurerm_resource_group.this.name, "rg", "sandbox-public-sn")
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.this.address_space[0], 3, 0)]
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_network_interface" "this" {
  name                = replace(data.azurerm_resource_group.this.name, "rg", "sandbox-nic")
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  tags                = data.azurerm_resource_group.this.tags

  ip_configuration {
    name                          = replace(data.azurerm_resource_group.this.name, "rg", "sandbox-nic")
    subnet_id                     = azurerm_subnet.public.id
    public_ip_address_id          = azurerm_public_ip.this.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

data "external" "env" {
  program = ["python", "-c", "import sys,os,json;json.dump(dict(os.environ), sys.stdout)"]
}

resource "azurerm_user_assigned_identity" "this" {
  name                = replace(data.azurerm_resource_group.this.name, "rg", "identity")
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  tags                = data.azurerm_resource_group.this.tags
}

resource "azurerm_role_assignment" "user_assigned" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = "${data.azurerm_subscription.current.id}${data.azurerm_role_definition.contributor.id}"
  principal_id       = azurerm_user_assigned_identity.this.principal_id
}

provider "databricks" {
  host = data.azurerm_databricks_workspace.this.workspace_url
}

resource "azurerm_linux_virtual_machine" "user_assigned_msi" {
  name                  = replace(data.azurerm_resource_group.this.name, "rg", "user-assigned-msi-vm")
  resource_group_name   = data.azurerm_resource_group.this.name
  location              = data.azurerm_resource_group.this.location
  tags                  = data.azurerm_resource_group.this.tags
  network_interface_ids = [azurerm_network_interface.this.id]
  size                  = "Standard_DS1_v2" # todo: make it smaller

  os_disk {
    name                 = "main"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-hirsute"
    sku       = "21_04"
    version   = "latest"
  }

  computer_name                   = replace(data.azurerm_resource_group.this.name, "rg", "user-assigned-msi-vm")
  disable_password_authentication = true
  admin_username                  = data.external.env.result.USER

  admin_ssh_key {
    username   = data.external.env.result.USER
    public_key = file("~/.ssh/id_rsa.pub")
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }
}

output "ssh_command_for_user_assigned" {
  value = "ssh ${azurerm_linux_virtual_machine.user_assigned_msi.public_ip_address}"
}

resource "azurerm_public_ip" "this2" {
  name                = replace(data.azurerm_resource_group.this.name, "rg", "system-msi-ip")
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  tags                = data.azurerm_resource_group.this.tags

  allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "system_assigned_msi_vm" {
  name                = replace(data.azurerm_resource_group.this.name, "rg", "system-msi-nic")
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  tags                = data.azurerm_resource_group.this.tags

  ip_configuration {
    name                          = replace(data.azurerm_resource_group.this.name, "rg", "system-msi-nic")
    subnet_id                     = azurerm_subnet.public.id
    public_ip_address_id          = azurerm_public_ip.this2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "samsi" {
  network_interface_id      = azurerm_network_interface.system_assigned_msi_vm.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_linux_virtual_machine" "system_assigned" {
  name                  = replace(data.azurerm_resource_group.this.name, "rg", "system-msi-vm")
  resource_group_name   = data.azurerm_resource_group.this.name
  location              = data.azurerm_resource_group.this.location
  tags                  = data.azurerm_resource_group.this.tags
  network_interface_ids = [azurerm_network_interface.system_assigned_msi_vm.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "main3"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-hirsute"
    sku       = "21_04"
    version   = "latest"
  }

  computer_name                   = replace(data.azurerm_resource_group.this.name, "rg", "system-msi-vm")
  disable_password_authentication = true
  admin_username                  = data.external.env.result.USER

  admin_ssh_key {
    username   = data.external.env.result.USER
    public_key = file("~/.ssh/id_rsa.pub")
  }

  identity {
    type = "SystemAssigned"
  }
}

data "azurerm_subscription" "current" {}

data "azurerm_role_definition" "contributor" {
  name = "Contributor"
}

resource "azurerm_role_assignment" "example" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = "${data.azurerm_subscription.current.id}${data.azurerm_role_definition.contributor.id}"
  principal_id       = azurerm_linux_virtual_machine.system_assigned.identity[0].principal_id
}

output "ssh_command_for_system_assigned" {
  value = "ssh ${azurerm_linux_virtual_machine.system_assigned.public_ip_address}"
}