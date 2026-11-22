# Module: resource-group

Creates one Azure Resource Group.

| Input | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Must start with `rg-` |
| `location` | string | yes | Azure region |
| `tags` | map(string) | no | Tags |

| Output | Description |
|---|---|
| `name` | RG name |
| `id` | RG resource ID |
| `location` | RG region |

```hcl
module "rg" {
  source   = "../modules/resource-group"
  name     = "rg-nexpay-dev"
  location = "centralindia"
}
```
