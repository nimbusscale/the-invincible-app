terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0-pre2"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

module "primary_k8s_cluster" {
  source = "./modules/cluster-config"
  region = "ams3"
  db_cluster_name = "invincible-app-ams3"
  db_replica_name = "invincible-app-nyc1"
}

module "secondary_k8s_cluster" {
  source = "./modules/cluster-config"
  region = "nyc1"
  db_cluster_name = "invincible-app-ams3"
  db_replica_name = "invincible-app-nyc1"
}
