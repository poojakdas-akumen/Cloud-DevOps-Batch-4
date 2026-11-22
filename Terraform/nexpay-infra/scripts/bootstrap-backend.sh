#!/usr/bin/env bash
# Alternative to bootstrap/ : create the state backend with Azure CLI only.
set -euo pipefail

LOCATION="${LOCATION:-centralindia}"
RG="rg-nexpay-tfstate"
SA="sttfnexpay$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)"
CONTAINER="tfstate"

az group create --name "$RG" --location "$LOCATION" --output none

az storage account create \
  --name "$SA" \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --sku Standard_GRS \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output none

az storage account blob-service-properties update \
  --account-name "$SA" \
  --resource-group "$RG" \
  --enable-versioning true \
  --output none

az storage container create \
  --name "$CONTAINER" \
  --account-name "$SA" \
  --auth-mode login \
  --output none

cat <<OUT
Backend ready. Put this in terraform/backend.hcl:

resource_group_name  = "$RG"
storage_account_name = "$SA"
container_name       = "$CONTAINER"
key                  = "nexpay/app.tfstate"
OUT
