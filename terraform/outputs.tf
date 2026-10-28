output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "web_app_name" {
  description = "Name of the web app"
  value       = azurerm_linux_web_app.app.name
}

output "app_url" {
  description = "Public URL of the deployed app"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}
