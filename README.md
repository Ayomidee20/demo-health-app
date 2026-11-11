# Azure HealthApp — CI/CD with Terraform & Azure DevOps

A Python Flask application deployed on **Azure Container Apps**, provisioned with **Terraform**, and automated through **Azure DevOps Pipelines**.

## Architecture

- **App**: Flask with `/healthcheck`, `/login`, and `/` routes
- **Container runtime**: Azure Container Apps (consumption plan)
- **Registry**: Azure Container Registry (ACR)
- **IaC**: Terraform with remote state in Azure Storage
- **CI/CD**: Azure DevOps Pipelines
  - **Infra pipeline**: `terraform plan` → human approval → `terraform apply`
  - **App pipeline**: lint → test → scan → build → push → deploy → health check

## Repo structure

```
app/                  # Flask application
tests/                # Pytest test suite
infra/
  bootstrap/          # One-time state storage setup (run locally)
  env/                # Per-environment tfvars (dev.tfvars, prod.tfvars)
  *.tf                # Main Terraform configuration
pipelines/
  infra-pipeline.yml  # Terraform plan/apply with approval gate
  app-pipeline.yml    # Build, push, deploy, health check
Dockerfile            # Multi-stage: test in build, gunicorn in prod
```

## Local development

```bash
# Install deps
pip install -r requirements.txt

# Run tests
python -m pytest tests/ -v

# Run locally
python app/app.py
# Visit http://localhost:3000/healthcheck
```

## Docker

```bash
docker build --platform linux/amd64 --build-arg COMMIT_SHA=$(git rev-parse HEAD) -t healthapp .
docker run -p 3000:3000 healthapp
```

## Author

Ayomide Giwa — DevOps/Infrastructure Engineer
