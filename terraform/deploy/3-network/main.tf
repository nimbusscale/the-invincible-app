module "network" {
  source = "../../modules/network"
  app_name = "invincible-app"
  parent_domain = "do.jjk3.com"
  primary_region = "ams3"
  secondary_region = "nyc1"
}