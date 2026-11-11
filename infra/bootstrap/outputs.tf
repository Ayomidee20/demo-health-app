output "resource_group_name" {
  value = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}

output "container_name" {
  value = azurerm_storage_container.tfstate.name
}

output "storage_account_id" {
  description = "Scope to grant the pipeline's service connection Storage Blob Data Contributor on."
  value       = azurerm_storage_account.tfstate.id
}

# What infra/backend.tf contains. The key is per environment and set at init:
#   terraform init -backend-config="key=dev.tfstate"
output "backend_config" {
  value = <<-EOT
    backend "azurerm" {
      resource_group_name  = "${azurerm_resource_group.tfstate.name}"
      storage_account_name = "${azurerm_storage_account.tfstate.name}"
      container_name       = "${azurerm_storage_container.tfstate.name}"
      use_azuread_auth     = true
    }
  EOT
}
