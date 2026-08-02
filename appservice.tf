# appservice.tf
resource "azurerm_service_plan" "this" {
  name                = "asp-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  tags                = local.common_tags
}

resource "azurerm_linux_web_app" "this" {
  name                      = "app-${local.name_prefix}-${random_string.suffix.result}"
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_service_plan.this.location
  service_plan_id           = azurerm_service_plan.this.id
  virtual_network_subnet_id = azurerm_subnet.appsvc.id
  https_only                = true
  tags                      = local.common_tags

  site_config {
    always_on           = true
    minimum_tls_version = "1.2"
    application_stack {
      dotnet_version = "8.0"
    }
  }

  app_settings = {
    "ENVIRONMENT" = var.environment
  }
}

resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.this.id
  https_only     = true
  tags           = local.common_tags

  site_config {
    minimum_tls_version = "1.2"
    application_stack {
      dotnet_version = "8.0"
    }
  }
}
