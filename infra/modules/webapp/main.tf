terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_image" "app" {
  name         = var.image
  keep_locally = true
}

resource "docker_container" "web" {
  name  = "webapp-${var.env_name}"
  image = docker_image.app.image_id

  env = ["APP_ENV=${var.env_name}"]

  ports {
    internal = var.internal_port
    external = var.external_port
  }

  labels {
    label = "env"
    value = var.env_name
  }
}
