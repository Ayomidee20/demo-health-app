# Who is running `terraform apply` right now (your `az login` user).
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Storage account names are global across all of Azure, 3-24 chars,
# lowercase letters and digits only. The suffix avoids collisions.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "${var.storage_account_prefix}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  # No storage account keys. Everything (you, the pipeline) authenticates
  # with Entra ID and needs an RBAC role on the account instead.
  shared_access_key_enabled = false

  blob_properties {
    # Every write to a state file keeps the previous version, so a bad
    # apply or a corrupted state can be rolled back.
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags

  # The provider polls the blob service with your Entra token as soon as the
  # account exists, so your data-plane role must already be in place.
  depends_on = [azurerm_role_assignment.state_rw_current_user]
}

# storage_account_id (not storage_account_name) makes the provider create the
# container through Azure Resource Manager, so it works without account keys
# and without waiting for the data-plane role below to propagate.
resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# Lets you read and write state blobs from your laptop. The pipeline's
# service connection gets the same role later, in Phase 3.
# Scoped to the resource group (which holds only the state account) rather than
# the account itself, so it can exist before the account is created.
resource "azurerm_role_assignment" "state_rw_current_user" {
  scope                = azurerm_resource_group.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
