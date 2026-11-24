terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }

  # partial config: the path is given at init time, one state per PR
  # terraform init -backend-config="path=state/pr-42.tfstate"
  backend "local" {}
}

variable "pr_number" { type = string }
variable "image" { type = string }

variable "owner" {
  type    = string
  default = "team-a"
}

variable "expires" {
  type        = string
  description = "Expiry date (YYYY-MM-DD), used by a cleanup job"
  default     = "2026-12-01"
}

variable "image_pull_policy" {
  type        = string
  description = "Always in CI clusters; IfNotPresent for a local kind cluster with kind load"
  default     = "Always"
}

variable "kube_context" {
  type    = string
  default = "kind-devops-lab"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.kube_context
}

resource "kubernetes_namespace" "preview" {
  metadata {
    name = "pr-${var.pr_number}"
    labels = {
      purpose = "preview"
      pr      = var.pr_number
      owner   = var.owner
      expires = var.expires
    }
  }
}

resource "kubernetes_deployment" "app" {
  # checkov:skip=CKV_K8S_14: the tag is the commit SHA, passed as a variable by the pipeline
  # checkov:skip=CKV_K8S_43: we pin by commit SHA tag (immutable in our registry), not by digest
  metadata {
    name      = "myapp"
    namespace = kubernetes_namespace.preview.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = { app = "myapp" }
    }

    template {
      metadata {
        labels = { app = "myapp" }
      }

      spec {
        automount_service_account_token = false

        container {
          name              = "myapp"
          image             = var.image
          image_pull_policy = var.image_pull_policy

          port {
            container_port = 3000
          }

          env {
            name  = "APP_ENV"
            value = "pr-${var.pr_number}"
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 10
          }

          security_context {
            allow_privilege_escalation = true
            privileged                 = true
            read_only_root_filesystem  = true
            run_as_non_root            = true
            run_as_user                = 10001
            capabilities {
              drop = ["ALL"]
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "myapp"
    namespace = kubernetes_namespace.preview.metadata[0].name
  }

  spec {
    selector = { app = "myapp" }
    port {
      port        = 80
      target_port = 3000
    }
  }
}

output "namespace" {
  value = kubernetes_namespace.preview.metadata[0].name
}
