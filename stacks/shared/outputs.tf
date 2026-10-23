output "eks_cluster_name" {
  value = aws_eks_cluster.this.name
}

output "configure_kubectl" {
  description = "Aponta o kubectl local para o cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.this.name}"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nlb_dns_name" {
  value = aws_lb.internal.dns_name
}

output "ssm_prefix" {
  description = "Prefixo dos parâmetros publicados para os outros repositórios"
  value       = local.ssm_prefix
}
