variable "subscription_id" {
  description = "Azure subscription ID (find it with: az account show)"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Short name used to build resource names"
  type        = string
  default     = "devopsflask"
}

variable "environment" {
  description = "Environment name (also shown on the web page)"
  type        = string
  default     = "production"
}

variable "location" {
  description = "Azure region where resources are created"
  type        = string
  default     = "centralindia"
}

variable "sku_name" {
  description = "App Service plan size. B1 is the cheapest that runs containers."
  type        = string
  default     = "B1"
}

variable "web_app_suffix" {
  description = "Makes the web app name globally unique, e.g. your initials + digits (lowercase letters and numbers only)"
  type        = string
}

variable "docker_image" {
  description = "Docker Hub image with tag, e.g. myuser/devops-flask-app:latest"
  type        = string
}

variable "app_version" {
  description = "Version text shown on the page"
  type        = string
  default     = "1.0.0"
}

variable "tags" {
  description = "Tags added to every resource"
  type        = map(string)
  default = {
    project = "devops-college-project"
    managed = "terraform"
  }
}
