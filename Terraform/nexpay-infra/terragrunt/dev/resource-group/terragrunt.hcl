include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true # lets us read include.root.locals.*
}

terraform {
  # "//" tells Terragrunt to copy the whole modules/ folder, then use resource-group/
  source = "../../../modules//resource-group"
}

inputs = {
  name = "rg-nexpay-tg-${include.root.locals.env}"
}
