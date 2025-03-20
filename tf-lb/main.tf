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

resource "kubernetes_namespace_v1" "ams3_ingress_nginx" {
  provider = kubernetes.ams3
  metadata {
    name = "ingress-nginx"
    labels = {
      name = "ingress-nginx"
    }
  }
}

data "http" "ingress_nginx_values" {
  url = "https://raw.githubusercontent.com/digitalocean/marketplace-kubernetes/master/stacks/ingress-nginx/values.yml"
}

resource "helm_release" "ams3_ingress_nginx" {
  provider   = helm.ams3
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace_v1.ams3_ingress_nginx.metadata[0].name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"
  values = [
    data.http.ingress_nginx_values.response_body
  ]
  set = [
    {
      name  = "controller.service.annotations.\"service\\.beta\\.kubernetes\\.io/do-loadbalancer-name\""
      value = "invincible-app-ams3"
    },
    {
      name  = "controller.service.annotations.\"service\\.beta\\.kubernetes\\.io/do-loadbalancer-enable-proxy-protocol\""
      value = "true"
    },
    {
      name  = "controller.service.annotations.\"service\\.beta\\.kubernetes\\.io/do-loadbalancer-tls-passthrough\""
      value = "true"
    },
    {
      name  = "config.use-proxy-protocol"
      value = "true"
    }
  ]
}

resource "kubernetes_namespace_v1" "ams3_cert_manager" {
  provider = kubernetes.ams3
  metadata {
    name = "cert-manager"
    labels = {
      name = "cert-manager"
    }
  }
}

data "http" "cert_manager_values" {
  url = "https://raw.githubusercontent.com/digitalocean/marketplace-kubernetes/master/stacks/cert-manager/values.yml"
}


resource "helm_release" "ams3_cert_manager" {
  provider   = helm.ams3
  name       = "cert-manager"
  namespace  = kubernetes_namespace_v1.ams3_cert_manager.metadata[0].name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.13.3"
  values = [
    data.http.cert_manager_values.response_body
  ]
}


