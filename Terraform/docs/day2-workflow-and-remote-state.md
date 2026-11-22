# Day 2 — The Workflow (init · plan · apply · destroy) & Remote State

**Goal:** master the four core commands, understand state, and move state to Azure Blob Storage like a real team.

---

## 1. The core workflow

```
 write code ──► terraform init ──► terraform plan ──► terraform apply ──► (later) terraform destroy
                 download           preview the        make the            delete everything
                 providers,         changes            changes             in this config
                 set up backend
```

Plus two helpers you should run every time:
```bash
terraform fmt        # auto-format code (fix indentation, align "=")
terraform validate   # check syntax and references, without touching Azure
```

## 2. `terraform init`

Run it: first time in a folder, after adding a provider/module, after changing the backend.

What it does:
1. Downloads providers into `.terraform/providers/`
2. Downloads modules into `.terraform/modules/`
3. Configures the **backend** (where state lives)
4. Creates/updates **`.terraform.lock.hcl`** — exact provider versions + checksums

```bash
terraform init
terraform init -upgrade                          # get newer provider versions allowed by constraints
terraform init -backend-config=backend.hcl       # partial backend config (see section 7)
terraform init -migrate-state                    # move state to a new backend
terraform init -reconfigure                      # switch backend, ignore old one
```

> ✅ **Commit** `.terraform.lock.hcl` to Git (everyone gets the same provider version).
> ❌ **Never commit** `.terraform/` or `*.tfstate`.

## 3. `terraform plan`

Plan = **dry run**. It compares 3 things: your code, the state file, and real Azure.

```bash
terraform plan
terraform plan -out=tfplan                  # save the plan to a file
terraform plan -var-file=env/prod.tfvars
terraform plan -destroy                     # preview a destroy
terraform plan -target=module.network       # only one thing (emergencies only!)
```

**Reading a plan — the symbols:**

| Symbol | Meaning | Example cause |
|---|---|---|
| `+` | create | new resource in code |
| `~` | update in-place | changed a tag |
| `-/+` | destroy then create (**replace**) | changed `location` or `name` |
| `-` | destroy | removed from code |
| `<=` | read (data source) | |

Last line summary: `Plan: 2 to add, 1 to change, 0 to destroy.`

> ⚠️ Always read the plan. A `-/+` on a database or storage account means **data loss**.

## 4. `terraform apply`

```bash
terraform apply                  # makes a new plan, asks "yes"
terraform apply tfplan           # applies EXACTLY the saved plan, no question (used in CI/CD)
terraform apply -auto-approve    # no question (labs only!)
```

Production pattern (what pipelines do):
```bash
terraform plan -out=tfplan       # stage 1: plan, a human reviews it
terraform apply tfplan           # stage 2: apply the reviewed plan
```

## 5. `terraform destroy`

```bash
terraform destroy                            # delete everything in this state
terraform destroy -target=azurerm_storage_account.lab   # one resource (careful)
```
To remove one resource permanently, the clean way is: **delete it from the code, then `apply`.**

## 6. State — Terraform's memory

After `apply`, Terraform writes `terraform.tfstate`: a JSON map of **code address → real Azure ID**.

```json
"type": "azurerm_resource_group",
"name": "lab",
"instances": [{ "attributes": { "id": "/subscriptions/.../resourceGroups/rg-tf-day1-manoop", ... } }]
```

Without state, Terraform doesn't know it already created something — it would try to create it again.

**State commands:**
```bash
terraform state list                                          # everything Terraform manages
terraform state show azurerm_resource_group.lab               # details of one
terraform state mv azurerm_resource_group.lab azurerm_resource_group.main   # renamed in code
terraform state rm azurerm_storage_account.lab                # "forget" it (Azure keeps it)
terraform refresh   # old; use: terraform apply -refresh-only
```

Modern refactoring — prefer a `moved` block over `state mv` (it is reviewed in Git):
```hcl
moved {
  from = azurerm_resource_group.lab
  to   = azurerm_resource_group.main
}
```

### Why local state is a problem in a team

| Problem | What happens |
|---|---|
| State is on *your* laptop | Colleague runs apply → creates duplicates |
| Two people apply at once | State gets corrupted |
| Laptop dies | Terraform "forgets" all of prod |
| **Secrets in plain text** | Storage keys, passwords are inside the state JSON |

**Solution: remote state in Azure Blob Storage** — shared, locked, versioned, encrypted at rest.

## 7. Remote state with the `azurerm` backend

### Step 1 — create the storage (only once)

Chicken-and-egg: the backend must exist before Terraform can use it. We create it with a small separate config that uses local state: `nexpay-infra/bootstrap/`.

