# These feed the app pipeline's variable group (Phase 4/5).

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "acr_name" {
  description = "Used by `az acr login --name ...` in the app pipeline."
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Image prefix: <acr_login_server>/healthapp:<tag>."
  value       = azurerm_container_registry.main.login_server
}

output "container_app_name" {
  description = "Used by `az containerapp update --name ...` in the app pipeline."
  value       = azurerm_container_app.main.name
}

output "container_app_url" {
  value = "https://${azurerm_container_app.main.ingress[0].fqdn}"
}
