provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

# Token obtido via `aws eks get-token` a cada chamada: não expira no meio de
# um apply longo, ao contrário do data source aws_eks_cluster_auth (15 min).
provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.this.name, "--region", var.aws_region]
    }
  }
}