```bash
cd nexpay-infra/bootstrap
terraform init
terraform apply
terraform output backend_hcl
```
It creates: `rg-nexpay-tfstate` → storage account `sttfnexpayXXXXXX` (GRS, versioning, TLS 1.2, `prevent_destroy`) → container `tfstate`.

(Prefer the CLI? `nexpay-infra/scripts/bootstrap-backend.sh` does the same with `az` commands.)

### Step 2 — point your config at it

**Option A — full config in code** (fine for labs):
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-nexpay-tfstate"
    storage_account_name = "sttfnexpayab12cd"
    container_name       = "tfstate"
    key                  = "labs/day2/manoop.tfstate"   # the blob name = path of the state file
  }
}
```

**Option B — partial config** (what the NexPay project uses):
```hcl
# backend.tf
terraform {
  backend "azurerm" {}
}
```
```hcl
# backend.hcl  (not committed; each team/subscription has its own)
resource_group_name  = "rg-nexpay-tfstate"
storage_account_name = "sttfnexpayab12cd"
container_name       = "tfstate"
key                  = "nexpay/app.tfstate"
```
```bash
terraform init -backend-config=backend.hcl
```

> Backend blocks **cannot use variables** (`var.x` is not allowed there). That's why partial config exists.

### Step 3 — authentication for the backend

| Method | Setting | When |
|---|---|---|
| Azure CLI login (default) | nothing | labs — Terraform looks up the storage key for you |
| Entra ID / RBAC | `use_azuread_auth = true` | production — needs role **Storage Blob Data Contributor** on the account; storage keys can then be disabled |
| Service principal / OIDC | `ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_USE_OIDC=true` | CI/CD pipelines |

### State locking

When you run `plan`/`apply`, Terraform takes a **blob lease** (a lock) on the state file. A second person gets:
```
Error: Error acquiring the state lock
Lock Info:  ID: 4c1b...  Who: ravi@laptop  Operation: OperationTypeApply
```
Wait for them to finish. If a run crashed and left a stale lock:
```bash
terraform force-unlock <LOCK_ID>      # only if you are SURE nobody is running
```

### Moving existing local state to Azure

```bash
# 1. add the backend block
# 2. then:
terraform init -migrate-state
# Answer "yes" to copy the state. Check the blob in the Portal, then delete the local terraform.tfstate.
```

### Reading another project's state (sharing outputs)

```hcl
data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-nexpay-tfstate"
    storage_account_name = "sttfnexpayab12cd"
    container_name       = "tfstate"
    key                  = "nexpay/network.tfstate"
  }
}

# use it:
subnet_id = data.terraform_remote_state.network.outputs.app_subnet_id
```

---

## 🧪 Lab 2 — Workflow + remote state (`labs/day2-remote-state`)

```bash
# Part A: bootstrap the backend (instructor does this once for the whole batch,
#         or each student does it in their own subscription)
cd nexpay-infra/bootstrap && terraform init && terraform apply

# Part B: use local state first
cd ../../labs/day2-remote-state
mv backend.tf backend.tf.off        # disable the backend for now
terraform init && terraform apply
ls                                  # see terraform.tfstate locally
terraform state list

# Part C: migrate to Azure
mv backend.tf.off backend.tf        # edit: storage_account_name + your name in key
terraform init -migrate-state
rm terraform.tfstate terraform.tfstate.backup
terraform plan                      # "No changes" -> state is now read from Azure 🎉
```
Open the Portal → storage account → container `tfstate` → see your blob. Click **Versions**.

**Try this:**
1. Two students share the same `key`. Both run `terraform apply` at the same time. Who gets the lock error?
2. Rename `azurerm_virtual_network.lab` to `.main` in code → plan shows destroy/create. Add a `moved` block → plan shows "has moved", no changes.
3. `terraform plan -out=tfplan` then `terraform apply tfplan`.
4. `terraform destroy`.

## ✅ Day 2 recap

- `init` → `plan` → `apply` → `destroy`; plus `fmt` and `validate`.
- Read the plan symbols: `+`, `~`, `-/+`, `-`.
- State = mapping of code to real IDs. Contains secrets. Never in Git.
- Remote state on Azure Blob: shared, locked (blob lease), versioned.
- Backend blocks can't use variables → partial config with `-backend-config`.

## ❓ Quick quiz
1. What is inside `.terraform.lock.hcl` and should you commit it?
2. What does `-/+` mean and why is it dangerous?
3. How does the azurerm backend prevent two applies at once?
4. Why do we bootstrap the state storage with a separate configuration?
