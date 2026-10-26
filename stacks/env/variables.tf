variable "environment" {
  description = "Ambiente: homolog (branch develop) ou prod (branch main)"
  type        = string

  validation {
    condition     = contains(["homolog", "prod"], var.environment)
    error_message = "environment deve ser homolog ou prod."
  }
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo dos recursos (igual ao do stack shared)"
  type        = string
  default     = "tech-challenge"
}

# P7: porta fixa do Service NodePort da aplicação em cada namespace.
# O manifest da aplicação (repo postech-16soat-app) precisa usar a mesma porta.
variable "node_ports" {
  description = "NodePort do Service da aplicação por ambiente"
  type        = map(number)
  default = {
    prod    = 30080
    homolog = 30081
  }
}

variable "app_health_path" {
  description = "Path do health check do target group"
  type        = string
  default     = "/actuator/health"
}

variable "access_log_retention_days" {
  description = "Retenção dos access logs do API Gateway"
  type        = number
  default     = 7
}
