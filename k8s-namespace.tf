resource "kubectl_manifest" "namespace" {
  depends_on = [aws_eks_cluster.cluster, aws_eks_node_group.node_group]
  yaml_body  = file("${local.k8s_manifests}/namespace.yaml")
}