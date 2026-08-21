variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "tech-challenge"
}

variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    "Name" = "tech-challenge"
  }
}

variable "awsAcademyRole" {
  description = "AWS Academy role ARN"
  type        = string
  default     = "arn:aws:iam::426378709051:role/LabRole"
}

variable "instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

# Preencha os valores reais em terraform.tfvars (gitignored) ou via env vars
# TF_VAR_db_user, TF_VAR_db_pass, etc. Nunca coloque valor default aqui -
# isso viraria o segredo committado no lugar do secret.yaml.
variable "db_user" {
  description = "Usuario do Postgres"
  type        = string
  sensitive   = true
}

variable "db_pass" {
  description = "Senha do Postgres"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Chave HMAC para assinatura dos JWT (minimo 32 bytes)"
  type        = string
  sensitive   = true
}

variable "mail_username" {
  description = "Usuario SMTP para envio de e-mail"
  type        = string
  sensitive   = true
}

variable "mail_password" {
  description = "Senha/app-password SMTP"
  type        = string
  sensitive   = true
}