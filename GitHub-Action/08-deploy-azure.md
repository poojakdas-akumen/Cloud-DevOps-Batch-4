# Chapter 08 · Deploying to Azure from GitHub Actions

[🏠 Index](README.md)

---

This is a real-world CD pipeline: **push to `main` → build → authenticate to Azure → deploy.** No manual FTP, no portal clicks.

## The pipeline at a glance

```
Push to main → Build & Test → Build image → azure/login → Deploy to Azure
```

## Step 1 — Create an Azure service principal

A **service principal** is an identity GitHub uses to authenticate to Azure. Create one with the Azure CLI:

```bash
az ad sp create-for-rbac \
  --name "github-actions-nexpay" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP> \
  --sdk-auth
```

This prints a JSON credentials block. Copy the **entire** JSON.

## Step 2 — Store it as a secret

Repo → Settings → Secrets and variables → Actions → **New repository secret**
- Name: `AZURE_CREDENTIALS`
- Value: paste the JSON from step 1

## Step 3 — The deployment workflow

```yaml
name: Deploy to Azure Web App

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Check out code
        uses: actions/checkout@v4

      - name: Log in to Azure
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy to Web App
        uses: azure/webapps-deploy@v3
        with:
          app-name: nexpay-api
          package: .
```

## What a successful run looks like

```
✓ Set up job
✓ Run actions/checkout@v4
✓ Run azure/login@v2
    Login successful.
✓ Run azure/webapps-deploy@v3
    Deploying to nexpay-api...
    App available at nexpay-api.azurewebsites.net
✓ Deployment complete  (48s)
```

## Deploying a container image (Docker → Azure)

For containerized apps, build the image, push it to a registry (Azure Container Registry or Docker Hub), then deploy:

```yaml
name: Build and Deploy Container

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Log in to Azure
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Log in to Azure Container Registry
        run: az acr login --name myregistry

      - name: Build and push image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: myregistry.azurecr.io/nexpay-api:${{ github.sha }}

      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v3
        with:
          app-name: nexpay-api
          images: myregistry.azurecr.io/nexpay-api:${{ github.sha }}
```

> **Modern best practice:** Instead of a long-lived `AZURE_CREDENTIALS` secret, use **OIDC** (OpenID Connect) with `azure/login`. It issues short-lived tokens per run — no stored secret to leak. This requires configuring a federated credential on the Azure app registration.

## Common Azure deployment targets

| Target | Deploy action |
|--------|---------------|
| Azure Web App / App Service | `azure/webapps-deploy@v3` |
| Azure Functions | `azure/functions-action@v1` |
| Azure Kubernetes Service (AKS) | `azure/k8s-deploy@v5` |
| Azure Static Web Apps | `Azure/static-web-apps-deploy@v1` |
| Azure Container Instances | `azure/aci-deploy@v1` |

---

|  | |
|---|---|
| [← Matrix Builds](07-matrix-builds.md) | [Next → Self-Hosted Runners](09-self-hosted-runners.md) |
