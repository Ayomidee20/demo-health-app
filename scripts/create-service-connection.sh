#!/usr/bin/env bash
# Creates the Azure DevOps service connection "sc-healthapp-azure" via the REST API
# (workload identity federation, manual app registration), then prints the
# issuer/subject that the app registration's federated credential must trust.
#
# Needs a PAT with scope "Service Connections: Read, query & manage".
# The PAT is read silently and never written to disk.
set -euo pipefail

ORG="ayomidegiwaa"
PROJECT="DevOps"
NAME="sc-healthapp-azure"
TENANT_ID="18d75181-a1df-4fc2-bb50-7e1b2990a11a"
CLIENT_ID="73100a08-c5f0-4d32-bf1e-e414bf6f5dfa" # app registration sp-healthapp-ado
SUBSCRIPTION_ID="651d3386-8e30-4607-abfc-b1817d173f84"
SUBSCRIPTION_NAME="Azure subscription 1"

read -rsp "Paste your Azure DevOps PAT (hidden): " PAT
echo
AUTH="Authorization: Basic $(printf ':%s' "$PAT" | base64)"
API="https://dev.azure.com/$ORG"

# The endpoint must reference the project by ID.
project_id=$(curl -sS --fail-with-body -H "$AUTH" \
  "$API/_apis/projects/$PROJECT?api-version=7.1" |
  python3 -c 'import sys, json; print(json.load(sys.stdin)["id"])')

body=$(cat <<EOF
{
  "name": "$NAME",
  "type": "AzureRM",
  "url": "https://management.azure.com/",
  "isShared": false,
  "isReady": true,
  "authorization": {
    "scheme": "WorkloadIdentityFederation",
    "parameters": {
      "tenantid": "$TENANT_ID",
      "serviceprincipalid": "$CLIENT_ID"
    }
  },
  "data": {
    "environment": "AzureCloud",
    "scopeLevel": "Subscription",
    "subscriptionId": "$SUBSCRIPTION_ID",
    "subscriptionName": "$SUBSCRIPTION_NAME",
    "creationMode": "Manual"
  },
  "serviceEndpointProjectReferences": [
    {
      "projectReference": { "id": "$project_id", "name": "$PROJECT" },
      "name": "$NAME",
      "description": "Terraform and app pipelines (workload identity federation)"
    }
  ]
}
EOF
)

curl -sS --fail-with-body -H "$AUTH" -H "Content-Type: application/json" \
  -d "$body" "$API/_apis/serviceendpoint/endpoints?api-version=7.1" |
  python3 -c '
import sys, json
d = json.load(sys.stdin)
p = d["authorization"]["parameters"]
print("Created service connection:", d["name"], d["id"])
print("Issuer: ", p.get("workloadIdentityFederationIssuer"))
print("Subject:", p.get("workloadIdentityFederationSubject"))
'
