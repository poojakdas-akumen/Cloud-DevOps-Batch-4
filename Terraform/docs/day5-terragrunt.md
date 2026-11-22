# Day 5 — Terragrunt Basics for DRY Configurations + Wrap-up

**Goal:** understand what Terragrunt adds on top of Terraform and deploy NexPay dev & prod with almost zero repeated code.

---

## 1. The problem Terragrunt solves

Imagine each environment and each component in its own folder (good for isolation):
```
dev/network/     backend.tf  provider.tf  main.tf  terraform.tfvars
dev/web-app/     backend.tf  provider.tf  main.tf  terraform.tfvars
prod/network/    backend.tf  provider.tf  main.tf  terraform.tfvars
prod/web-app/    backend.tf  provider.tf  main.tf  terraform.tfvars
```
The `backend.tf` and `provider.tf` are **copy-pasted 4 times** (40 times in a real company), and backend blocks can't use variables. Change the storage account → edit 40 files.

**Terragrunt** is a thin wrapper around Terraform that:
1. **Generates** backend and provider files from one root file
2. **Names each state file automatically** from the folder path
3. **Passes outputs between units** (`dependency` blocks)
4. **Runs many units at once** in the correct order

You still write normal Terraform modules — Terragrunt just calls them.

## 2. Vocabulary

| Word | Meaning |
|---|---|
| **unit** | one folder with a `terragrunt.hcl` = one Terraform state |
| **root.hcl** | shared settings, included by every unit |
| **include** | "inherit the settings of that file" |
| **inputs** | values for the module's variables (like `terraform.tfvars`) |
| **dependency** | read outputs from another unit |

## 3. The NexPay Terragrunt layout

```
nexpay-infra/
├── modules/                    # the SAME modules from Day 3 (unchanged!)
└── terragrunt/
    ├── root.hcl                # backend + provider + common inputs (written once)
    ├── dev/
    │   ├── env.hcl             # env = "dev"
    │   ├── resource-group/terragrunt.hcl
    │   ├── network/terragrunt.hcl
    │   └── web-app/terragrunt.hcl
    └── prod/
        ├── env.hcl             # env = "prod"
        ├── resource-group/terragrunt.hcl
        ├── network/terragrunt.hcl
        └── web-app/terragrunt.hcl
```

## 4. `root.hcl` — written once

```hcl
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals.env
  location = local.env_vars.locals.location
}

# Backend generated into every unit. The key is built from the folder path:
#   dev/network  ->  terragrunt/dev/network/terraform.tfstate
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    resource_group_name  = "rg-nexpay-tfstate"
    storage_account_name = "sttfnexpayXXXXXX"
    container_name       = "tfstate"
    key                  = "terragrunt/${path_relative_to_include()}/terraform.tfstate"
  }
}

# Provider block generated into every unit
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  features {}
}
EOF
}

# Inputs every unit gets
inputs = {
  location = local.location
  tags = {
    project     = "nexpay"
    environment = local.env
    managed_by  = "terragrunt"
  }
}
```

Useful functions:
- `find_in_parent_folders("root.hcl")` — walks up the folders until it finds the file
- `path_relative_to_include()` — the unit's path relative to root.hcl (e.g. `dev/network`)
- `read_terragrunt_config(...)` — load another `.hcl` file's locals

## 5. `env.hcl` — the only difference between environments

```hcl
# terragrunt/dev/env.hcl
locals {
  env           = "dev"
  location      = "centralindia"
  unique_suffix = "ab12cd"
}
```

## 6. A unit — `dev/resource-group/terragrunt.hcl`

```hcl
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true                        # allows include.root.locals.env
}

terraform {
  source = "../../../modules//resource-group"   # "//" = copy whole modules folder
}

inputs = {
  name = "rg-nexpay-tg-${include.root.locals.env}"
}
```
That's the whole file. No backend, no provider, no variables file.

## 7. Dependencies — `dev/network/terragrunt.hcl`

```hcl
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../modules//network"
}

dependency "rg" {
  config_path = "../resource-group"

  # Fake outputs so 'plan' works before the RG exists
  mock_outputs = {
    name     = "rg-mock"
    location = "centralindia"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  name_prefix         = "nexpay-tg-${include.root.locals.env}"
  resource_group_name = dependency.rg.outputs.name     # output of another unit
  address_space       = ["10.110.0.0/16"]
  app_subnet_prefix   = "10.110.1.0/24"
  data_subnet_prefix  = "10.110.2.0/24"
}
```
`web-app` depends on both `resource-group` and `network`. Terragrunt builds the order:
```
resource-group ──► network ──► web-app
       └──────────────────────────▲
```

