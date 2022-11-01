output "resource_group_name" {
  value = azurerm_resource_group.testVnet.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.vm1.public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.testpk1.private_key_pem
  sensitive = true
}