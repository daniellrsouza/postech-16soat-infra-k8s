# Contrato com os demais repositórios (P4): o stack env deste repo, o
# infra-db, a lambda e o pipeline da aplicação leem estes parâmetros.
locals {
  ssm_parameters = {
    "vpc-id"                 = aws_vpc.main.id
    "vpc-cidr"               = aws_vpc.main.cidr_block
    "public-subnet-ids"      = join(",", aws_subnet.public[*].id)
    "private-subnet-ids"     = join(",", aws_subnet.private[*].id)
    "eks-cluster-name"       = aws_eks_cluster.this.name
    "eks-cluster-sg-id"      = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
    "eks-node-asg-name"      = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name
    "ecr-repository-url"     = aws_ecr_repository.app.repository_url
    "nlb-arn"                = aws_lb.internal.arn
    "apigateway-vpc-link-id" = aws_apigatewayv2_vpc_link.this.id
  }
}

resource "aws_ssm_parameter" "shared" {
  for_each = local.ssm_parameters

  name  = "${local.ssm_prefix}/${each.key}"
  type  = strcontains(each.key, "subnet-ids") ? "StringList" : "String"
  value = each.value
}
