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

resource "azurerm_network_interface" "testnic1" {
  name                = "testnic1"
  location            = azurerm_resource_group.testVnet.location
  resource_group_name = azurerm_resource_group.testVnet.name

  ip_configuration {
    name                          = "test_nic_configuration1"
    subnet_id                     = azurerm_subnet.Sub1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1publicip.id
  }
}

resource "azurerm_network_interface" "testnic2" {
  name                = "testnic2"
  location            = azurerm_resource_group.testVnet.location
  resource_group_name = azurerm_resource_group.testVnet.name

  ip_configuration {
    name                          = "test_nic_configuration2"
    subnet_id                     = azurerm_subnet.Sub1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm2publicip.id
  }
}

resource "tls_private_key" "testpk1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "testpk2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "vm1"
  location              = azurerm_resource_group.testVnet.location
  resource_group_name   = azurerm_resource_group.testVnet.name
  network_interface_ids = [azurerm_network_interface.testnic1.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "osDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9.0"
    version   = "9.0.2022081813"
  }

  computer_name                   = "vm1"
  admin_username                  = "vm1admin"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "vm1ssh"
    public_key = tls_private_key.testpk1.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.testStorage.primary_blob_endpoint
  }

}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                  = "vm2"
  location              = azurerm_resource_group.testVnet.location
  resource_group_name   = azurerm_resource_group.testVnet.name
  network_interface_ids = [azurerm_network_interface.testnic2.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "osDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9.0"
    version   = "9.0.2022081813"
  }

  computer_name                   = "vm2"
  admin_username                  = "vm2admin"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "vm2ssh"
    public_key = tls_private_key.testpk2.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.testStorage.primary_blob_endpoint
  }

}

resource "azurerm_public_ip" "vm1publicip" {
  name                = "vm1PublicIP"
  location            = azurerm_resource_group.testVnet.location
  resource_group_name = azurerm_resource_group.testVnet.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "vm2publicip" {
  name                = "vm2PublicIP"
  location            = azurerm_resource_group.testVnet.location
  resource_group_name = azurerm_resource_group.testVnet.name
  allocation_method   = "Dynamic"
}

