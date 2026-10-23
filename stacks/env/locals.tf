locals {
  shared_prefix = "/${var.project_name}/shared"
  env_prefix    = "/${var.project_name}/${var.environment}"

  node_port = var.node_ports[var.environment]

  shared = { for k, p in data.aws_ssm_parameter.shared : k => p.value }

  tags = {
    Project     = "postech-16soat"
    Repository  = "postech-16soat-infra-k8s"
    Stack       = "env"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
