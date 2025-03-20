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

provider "helm" {
  alias = "ams3"
  kubernetes = {
    host  = data.digitalocean_kubernetes_cluster.ams3.endpoint
    token = data.digitalocean_kubernetes_cluster.ams3.kube_config[0].token
    cluster_ca_certificate = base64decode(
      data.digitalocean_kubernetes_cluster.ams3.kube_config[0].cluster_ca_certificate
    )
  }
}

resource "kubernetes_namespace_v1" "ams3-ingress-nginx" {
  provider = kubernetes.ams3
  metadata {
    name = "ingress-nginx"
    labels = {
      name = "ingress-nginx"
    }
  }
}

resource "helm_release" "ams3-ingress-nginx" {
  provider   = helm.ams3
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"
  values     = [file("./values.yaml")]
  set = [
    {
      name  = "controller.service.annotations.\"service\\.beta\\.kubernetes\\.io/do-loadbalancer-name\""
      value = "invincible-app-ams3"
    }
  ]
}

data "kubernetes_service_v1" "ams3_ingress_nginx_controller" {
  provider = kubernetes.ams3
  depends_on = [
    helm_release.ams3-ingress-nginx
  ]
  metadata {
    name = "ingress-nginx-controller"
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
  depends_on = [
    helm_release.ams3-ingress-nginx
  ]
  name = "invincible-app-glb"
  type = "GLOBAL"
  # need to param project_id
  project_id = "536e4ae6-b7e0-411f-b806-400f3b387bf2"
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