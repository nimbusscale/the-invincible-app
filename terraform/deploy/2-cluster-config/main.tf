module "primary_k8s_cluster" {
  source = "../../modules/cluster-config"
  app_name = "invincible-app"
  region = "ams3"
  db_cluster_name = "invincible-app-ams3"
  db_replica_name = "invincible-app-nyc1"
}

module "secondary_k8s_cluster" {
  source = "../../modules/cluster-config"
  app_name = "invincible-app"
  region = "nyc1"
  db_cluster_name = "invincible-app-ams3"
  db_replica_name = "invincible-app-nyc1"
}
