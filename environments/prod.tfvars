# environments/prod.tfvars
environment              = "prod"
location                 = "eastus2"
location_short           = "eus2"
vm_size                  = "Standard_D2s_v5"
app_service_sku          = "P1v3"
storage_replication_type = "GRS"
mgmt_source_cidr         = "0.0.0.0/0"
