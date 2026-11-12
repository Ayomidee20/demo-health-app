# No default: the repo is public, so IDs come from a git-ignored
# terraform.tfvars (see terraform.tfvars.example).
variable "subscription_id" {
  description = "Azure subscription that holds the Terraform state storage."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a subscription ID (a GUID)."
  }
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

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.pipeline_principal_id))
    error_message = "pipeline_principal_id must be an Entra object ID (a GUID)."
  }
}
