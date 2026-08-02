# outputs.tf
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "linux_vm_public_ip" {
  description = "Public IP of the Linux web VM."
  value       = azurerm_public_ip.linux.ip_address
}

output "linux_vm_private_ip" {
  value = azurerm_network_interface.linux.private_ip_address
}

output "windows_vm_private_ip" {
  value = azurerm_network_interface.windows.private_ip_address
}

output "app_service_url" {
  description = "Production App Service URL."
  value       = "https://${azurerm_linux_web_app.this.default_hostname}"
}

output "app_service_staging_url" {
  value = "https://${azurerm_linux_web_app_slot.staging.default_hostname}"
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "linux_nic_name" {
  description = "Used by Network Watcher effective-routes checks."
  value       = azurerm_network_interface.linux.name
}
