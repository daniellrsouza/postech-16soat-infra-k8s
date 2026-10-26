variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo dos recursos (mantém eks-tech-challenge e o ECR tech-challenge-backend das fases anteriores)"
  type        = string
  default     = "tech-challenge"
}

variable "cidr_vpc" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs usadas pelas subnets públicas (nós) e privadas (NLB, RDS, Lambda, VPC Link)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes do cluster EKS"
  type        = string
  default     = "1.36"
}

variable "node_instance_types" {
  description = "Tipos de instância do node group"
  type        = list(string)
  default     = ["t3.medium"]
}

# Orçamento do lab (D31): no máximo 2 nós; min 0 permite desligar os nós fora
# do horário de trabalho (scripts/nos.sh).
variable "node_scaling" {
  description = "Tamanho do node group (min/desired/max)"
  type = object({
    min     = number
    desired = number
    max     = number
  })
  default = {
    min     = 0
    desired = 2
    max     = 2
  }
}

variable "metrics_server_chart_version" {
  description = "Versão do chart oficial do metrics-server (necessário para o HPA)"
  type        = string
  default     = "3.14.0"
}

variable "newrelic_license_key" {
  description = "License key (INGEST) do New Relic para a integração Kubernetes. Vazio = integração não instalada"
  type        = string
  sensitive   = true
  default     = ""
}

variable "nri_bundle_chart_version" {
  description = "Versão do chart nri-bundle do New Relic"
  type        = string
  default     = "8.0.36"
}
