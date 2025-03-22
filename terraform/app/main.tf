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

resource "digitalocean_domain" "invincible_domain" {
  name = "invincible.do.jjk3.com"
}

data "digitalocean_loadbalancer" "ams3" {
  depends_on = [
    module.primary_k8s_cluster,
    module.secondary_k8s_cluster
  ]
  name = "invincible-app-ams3"
}

resource "digitalocean_record" "ams" {
  domain = digitalocean_domain.invincible_domain.id
  type   = "A"
  name   = "ams3"
  value  = data.digitalocean_loadbalancer.ams3.ip
  ttl    = 300
}

data "digitalocean_loadbalancer" "nyc1" {
  depends_on = [
    module.primary_k8s_cluster,
    module.secondary_k8s_cluster
  ]
  name = "invincible-app-nyc1"
}


resource "digitalocean_record" "nyc" {
  domain = digitalocean_domain.invincible_domain.id
  type   = "A"
  name   = "nyc1"
  value  = data.digitalocean_loadbalancer.nyc1.ip
  ttl    = 300
}

data "digitalocean_domain" "parent_domain" {
  name = "do.jjk3.com"
}

resource "digitalocean_record" "ns1" {
  domain = data.digitalocean_domain.parent_domain.id
  type   = "NS"
  name   = "invincible"
  value  = "ns1.digitalocean.com."
  ttl    = 86400
}

resource "digitalocean_record" "ns2" {
  domain = data.digitalocean_domain.parent_domain.id
  type   = "NS"
  name   = "invincible"
  value  = "ns2.digitalocean.com."
  ttl    = 86400
}

resource "digitalocean_record" "ns3" {
  domain = data.digitalocean_domain.parent_domain.id
  type   = "NS"
  name   = "invincible"
  value  = "ns3.digitalocean.com."
  ttl    = 86400
}

resource "digitalocean_loadbalancer" "glb" {
  name = "invincible-app-glb"
  type = "GLOBAL"
  # need to param project_id
  project_id = "be7ced25-d223-44c6-ace0-6f0ccd7828da"
  target_load_balancer_ids = [
    data.digitalocean_loadbalancer.ams3.id,
    data.digitalocean_loadbalancer.nyc1.id
  ]
  domains {
      name       = "invincible.do.jjk3.com"
      is_managed = true
  }
  glb_settings {
    target_protocol = "http"
    target_port = 80
  }
}

resource "digitalocean_project_resources" "invincible_app_ams3" {
  project = "be7ced25-d223-44c6-ace0-6f0ccd7828da"
  resources = [
    data.digitalocean_loadbalancer.ams3.urn,
    data.digitalocean_loadbalancer.nyc1.urn,
  ]
}