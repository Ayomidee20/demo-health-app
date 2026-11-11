# Remote state in the storage created by infra/bootstrap.
#
# `key` is deliberately missing (partial configuration): each environment has
# its own state file, chosen at init time:
#
#   terraform init -backend-config="key=dev.tfstate"
#   terraform init -reconfigure -backend-config="key=prod.tfstate"
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-healthapp-tfstate"
    storage_account_name = "sthealthapptf4umma6"
    container_name       = "tfstate"

    # Sign in with Entra ID (az login locally, the service connection in the
    # pipeline). Required: the storage account has key auth disabled.
    use_azuread_auth = true
  }
}
