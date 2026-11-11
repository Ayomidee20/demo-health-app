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
  }

  # No backend block on purpose: this config creates the remote backend,
  # so its own state stays local (terraform.tfstate in this folder).
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id

  # Storage data-plane calls (blob service polling, containers, blobs) use your
  # Entra ID token instead of account keys. Required because the account has
  # shared_access_key_enabled = false; without it the provider gets a 403.
  storage_use_azuread = true
}
