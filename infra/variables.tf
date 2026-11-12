# No default: the repo is public, so IDs come from a git-ignored
# terraform.tfvars locally (see terraform.tfvars.example) and from the
# service connection / pipeline variables in the infra pipeline.
variable "subscription_id" {
  description = "Azure subscription to deploy into."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a subscription ID (a GUID)."
  }
}

variable "environment" {
  description = "Environment name; used in every resource name and tag."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be \"dev\" or \"prod\"."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "westus2"
}

variable "project" {
  description = "Short project name used in resource names."
  type        = string
  default     = "healthapp"
}

# ---------- Container App sizing ----------

variable "container_cpu" {
  description = "vCPU per replica. Container Apps only accepts fixed CPU/memory pairs (0.25/0.5Gi, 0.5/1Gi, 1/2Gi ...)."
  type        = number
  default     = 0.25
}

variable "container_memory" {
  description = "Memory per replica; must be 2x the CPU value, e.g. \"0.5Gi\" for 0.25 vCPU."
  type        = string
  default     = "0.5Gi"
}

variable "min_replicas" {
  description = "Minimum replicas. 1 keeps a warm replica; 0 would scale to zero (no idle cost, slow first request)."
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum replicas under load."
  type        = number
  default     = 1
}

variable "target_port" {
  description = "Port the app listens on inside the container (gunicorn binds 3000)."
  type        = number
  default     = 3000
}

variable "placeholder_image" {
  description = <<-EOT
    Image used only when the Container App is first created (the new ACR is
    still empty). The app pipeline replaces it; Terraform then ignores the image.
    traefik/whoami answers 200 on any path, so the /healthcheck probes pass.
  EOT
  type        = string
  default     = "docker.io/traefik/whoami:v1.11.0"
}

variable "tags" {
  description = "Extra tags merged into the default tags."
  type        = map(string)
  default     = {}
}

# Keys: local_user (you, az login) and pipeline (sp-healthapp-ado, behind the
# sc-healthapp-azure service connection). Keep the keys: they are the role
# assignments' addresses in state. No default, like subscription_id.
variable "kv_secrets_officers" {
  description = "Object IDs that may manage Key Vault secrets: everyone who runs Terraform."
  type        = map(string)

  validation {
    condition = alltrue([
      for id in values(var.kv_secrets_officers) :
      can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", id))
    ])
    error_message = "Every kv_secrets_officers value must be an Entra object ID (a GUID)."
  }
}
