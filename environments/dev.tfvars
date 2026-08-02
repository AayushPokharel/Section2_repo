# environments/dev.tfvars
environment              = "dev"
location                 = "eastus"
location_short           = "eus"
vm_size                  = "Standard_B2s"
app_service_sku          = "S1"
storage_replication_type = "LRS"
mgmt_source_cidr         = "0.0.0.0/0" # replace with <your-public-ip>/32
