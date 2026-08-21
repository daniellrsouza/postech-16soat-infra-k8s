resource "kubectl_manifest" "configmap" {
  depends_on         = [kubectl_manifest.namespace]
  yaml_body          = file("${local.k8s_manifests}/configmap.yaml")
  override_namespace = local.k8s_namespace
}
