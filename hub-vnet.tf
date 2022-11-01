locals {
  prefix-hub         = "hub"
  hub-location       = "eastus"
  hub-resource-group = "testVnet"
  shared-key         = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}

resource "azurerm_resource_group" "testVnet" {
  name     = local.hub-resource-group
  location = local.hub-location
}

resource "azurerm_virtual_network" "hub-vnet" {
  name                = "${local.prefix-hub}-vnet"
  location            = azurerm_resource_group.testVnet.location
  resource_group_name = azurerm_resource_group.testVnet.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "hub-spoke"
  }
}

resource "azurerm_network_security_group" "sshAllow" {
  name                = "allowSSHonly"
  location            = azurerm_resource_group.testVnet.location
  resource_group_name = azurerm_resource_group.testVnet.name
}

resource "azurerm_network_security_rule" "testVnetSecurity" {
  name                        = "SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = ["10.0.0.0/16","10.0.0.0/24","10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.testVnet.name
  network_security_group_name =  azurerm_network_security_group.sshAllow.name
}

resource "azurerm_subnet" "Sub1" {
  name                 = "Sub1"
  resource_group_name  = azurerm_resource_group.testVnet.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "Sub2" {
  name                 = "Sub2"
  resource_group_name  = azurerm_resource_group.testVnet.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "Sub3" {
  name                 = "Sub3"
  resource_group_name  = azurerm_resource_group.testVnet.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_subnet" "Sub4" {
  name                 = "Sub4"
  resource_group_name  = azurerm_resource_group.testVnet.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_storage_account" "testStorage" {
  name                = "teststorageaccount"
  resource_group_name = azurerm_resource_group.testVnet.name

  location                 = azurerm_resource_group.testVnet.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_network_interface" "testnic" {
  name                = "testnic"
  location            = azurerm_resource_group.testVnet.location
  resource_group_name = azurerm_resource_group.testVnet.name

  ip_configuration {
    name                          = "test_nic_configuration"
    subnet_id                     = azurerm_subnet.Sub1.id
    private_ip_address_allocation = "Dynamic"
  }
}

  resource "tls_private_key" "testpk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "vm1"
  location              = azurerm_resource_group.testVnet.location
  resource_group_name   = azurerm_resource_group.testVnet.name
  network_interface_ids = [azurerm_network_interface.testnic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "osDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9_0"
    version   = "9.0.2022081813"
  }

  computer_name                   = "vm1"
  admin_username                  = "vm1admin"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "vm1ssh"
    public_key = tls_private_key.testpk.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.testStorage.primary_blob_endpoint
  }

}

resource "azurerm_public_ip" "vmpublicip" {
  name                = "vmPublicIP"
  location            = azurerm_resource_group.testVnet.location
  resource_group_name = azurerm_resource_group.testVnet.name
  allocation_method   = "Dynamic"
}

