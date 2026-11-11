locals {
  # e.g. "healthapp-dev": the common middle of every resource name.
  name = "${var.project}-${var.environment}"

  tags = merge(
    {
      project     = var.project
      environment = var.environment
      managed_by  = "terraform"
    },
    var.tags,
  )
}

# ---------- Resource group: everything for one environment ----------

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

# ---------- Logs: where the Container Apps Environment sends app output ----------

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Pay per GB ingested. 30 days is the minimum (and free) retention.
  sku               = "PerGB2018"
  retention_in_days = 30

  tags = local.tags
}

# ---------- Container registry: where the app pipeline pushes images ----------

# ACR names are global across Azure, 5-50 chars, letters and digits only
# (no hyphens), so the usual "acr-healthapp-dev" pattern isn't allowed.
resource "random_string" "acr_suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_container_registry" "main" {
  name                = "acr${var.project}${var.environment}${random_string.acr_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Basic is enough for one app; the manual deploy used Standard (more cost).
  sku = "Basic"

  # No shared admin username/password. The Container App pulls with its
  # managed identity, the pipeline pushes with its service connection.
  admin_enabled = false

  tags = local.tags
}

# ---------- Identity the Container App runs as, allowed to pull images ----------

resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${local.name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags
}

resource "azurerm_role_assignment" "app_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.app.principal_id

  # A brand-new identity can take a minute to be visible everywhere in
  # Entra ID. Stating its type skips a lookup that fails during that gap.
  principal_type = "ServicePrincipal"
}

# ---------- Container Apps Environment: the shared platform (like an ECS cluster) ----------

resource "azurerm_container_app_environment" "main" {
  name                = "cae-${local.name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Container stdout/stderr and system logs go to Log Analytics.
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = local.tags
}

# ---------- Key Vault: holds the Flask secret key (like SSM Parameter Store SecureString) ----------

# Who is running Terraform: you locally, or the pipeline's service connection.
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  # Global name, 3-24 chars. Reuses the ACR's random suffix: kv-healthapp-dev-pgcdm
  name                = "kv-${local.name}-${random_string.acr_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Access is granted with Azure RBAC roles (like IAM), not legacy access policies.
  rbac_authorization_enabled = true

  # Short soft-delete window and no purge protection, so the environment can
  # be destroyed and recreated freely. A real prod vault would enable purge protection.
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = local.tags
}

# Whoever runs Terraform may create/update secrets (needed to create the
# placeholder secret below). Data-plane role: Contributor alone can't read or
# write secret values.
resource "azurerm_role_assignment" "terraform_kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# The app's identity may only read secret values.
resource "azurerm_role_assignment" "app_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
  principal_type       = "ServicePrincipal"
}

# New role assignments take a minute or two to take effect. Without this
# pause, creating the secret (or the app reading it) fails with a 403.
resource "time_sleep" "wait_for_kv_roles" {
  create_duration = "90s"

  depends_on = [
    azurerm_role_assignment.terraform_kv_secrets_officer,
    azurerm_role_assignment.app_kv_secrets_user,
  ]
}

# Terraform creates the secret with a dummy value and then ignores its value
# forever. The real value is set by hand (az keyvault secret set), so it never
# appears in Terraform state, a plan file, the pipeline or the repo.
resource "azurerm_key_vault_secret" "flask_secret_key" {
  name         = "flask-secret-key"
  value        = "replace-me-outside-terraform"
  key_vault_id = azurerm_key_vault.main.id

  lifecycle {
    ignore_changes = [value]
  }

  depends_on = [time_sleep.wait_for_kv_roles]
}

# ---------- The app itself (like an ECS service + ALB) ----------

resource "azurerm_container_app" "main" {
  # Becomes the start of the public URL: https://healthapp-dev.<random>.westus2.azurecontainerapps.io
  name                         = local.name
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id

  # One active revision at a time: a new deploy replaces the old one.
  revision_mode = "Single"

  # Run as the managed identity that has AcrPull...
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  # ...and use it to pull from our ACR. No registry passwords anywhere.
  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.app.id
  }

  # A reference, not a value: Container Apps fetches the secret from Key Vault
  # with the app's identity (like ECS "valueFrom" pointing at Parameter Store).
  # versionless_id = always the latest version, so updating it in Key Vault
  # needs no Terraform change.
  secret {
    name                = "flask-secret-key"
    key_vault_secret_id = azurerm_key_vault_secret.flask_secret_key.versionless_id
    identity            = azurerm_user_assigned_identity.app.id
  }

  ingress {
    external_enabled = true # public HTTPS URL (the manual deploy defaulted to internal)
    target_port      = var.target_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "healthapp"
      image  = var.placeholder_image
      cpu    = var.container_cpu
      memory = var.container_memory

      # Read by the placeholder only (makes whoami listen on 3000).
      # Harmless leftover once the real app replaces it.
      env {
        name  = "WHOAMI_PORT_NUMBER"
        value = tostring(var.target_port)
      }

      env {
        name        = "FLASK_SECRET_KEY"
        secret_name = "flask-secret-key"
      }

      # Restart the container if /healthcheck stops answering.
      liveness_probe {
        transport = "HTTP"
        port      = var.target_port
        path      = "/healthcheck"
      }

      # Only send traffic once /healthcheck answers.
      readiness_probe {
        transport = "HTTP"
        port      = var.target_port
        path      = "/healthcheck"
      }
    }
  }

  lifecycle {
    # The app pipeline owns the image (az containerapp update --image ...).
    # Without this, every terraform apply would roll the app back to the placeholder.
    ignore_changes = [template[0].container[0].image]
  }

  # Nothing above references these role assignments, so Terraform can't infer
  # the order. AcrPull must exist before the app pulls from ACR, and the Key
  # Vault read role must be active before the app fetches its secret.
  depends_on = [
    azurerm_role_assignment.app_acr_pull,
    time_sleep.wait_for_kv_roles,
  ]

  tags = local.tags
}
