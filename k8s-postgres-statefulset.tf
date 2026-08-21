resource "kubectl_manifest" "postgres_statefulset" {
  depends_on = [
    kubectl_manifest.configmap,
    kubectl_manifest.secret,
    kubectl_manifest.postgres_service,
    kubectl_manifest.storageclass_gp3,
  ]
  yaml_body          = file("${local.k8s_manifests}/postgres-statefulset.yaml")
  override_namespace = local.k8s_namespace

  # Mesmo motivo do k8s-deployment.tf: nao arriscar estourar os 15min do
  # token de auth do EKS esperando o rollout do StatefulSet.
  wait_for_rollout = false
}
