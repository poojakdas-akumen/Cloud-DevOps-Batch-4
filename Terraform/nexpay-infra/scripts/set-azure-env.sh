#!/usr/bin/env bash
# Usage:  source scripts/set-azure-env.sh
# Exports the subscription ID so the azurerm provider (v4+) can find it.
export ARM_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
echo "ARM_SUBSCRIPTION_ID set to $ARM_SUBSCRIPTION_ID"
