#!/usr/bin/env bash
# Simulates "ClickOps": someone created these in the Portal, not with Terraform.
set -euo pipefail
NAME="${1:?usage: ./create-legacy.sh <your-name>}"

az group create --name "rg-legacy-${NAME}" --location centralindia \
  --tags created_by=portal --output none

az network vnet create --name "vnet-legacy-${NAME}" \
  --resource-group "rg-legacy-${NAME}" \
  --address-prefixes 10.60.0.0/16 --output none

echo "Resource group ID:"
az group show --name "rg-legacy-${NAME}" --query id --output tsv
echo "VNet ID:"
az network vnet show --name "vnet-legacy-${NAME}" --resource-group "rg-legacy-${NAME}" --query id --output tsv
