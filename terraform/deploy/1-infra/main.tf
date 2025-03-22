# terraform {
#   required_providers {
#     digitalocean = {
#       source  = "digitalocean/digitalocean"
#       version = "~> 2.0"
#     }
#   }
# }

module "infra" {
  source = "../../modules/infra"
  app_name = "invincible-app"
  primary_region = "ams3"
  secondary_region = "nyc1"
  db_size = "db-s-1vcpu-2gb"
  k8s_worker_size = "s-1vcpu-2gb"
}
