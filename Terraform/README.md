# Terraform on Azure — 5-Day Module

Hands-on course: from your first resource group to a production-style, multi-environment Azure platform (**NexPay**) managed with Terraform and Terragrunt.

## Schedule

| Day | Topics | Notes | Hands-on |
|---|---|---|---|
| 0 | Tools, Azure login, subscription env var | [00-setup.md](docs/00-setup.md) | smoke test |
| 1 | Terraform on Azure · HCL: providers, resources, variables, outputs, locals, data sources, count/for_each | [day1](docs/day1-terraform-and-hcl.md) | `labs/day1-hello-azure` |
| 2 | `init` · `plan` · `apply` · `destroy` · state · **remote state on Azure Blob** · locking · migration | [day2](docs/day2-workflow-and-remote-state.md) | `nexpay-infra/bootstrap`, `labs/day2-remote-state` |
| 3 | **Modules** — build, call, compose, version | [day3](docs/day3-modules.md) | `nexpay-infra/modules` |
| 4 | **Workspaces** for dev/staging/prod · **Import** existing Azure resources | [day4](docs/day4-workspaces-and-import.md) | `nexpay-infra/terraform`, `labs/day4-import-demo` |
| 5 | **Terragrunt** basics — DRY backend/provider, dependencies, run --all · wrap-up | [day5](docs/day5-terragrunt.md) | `nexpay-infra/terragrunt` |
| — | Commands, syntax, common errors | [cheatsheet.md](docs/cheatsheet.md) | |

## Folder structure

```
terraform-azure-5day/
├── docs/                         # the 5-day notes (read in order)
├── labs/
│   ├── day1-hello-azure/         # RG + storage + containers (all HCL basics)
│   ├── day2-remote-state/        # local state -> Azure Blob migration
│   └── day4-import-demo/         # import Portal-created resources
└── nexpay-infra/                 # production-style project
    ├── bootstrap/                # creates the remote-state storage (run once)
    ├── modules/                  # resource-group, network, storage-account, web-app
    ├── terraform/                # root module + workspaces (dev/staging/prod)
    ├── terragrunt/               # same modules, Terragrunt layout (dev/prod)
    └── scripts/                  # helper scripts
```

## What NexPay deploys (per environment)

```
rg-nexpay-<env>
├── vnet-nexpay-<env>  (10.x0.0.0/16)
│   ├── snet-app   → delegated to App Service (VNet integration)
│   └── snet-data  → NSG: allow from snet-app only, deny Internet
├── stnexpay<env><suffix>        Storage: TLS1.2, private, versioning, containers invoices/receipts
├── asp-app-nexpay-<env>-<sfx>   App Service Plan (B1 dev/staging, P0v3 prod)
└── app-nexpay-<env>-<suffix>    Linux Web App (Node 20), HTTPS only, managed identity
                                 └─ RBAC: Storage Blob Data Contributor on the storage account
```

## Suggested daily flow (≈ 3 hours)

| Time | Activity |
|---|---|
| 45 min | Concepts from the day's notes (use the diagrams + examples) |
| 30 min | Instructor live demo |
| 75 min | Students do the lab + "Try this" exercises |
| 15 min | Recap + quiz |
| 5 min | **`terraform destroy`** 💰 |

## Requirements
Terraform ≥ 1.9 · azurerm provider 4.x · Azure CLI · Terragrunt (Day 5) · an Azure subscription with Contributor (Owner for the RBAC role assignment).
