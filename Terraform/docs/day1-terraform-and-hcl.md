# Day 1 — Terraform on Azure & HCL Syntax

**Goal:** understand what Terraform is, how it talks to Azure, and write your first configuration using providers, resources, variables and outputs.

---

## 1. What is Infrastructure as Code (IaC)?

Instead of clicking in the Azure Portal, you **write a file that describes what you want**. A tool reads the file and creates it for you.

| Portal (ClickOps) | Terraform (IaC) |
|---|---|
| Click, click, click | Write code once |
| Hard to repeat for dev/test/prod | Same code, different values |
| No history of who changed what | Git history + code review |
| "Who created this VM?" | Every resource is documented in code |

**Real example:** NexPay needs the same network, storage and web app in dev, staging and prod. By hand, that's 3× the clicking and 3× the chance of a mistake. With Terraform, it's one codebase.

## 2. How Terraform works with Azure

```
  you write           Terraform              azurerm provider            Azure
  *.tf files   --->   core engine    --->    (plugin that knows   --->   Resource Manager
                      (plan/apply)           Azure APIs)                 (ARM) API
                           |
                           v
                   terraform.tfstate
              (Terraform's memory of what it created)
```

- **Terraform core** — reads your code, compares it with the state, decides what to do.
- **Provider** — a plugin that translates Terraform into API calls. For Azure: `hashicorp/azurerm`.
- **State** — a JSON file that maps your code to real Azure resource IDs. (Day 2 goes deep on this.)

**Declarative:** you say *what* you want ("a resource group called rg-demo"), not *how* ("call this API, then that API"). If it already exists and matches, Terraform does nothing.

## 3. HCL — the language

HCL (HashiCorp Configuration Language) is made of **blocks**:

```hcl
<BLOCK TYPE> "<LABEL 1>" "<LABEL 2>" {
  argument = value   # a setting
  nested_block {     # a block inside a block
    argument = value
  }
}
```

Value types you will use:

```hcl
name     = "rg-demo"                    # string
count    = 2                            # number
enabled  = true                         # bool
cidrs    = ["10.0.0.0/16", "10.1.0.0/16"]  # list
tags     = { env = "dev", team = "ops" }   # map
```

File names don't matter to Terraform — it loads **every `.tf` file in the folder**. We split files by convention:

| File | Contains |
|---|---|
| `providers.tf` / `versions.tf` | `terraform {}` and `provider {}` blocks |
| `main.tf` | resources |
| `variables.tf` | input variables |
| `outputs.tf` | outputs |
| `terraform.tfvars` | values for variables |

## 4. The `terraform` block & providers

```hcl
terraform {
  required_version = ">= 1.9"          # which Terraform CLI versions are OK

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"     # registry.terraform.io/hashicorp/azurerm
      version = "~> 4.0"                # any 4.x, never 5.0
    }
  }
}

provider "azurerm" {
  features {}                           # required, even if empty
  # subscription_id comes from ARM_SUBSCRIPTION_ID env var
}
```

**Version constraints:**

| Constraint | Means |
|---|---|
| `= 4.10.0` | exactly this |
| `>= 4.0` | 4.0 or newer (risky — allows 5.0) |
| `~> 4.0` | 4.x only ✅ recommended |
| `~> 4.10.0` | 4.10.x only |

**How does the provider log in?** In this course: the Azure CLI (`az login`). In CI/CD pipelines you use a Service Principal or OIDC with environment variables (`ARM_CLIENT_ID`, `ARM_TENANT_ID`, …).

## 5. Resources

A resource = one thing in Azure.

```hcl
resource "azurerm_resource_group" "lab" {
#          ^ resource TYPE          ^ local NAME (only used inside Terraform)
  name     = "rg-tf-day1-manoop"    # the name in Azure
  location = "centralindia"
}
```

**References** — use one resource's attribute in another: `<TYPE>.<NAME>.<ATTRIBUTE>`

```hcl
resource "azurerm_storage_account" "lab" {
  name                     = "stmanoop12345"
  resource_group_name      = azurerm_resource_group.lab.name       # <-- reference
  location                 = azurerm_resource_group.lab.location   # <-- reference
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

References also tell Terraform the **order**: the RG must exist before the storage account. You never write "step 1, step 2" — Terraform builds a dependency graph.

> Where do I find all the arguments? The azurerm docs on registry.terraform.io → search the resource name → "Argument Reference" (inputs) and "Attributes Reference" (outputs you can reference).

## 6. Variables (inputs)

Variables make code reusable. Hard-coded names = copy-paste code. Variables = one code, many uses.

```hcl
variable "student_name" {
  description = "Your short name, lowercase"
  type        = string
  # no default -> Terraform will ASK for it (required)

  validation {
    condition     = can(regex("^[a-z]{3,10}$", var.student_name))
    error_message = "Use 3-10 lowercase letters."
  }
}

