# STEP 5 — Windows data VM (private NIC + VM)
resource "azurerm_network_interface" "windows" {
  name                = "nic-win-${local.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.data.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "data" {
  name                  = "vm-data-win-${var.environment}"
  computer_name         = "vmdatawin"
  resource_group_name   = azurerm_resource_group.this.name
  location              = azurerm_resource_group.this.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.windows_admin_password
  network_interface_ids = [azurerm_network_interface.windows.id]
  tags                  = local.common_tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}
