terraform {
  required_version = ">= 1.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
}

module "backend" {
  source = "./modules/backend"

  mapbox_secret_arn = var.mapbox_secret_arn
  valhalla_endpoint = var.valhalla_endpoint
}
