variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the VM will be created"
  default     = "rg-terraform-vm-demo"
}

variable "location" {
  type        = string
  description = "The Azure region for the resources"
  default     = "West Europe" # You can change this to your preferred region
}

variable "vm_name" {
  type        = string
  description = "The name of the Virtual Machine"
  default     = "my-linux-vm"
}

variable "admin_username" {
  type        = string
  description = "The username for the VM admin"
  default     = "azureuser"
}

# This variable is marked as sensitive so its value won't show in logs
# It matches the TF_VAR_admin_password in your YAML
variable "admin_password" {
  type        = string
  description = "The password for the VM admin user"
  sensitive   = true
}