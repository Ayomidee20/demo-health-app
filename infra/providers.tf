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
}

provider "azurerm" {
  features {}
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
