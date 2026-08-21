resource "kubectl_manifest" "hpa" {
  depends_on         = [kubectl_manifest.deployment, kubectl_manifest.metrics_server]
  yaml_body          = file("${local.k8s_manifests}/app-hpa.yaml")
  override_namespace = local.k8s_namespace
}
