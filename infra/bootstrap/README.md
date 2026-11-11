# Bootstrap — Terraform remote state

Run this once from your local machine to create the Azure Storage account
and blob container that holds your Terraform state.

This config uses **local state** (no backend block) because it's the
chicken-and-egg: you can't store state remotely before the remote store exists.

After applying, note the storage account name and container name —
you'll reference them in `infra/backend.tf`.
