terraform {
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }

  # O bucket (tfstate-<id-da-conta>-postech-16soat) é criado pelo próprio
  # pipeline e passado em `terraform init -backend-config=bucket=...`
  # (ver scripts/tf.sh).
  backend "s3" {
    key          = "infra-k8s/shared.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
