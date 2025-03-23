module "network" {
  source = "../../modules/network"
  app_name = "invincible-app"
  parent_domain = "do.jjk3.com"
  primary_region = "ams3"
  secondary_region = "nyc1"
}

module "primary_app" {
  source = "../../modules/app"
  app_name = "invincible-app"
  region = "ams3"
  primary = "true"
  domain = "invincible-app.do.jjk3.com"
  image_repository = "registry.digitalocean.com/jjk3-sandbox/invincible-app"
}

module "secondary_app" {
  source = "../../modules/app"
  app_name = "invincible-app"
  region = "nyc1"
  primary = "false"
  domain = "invincible-app.do.jjk3.com"
  image_repository = "registry.digitalocean.com/jjk3-sandbox/invincible-app"
}