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
Dockerfile            # Runtime image: gunicorn, non-root (tests run in the pipeline)
```

## Local development

```bash
# Install deps
pip install -r requirements-dev.txt

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

## Azure IDs (not committed)

The subscription ID and Entra object IDs aren't in the repo. The Terraform variables that need them have no defaults, so each run has to supply them:

| Value | Terraform variable | Locally | Infra pipeline |
|---|---|---|---|
| Subscription ID | `subscription_id` (`infra/`, `infra/bootstrap/`) | `terraform.tfvars` | read from the service connection |
| Your Entra user's object ID | `kv_secrets_officers.local_user` | `infra/terraform.tfvars` | pipeline variable `localUserObjectId` |
| `sp-healthapp-ado` object ID | `kv_secrets_officers.pipeline`, `pipeline_principal_id` (bootstrap) | `terraform.tfvars` | pipeline variable `pipelineObjectId` |

**Locally**, copy each example to `terraform.tfvars` (git-ignored, loaded automatically) and fill it in:

```bash
cp infra/terraform.tfvars.example infra/terraform.tfvars
cp infra/bootstrap/terraform.tfvars.example infra/bootstrap/terraform.tfvars
```

The examples list the `az` command that prints each value. `TF_VAR_<name>` environment variables work too.

**In Azure DevOps**, add `localUserObjectId` and `pipelineObjectId` as variables on the infra pipeline (Edit → Variables). The Plan step stops with an error if either is missing. Apply runs the saved plan, so it needs nothing extra.

[`scripts/create-service-connection.sh`](scripts/create-service-connection.sh) looks up the tenant, subscription and app registration from your `az login` session.

## Author

Ayomide Giwa — DevOps/Infrastructure Engineer
