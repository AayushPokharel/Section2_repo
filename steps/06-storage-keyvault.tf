# STEP 6 — Data services: uniqueness suffix, client_config data source, Storage, Key Vault
data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}

resource "azurerm_storage_account" "this" {
  name                       = "st${var.project}${var.environment}${random_string.suffix.result}"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  account_tier               = "Standard"
  account_replication_type   = var.storage_replication_type
  access_tier                = "Hot"
  min_tls_version            = "TLS1_2"
  https_traffic_only_enabled = true
  tags                       = local.common_tags
}

resource "azurerm_key_vault" "this" {
  name                       = "kv-${var.project}-${var.environment}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = local.common_tags
}
