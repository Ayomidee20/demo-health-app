# Infrastructure — Terraform

This directory holds the Terraform configuration for:

- Resource group
- Log Analytics workspace
- Azure Container Registry (ACR)
- User-assigned managed identity + AcrPull role assignment
- Container Apps Environment
- Container App (with health probes)

## Files to create

- `providers.tf` — azurerm provider and version constraints
- `backend.tf` — azurerm backend pointing at the bootstrap storage
- `variables.tf` — input variables (environment, location, etc.)
- `main.tf` — all resources
- `outputs.tf` — ACR login server, app URL, resource group name

## Environments

- `env/dev.tfvars` — dev-specific values
- `env/prod.tfvars` — prod-specific values
