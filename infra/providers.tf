terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Deleted vaults are kept for 7 days ("soft delete") and block reusing
      # the name. Purge on destroy so create -> destroy -> create works.
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.subscription_id

  # azurerm registers a "core" set of resource providers on the subscription
  # by default. Container Apps and Log Analytics may not be in it, so ask for
  # them explicitly. Registration is a one-time, subscription-wide switch,
  # like enabling a service in a new AWS account.
  resource_providers_to_register = [
    "Microsoft.App",
    "Microsoft.OperationalInsights",
  ]
}
