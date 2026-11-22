output "environment" {
  value = local.env
}

output "resource_group_name" {
  value = module.rg.name
}

output "vnet_id" {
  value = module.network.vnet_id
}

output "storage_account_name" {
  value = module.storage.name
}

output "web_app_url" {
  value = module.web_app.url
}
