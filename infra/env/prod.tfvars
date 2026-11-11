# Use with: terraform init -reconfigure -backend-config="key=prod.tfstate"
environment = "prod"

# Always one warm replica (no cold start), room to scale under load.
# Short-lived: created for the demo, then destroyed via the pipeline.
container_cpu    = 0.5
container_memory = "1Gi"
min_replicas     = 1
max_replicas     = 3
