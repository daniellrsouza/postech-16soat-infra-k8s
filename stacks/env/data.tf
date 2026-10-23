# Saídas do stack shared, publicadas no SSM (P4).
data "aws_ssm_parameter" "shared" {
  for_each = toset([
    "vpc-id",
    "vpc-cidr",
    "eks-cluster-name",
    "eks-cluster-sg-id",
    "eks-node-asg-name",
    "nlb-arn",
    "apigateway-vpc-link-id",
  ])

  name = "${local.shared_prefix}/${each.key}"
}

data "aws_eks_cluster" "this" {
  name = local.shared["eks-cluster-name"]
}
