resource "aws_eks_cluster" "this" {
  name     = "eks-${var.project_name}"
  version  = var.kubernetes_version
  role_arn = local.lab_role_arn

  access_config {
    authentication_mode = "API"
    # O acesso da role voclabs é declarado explicitamente abaixo; com o
    # bootstrap automático ligado, a mesma entrada seria criada duas vezes.
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    subnet_ids = aws_subnet.public[*].id
  }
}

# voclabs: role assumida pela sessão do AWS Academy (CLI, console e pipelines).
resource "aws_eks_access_entry" "voclabs" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = local.voclabs_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "voclabs_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.voclabs.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# Hop limit 2: pods (ex.: agente do New Relic) alcançam o IMDS do nó, já que o
# projeto não usa IRSA e depende das credenciais da LabRole no nó.
resource "aws_launch_template" "node" {
  name_prefix = "lt-${var.project_name}-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "node-${var.project_name}" })
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "nodeg-${var.project_name}"
  node_role_arn   = local.lab_role_arn
  subnet_ids      = aws_subnet.public[*].id
  instance_types  = var.node_instance_types

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  scaling_config {
    min_size     = var.node_scaling.min
    desired_size = var.node_scaling.desired
    max_size     = var.node_scaling.max
  }

  update_config {
    max_unavailable = 1
  }

  # desired_size muda fora do Terraform (scripts/nos.sh desliga/liga os nós).
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [aws_eks_access_policy_association.voclabs_admin]
}
