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

# Paste this into infra/backend.tf in Phase 2.
output "backend_config" {
  value = <<-EOT
    backend "azurerm" {
      resource_group_name  = "${azurerm_resource_group.tfstate.name}"
      storage_account_name = "${azurerm_storage_account.tfstate.name}"
      container_name       = "${azurerm_storage_container.tfstate.name}"
      key                  = "healthapp.tfstate"
      use_azuread_auth     = true
    }
  EOT
}
