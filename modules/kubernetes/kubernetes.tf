terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.1.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.1.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

variable "aether_ip" {
  type = string
}

provider "kubernetes" {
  host        = "https://${var.aether_ip}:6443"
  config_path = ".temp/kubeconfig"
}

provider "helm" {
  kubernetes {
    host        = "https://${var.aether_ip}:6443"
    config_path = ".temp/kubeconfig"
  }
}

resource "random_password" "postgres" {
  length = 16
}

resource "helm_release" "aether-postgres" {
  name       = "aether-postgres"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"

  set_sensitive {
    name  = "postgresqlPassword"
    value = random_password.postgres.result
  }

}

resource "kubernetes_namespace" "shinoa" {
  metadata {
    name = "shinoa"
  }
}

resource "kubernetes_secret" "shinoa_db" {
  metadata {
    namespace = kubernetes_namespace.shinoa.id
    name      = "db"
  }

  data = {
    database_url = "postgresql://postgres:${random_password.postgres.result}@aether-postgres.default.svc.cluster.local/shinoa"
  }
}
