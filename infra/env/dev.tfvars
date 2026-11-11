# Use with: terraform init -backend-config="key=dev.tfstate"
environment = "dev"

# Smallest size, one warm replica. Short-lived: destroyed after the demo.
container_cpu    = 0.25
container_memory = "0.5Gi"
min_replicas     = 1
max_replicas     = 1
