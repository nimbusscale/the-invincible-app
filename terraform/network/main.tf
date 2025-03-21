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
  }
}

data "digitalocean_kubernetes_cluster" "ams3" {
  name = "invincible-app-ams3"
}

provider "kubernetes" {
  alias = "ams3"
  host  = data.digitalocean_kubernetes_cluster.ams3.endpoint
  token = data.digitalocean_kubernetes_cluster.ams3.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.ams3.kube_config[0].cluster_ca_certificate
  )
}

data "kubernetes_service_v1" "ams3_ingress_nginx_controller" {
  provider = kubernetes.ams3
  metadata {
    name = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}

resource "digitalocean_domain" "invincible_domain" {
  name = "invincible.do.jjk3.com"
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
    data.kubernetes_service_v1.ams3_ingress_nginx_controller.metadata[0].annotations["kubernetes.digitalocean.com/load-balancer-id"]
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