resource "kubectl_manifest" "service" {
  depends_on         = [kubectl_manifest.namespace]
  yaml_body          = file("${local.k8s_manifests}/app-service.yaml")
  override_namespace = local.k8s_namespace
}
