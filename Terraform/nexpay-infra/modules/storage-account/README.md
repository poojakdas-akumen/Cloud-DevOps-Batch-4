# Module: storage-account

Creates a secure Storage Account (TLS 1.2, HTTPS only, no public blobs, versioning, soft delete)
and any number of private containers.

```hcl
module "storage" {
  source              = "../modules/storage-account"
  name                = "stnexpaydevab12cd"
  resource_group_name = module.rg.name
  location            = module.rg.location
  replication_type    = "LRS"
  containers          = ["invoices", "receipts"]
}
```