variable "location" {
  type    = string
  default = "centralindia"   # optional: has a default
}

variable "containers" {
  type    = list(string)
  default = ["images", "logs"]
}

variable "db_password" {
  type      = string
  sensitive = true           # hidden in plan/apply output
}
```

Use it with `var.<name>`:
```hcl
name = "rg-tf-day1-${var.student_name}"   # string interpolation
```

**Ways to give a value (lowest priority first — the later one wins):**

1. `default` in the variable block
2. Environment variable: `export TF_VAR_location=southindia`
3. `terraform.tfvars` (loaded automatically)
4. `*.auto.tfvars` files (loaded automatically, alphabetical order)
5. `-var-file=prod.tfvars` or `-var="location=southindia"` on the command line (highest)

If a required variable has no value anywhere, Terraform prompts you for it.

Keep it simple for students: **defaults in `variables.tf`, real values in `terraform.tfvars`.**

```hcl
# terraform.tfvars
student_name = "manoop"
containers   = ["images", "logs", "backups"]
```

## 7. Locals

A local is a named value computed **inside** the code — like a variable that users can't change.

```hcl
locals {
  rg_name = "rg-tf-day1-${var.student_name}"
  tags = merge(var.tags, {
    owner = var.student_name
  })
}

resource "azurerm_resource_group" "lab" {
  name = local.rg_name
  tags = local.tags
}
```
Rule of thumb: **variable** = user decides. **local** = code decides (naming rules, merged tags).

## 8. Outputs

Outputs print useful values after `apply`, and pass values out of modules (Day 3).

```hcl
output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.lab.name
}

output "storage_primary_key" {
  value     = azurerm_storage_account.lab.primary_access_key
  sensitive = true
}
```
```bash
terraform output                          # all outputs
terraform output storage_account_name     # one output
terraform output -raw storage_primary_key # show a sensitive value (careful!)
terraform output -json                    # for scripts
```

## 9. Data sources — read what already exists

```hcl
data "azurerm_client_config" "current" {}      # who am I?

data "azurerm_resource_group" "shared" {        # an RG someone else created
  name = "rg-shared-services"
}

output "tenant" {
  value = data.azurerm_client_config.current.tenant_id
}
```
`resource` = Terraform **creates and owns** it. `data` = Terraform **only reads** it.

## 10. Meta-arguments (available on every resource)

**`count`** — N copies, or 0/1 to make something optional
```hcl
resource "azurerm_resource_group" "team" {
  count    = 3
  name     = "rg-team-${count.index}"      # rg-team-0, rg-team-1, rg-team-2
  location = "centralindia"
}
```

**`for_each`** — one copy per item in a set/map (preferred: stable names)
```hcl
resource "azurerm_storage_container" "lab" {
  for_each              = toset(["images", "logs"])
  name                  = each.value
  storage_account_id    = azurerm_storage_account.lab.id
  container_access_type = "private"
}
```

**`depends_on`** — force an order Terraform can't see from references (rarely needed).

**`lifecycle`** — change default behavior
```hcl
lifecycle {
  prevent_destroy       = true          # refuse to delete
  create_before_destroy = true          # zero-downtime replacement
  ignore_changes        = [tags]        # someone edits tags in the portal? ignore it
}
```

---

## 🧪 Lab 1 — Hello Azure (`labs/day1-hello-azure`)

Creates a resource group, a storage account and containers — using every concept above.

```bash
cd labs/day1-hello-azure
# 1. edit terraform.tfvars: set student_name to YOUR name
terraform init
terraform plan
terraform apply          # type "yes"
terraform output
```
Check in the Portal: the RG, the storage account and 3 containers exist.

**Try this:**
1. Add `"reports"` to `containers` in `terraform.tfvars` → `terraform apply`. Only 1 new container is created. Why?
2. Change `student_name` to `AB` → `terraform plan`. Read the validation error.
3. Add a tag `batch = "07"` to `variables.tf` default tags → plan. It's an **update in-place** (`~`), not a re-create.
4. Change `location` to `southindia` → plan. Why does it say **must be replaced** (`-/+`)?
5. `terraform destroy`.

## ✅ Day 1 recap

- Terraform = declarative IaC; `azurerm` provider talks to Azure ARM.
- Blocks: `terraform`, `provider`, `resource`, `data`, `variable`, `locals`, `output`.
- Reference syntax: `type.name.attribute`, `var.x`, `local.x`, `data.type.name.attr`.
- `count` / `for_each` for multiples, `lifecycle` for safety.

## ❓ Quick quiz

1. What is the difference between `resource` and `data`?
2. What does `~> 4.0` allow?
3. Which wins: `terraform.tfvars` or `-var` on the command line?
4. Why is `for_each` usually better than `count` for a list of names?
