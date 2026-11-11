variable "subscription_id" {
  description = "Azure subscription that holds the Terraform state storage."
  type        = string
  default     = "651d3386-8e30-4607-abfc-b1817d173f84"
}

variable "location" {
  description = "Azure region for the state storage. Keep it the same as the app's region."
  type        = string
  default     = "westus2"
}

variable "resource_group_name" {
  description = "Resource group that holds only the Terraform state storage."
  type        = string
  default     = "rg-healthapp-tfstate"
}

variable "storage_account_prefix" {
  description = "Prefix for the storage account name. A random suffix is added because names are global."
  type        = string
  default     = "sthealthapptf"

  validation {
    condition     = can(regex("^[a-z0-9]{3,18}$", var.storage_account_prefix))
    error_message = "Use 3-18 lowercase letters or digits; 6 random characters are appended (24 max)."
  }
}

variable "container_name" {
  description = "Blob container that holds the state files."
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Tags applied to every bootstrap resource."
  type        = map(string)
  default = {
    project    = "healthapp"
    purpose    = "terraform-state"
    managed_by = "terraform-bootstrap"
  }
}

variable "pipeline_principal_id" {
  description = "Object ID of the pipeline's service principal (sp-healthapp-ado), used by the ADO service connection sc-healthapp-azure."
  type        = string
  default     = "af54ca36-0f95-4a72-bcf4-b4a175ced35b"
}
