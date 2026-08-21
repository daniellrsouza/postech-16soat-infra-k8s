resource "kubectl_manifest" "pdb" {
  depends_on         = [kubectl_manifest.deployment]
  yaml_body          = file("${local.k8s_manifests}/app-pdb.yaml")
  override_namespace = local.k8s_namespace
}
