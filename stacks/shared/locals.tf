data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # AWS Academy: só existe a LabRole (não é possível criar IAM roles).
  lab_role_arn = "arn:aws:iam::${local.account_id}:role/LabRole"
  # Role assumida pela sessão do lab (CLI, console e GitHub Actions).
  voclabs_role_arn = "arn:aws:iam::${local.account_id}:role/voclabs"

  # Prefixo do contrato entre repositórios no SSM Parameter Store (P4).
  ssm_prefix = "/${var.project_name}/shared"

  tags = {
    Project    = "postech-16soat"
    Repository = "postech-16soat-infra-k8s"
    Stack      = "shared"
    ManagedBy  = "terraform"
  }
}
