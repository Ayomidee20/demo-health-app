variable "subscription_id" {
  description = "Azure subscription to deploy into."
  type        = string
  default     = "651d3386-8e30-4607-abfc-b1817d173f84"
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
