variable "env_name" {
  type        = string
  description = "Environment name, used in the container name"
}

variable "image" {
  type        = string
  description = "Docker image (tag = commit SHA)"
}

variable "external_port" {
  type        = number
  description = "Port exposed on the host"
}

variable "internal_port" {
  type        = number
  description = "Port of the app inside the container"
  default     = 3000
}
