# 1. Resource group = a folder that holds everything for this project.
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# 2. App Service plan = the rented computer that runs the web app.
resource "azurerm_service_plan" "plan" {
  name                = "asp-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

# 3. Web app = our Docker container, with a public URL.
resource "azurerm_linux_web_app" "app" {
  name                = "app-${var.project_name}-${var.web_app_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.plan.location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true
  tags                = var.tags

  site_config {
    always_on         = true
    health_check_path = "/health"

    application_stack {
      docker_image_name   = var.docker_image
      docker_registry_url = "https://index.docker.io"
    }
  }

  # Environment configuration (read by app.py)
  app_settings = {
    WEBSITES_PORT                       = "8000"
    APP_ENV                             = var.environment
    APP_VERSION                         = var.app_version
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
  }

  # Jenkins updates the image and version on every deployment.
  # Without this, "terraform apply" would undo Jenkins' changes.
  lifecycle {
    ignore_changes = [
      site_config[0].application_stack,
      app_settings["APP_VERSION"],
    ]
  }
}
