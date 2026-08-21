resource "kubectl_manifest" "postgres_service" {
  depends_on         = [kubectl_manifest.namespace]
  yaml_body          = file("${local.k8s_manifests}/postgres-service.yaml")
  override_namespace = local.k8s_namespace
}
