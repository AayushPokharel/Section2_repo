# variables.tf
variable "project" {
  description = "Short workload name used in resource naming."
  type        = string
  default     = "heapp"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, prod."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "location_short" {
  description = "Short region code used in naming."
  type        = string
  default     = "eus"
}

variable "vm_size" {
  description = "SKU size for both VMs."
  type        = string
  default     = "Standard_B2s"
}

variable "storage_replication_type" {
  description = "Storage account replication (LRS, ZRS, GRS...)."
  type        = string
  default     = "LRS"
}

variable "admin_username" {
  description = "Local admin username for both VMs."
  type        = string
  default     = "azureadmin"
}

variable "admin_ssh_public_key" {
  description = "Path to the SSH public key for the Linux VM."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "windows_admin_password" {
  description = "Local admin password for the Windows VM (set via TF_VAR_windows_admin_password)."
  type        = string
  sensitive   = true
}

variable "mgmt_source_cidr" {
  description = "Source CIDR permitted to SSH into the web tier. Tighten to <your-ip>/32."
  type        = string
  default     = "0.0.0.0/0"
}

variable "extra_tags" {
  description = "Additional tags merged onto every resource."
  type        = map(string)
  default     = {}
}
