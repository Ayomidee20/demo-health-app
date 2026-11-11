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

# Lets you read and write state blobs from your laptop. The pipeline gets
# the same role below.
# Scoped to the resource group (which holds only the state account) rather than
# the account itself, so it can exist before the account is created.
resource "azurerm_role_assignment" "state_rw_current_user" {
  scope                = azurerm_resource_group.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ---------- The pipeline's identity (sp-healthapp-ado) ----------
# It already has Contributor on the subscription (assigned when the service
# connection was created). Contributor can create resources, but it can't
# touch blob data or create role assignments, so it needs these two extras.

# 1. Read and write the state files (data plane, like s3:GetObject/PutObject
#    on the state bucket).
resource "azurerm_role_assignment" "state_rw_pipeline" {
  scope                = azurerm_resource_group.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.pipeline_principal_id
  principal_type       = "ServicePrincipal"
}

# 2. Create and delete role assignments, but ONLY for the three roles the main
#    config hands out. Without the condition this role could grant anyone
#    Owner (like iam:PassRole/iam:AttachRolePolicy with no resource limit).
locals {
  # Built-in role definition IDs (the same in every tenant).
  delegable_role_ids = join(", ", [
    "7f951dda-4ed3-4680-a7ca-43fe172d538d", # AcrPull                  (app pulls images)
    "4633458b-17de-408a-b874-0445c86b69e6", # Key Vault Secrets User    (app reads its secret)
    "b86a8fe4-44ce-4948-aee5-eccb2c155cd7", # Key Vault Secrets Officer (Terraform writes the placeholder)
  ])
}

resource "azurerm_role_assignment" "rbac_admin_pipeline" {
  # Subscription scope: the resource groups it assigns roles in are created
  # and destroyed by the pipeline itself.
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = var.pipeline_principal_id
  principal_type       = "ServicePrincipal"

  # ABAC condition: a write (create) is allowed only if the role being granted
  # is in the list, and a delete only if the existing assignment's role is.
  condition_version = "2.0"
  condition         = <<-EOT
    (
      (
        !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
      )
      OR
      (
        @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.delegable_role_ids}}
      )
    )
    AND
    (
      (
        !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
      )
      OR
      (
        @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.delegable_role_ids}}
      )
    )
  EOT
}
