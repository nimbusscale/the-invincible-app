terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_project" "the_invincible_app" {
  name = "the-invincible-app"
}

resource "digitalocean_vpc" "ams3" {
  name   = "invincible-app-ams3"
  region = "ams3"
}

resource "digitalocean_vpc" "nyc1" {
  name   = "invincible-app-nyc1"
  region = "nyc1"
}

resource "digitalocean_vpc_peering" "ams3_nyc1" {
  name = "invincible-app-ams3-nyc1"
  vpc_ids = [
    digitalocean_vpc.ams3.id,
    digitalocean_vpc.nyc1.id
  ]
}

resource "digitalocean_database_cluster" "ams3" {
  name                 = "invincible-app-ams3"
  engine               = "pg"
  version              = "16"
  size                 = "db-s-1vcpu-2gb"
  region               = "ams3"
  node_count           = 2
  private_network_uuid = digitalocean_vpc.ams3.id
  project_id           = digitalocean_project.the_invincible_app.id
}

resource "digitalocean_database_firewall" "ams3" {
  cluster_id = digitalocean_database_cluster.ams3.id

  rule {
    type  = "ip_addr"
    value = digitalocean_vpc.ams3.ip_range
  }

  rule {
    type  = "ip_addr"
    value = digitalocean_vpc.nyc1.ip_range
  }
}

resource "digitalocean_database_replica" "nyc1" {
  cluster_id           = digitalocean_database_cluster.ams3.id
  name                 = "invincible-app-nyc1"
  size                 = "db-s-1vcpu-2gb"
  region               = "nyc1"
  private_network_uuid = digitalocean_vpc.nyc1.id
}

resource "digitalocean_database_firewall" "nyc1" {
  cluster_id = digitalocean_database_replica.nyc1.uuid

  rule {
    type  = "ip_addr"
    value = digitalocean_vpc.ams3.ip_range
  }

  rule {
    type  = "ip_addr"
    value = digitalocean_vpc.nyc1.ip_range
  }
}

resource "digitalocean_kubernetes_cluster" "ams3" {
  name    = "invincible-app-ams3"
  region  = "ams3"
  version = "1.32.2-do.0"
  vpc_uuid = digitalocean_vpc.ams3.id
  ha = true
  destroy_all_associated_resources = true
  registry_integration = true
  node_pool {
    name = "default"
    size = "s-1vcpu-2gb"
    auto_scale = true
    min_nodes = 2
    max_nodes = 4
  }
}


resource "digitalocean_kubernetes_cluster" "nyc1" {
  name    = "invincible-app-nyc1"
  region  = "nyc1"
  version = "1.32.2-do.0"
  vpc_uuid = digitalocean_vpc.nyc1.id
  ha = true
  destroy_all_associated_resources = true
  registry_integration = true
  node_pool {
    name = "default"
    size = "s-1vcpu-2gb"
    auto_scale = true
    min_nodes = 2
    max_nodes = 4
  }
}

resource "digitalocean_project_resources" "invincible_app_ams3" {
  project = digitalocean_project.the_invincible_app.id
  resources = [
    digitalocean_kubernetes_cluster.ams3.urn,
    digitalocean_kubernetes_cluster.nyc1.urn
  ]
}