## 8. Commands

Terragrunt passes commands through to Terraform:
```bash
cd nexpay-infra/terragrunt/dev/resource-group
terragrunt init
terragrunt plan
terragrunt apply
terragrunt output
terragrunt destroy
```

Run **all units** under a folder, in dependency order:
```bash
cd nexpay-infra/terragrunt/dev
terragrunt run --all plan
terragrunt run --all apply        # asks once for confirmation
terragrunt run --all destroy      # reverse order: web-app -> network -> resource-group
terragrunt dag graph              # show the dependency graph
```
> Older Terragrunt versions (before the 2025 CLI redesign) used `terragrunt run-all apply` and a root file named `terragrunt.hcl`. You'll see that in older blogs — the ideas are identical.

On disk you'll see a `.terragrunt-cache/` folder in each unit (a copy of the module + the generated `backend.tf` and `provider.tf`). It's in `.gitignore`; delete it any time.

## 9. Workspaces vs Terragrunt — when to use what

| | Workspaces | Terragrunt folders |
|---|---|---|
| Extra tool | no | yes |
| State per environment | ✅ | ✅ |
| State per component (network separate from app) | ❌ one big state | ✅ small states, faster plans, smaller blast radius |
| Different backend/subscription per env | ❌ | ✅ (put backend settings in `env.hcl`) |
| See what's deployed by browsing folders | ❌ | ✅ |
| Learning curve | low | medium |

## 🧪 Lab 5 — NexPay with Terragrunt

```bash
cd nexpay-infra/terragrunt
# 1. root.hcl: set storage_account_name (from the bootstrap output)
# 2. dev/env.hcl + prod/env.hcl: set a unique_suffix
source ../scripts/set-azure-env.sh

cd dev
terragrunt run --all plan         # notice mock outputs being used
terragrunt run --all apply
cd web-app && terragrunt output url
```
**Try this:**
1. Open the `tfstate` container → find `terragrunt/dev/network/terraform.tfstate`. Where did that name come from?
2. Look inside `dev/network/.terragrunt-cache/.../backend.tf` — Terragrunt wrote it.
3. Add a new unit `dev/storage-account/terragrunt.hcl` using the storage-account module (depends on resource-group). Only ~20 lines!
4. Change the tag `managed_by` in `root.hcl` → `terragrunt run --all plan` shows it in every unit.
5. `terragrunt run --all destroy`.

---

# 🎓 Wrap-up — the full production picture

```
nexpay-infra/
├── bootstrap/        Day 2    state storage (local state, prevent_destroy)
├── modules/          Day 3    resource-group, network, storage-account, web-app
├── terraform/        Day 1-4  root module: HCL, azurerm backend, workspaces dev/staging/prod
├── terragrunt/       Day 5    same modules, DRY folders per env/component
└── scripts/                   helpers
labs/day4-import-demo Day 4    import ClickOps resources
```

**Production checklist** — what this project already does, and what a real team adds next:

- [x] Remote state in Azure Blob: GRS, versioning, locking
- [x] Reusable modules with validation and security defaults
- [x] Separate state per environment
- [x] Tagging standard (project, environment, owner, managed_by)
- [x] Managed identity + RBAC instead of keys
- [x] Guard against the wrong workspace, `prevent_destroy` on critical resources
- [ ] CI/CD: `fmt -check` → `validate` → `plan -out` → manual approval → `apply tfplan` (GitHub Actions / Azure Pipelines with OIDC)
- [ ] Security scanning (Trivy, Checkov) in the pipeline
- [ ] Backend auth with `use_azuread_auth = true`, storage keys disabled
- [ ] Private endpoints for storage, Key Vault for secrets
- [ ] Prod in a separate subscription

## ✅ Day 5 recap
- Terragrunt = wrapper that generates backend/provider files and wires units together.
- `root.hcl` once, `env.hcl` per environment, a tiny `terragrunt.hcl` per unit.
- `dependency` + `mock_outputs` pass outputs between units.
- `terragrunt run --all <command>` runs a whole environment in order.

## ❓ Final quiz
1. What does `path_relative_to_include()` return for `prod/web-app`?
2. Why do we need `mock_outputs`?
3. Name two files Terragrunt generates for you.
4. Your company wants prod in a different subscription with a different state account. Workspaces or Terragrunt? Why?
