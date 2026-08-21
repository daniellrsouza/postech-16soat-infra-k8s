# A criacao deste recurso e gratuita. Custo real (ELB/ALB) so aparece se um
# ingress controller (ex.: ingress-nginx) for instalado no cluster para
# atender a classe "nginx" definida no manifest.
resource "kubectl_manifest" "ingress" {
  depends_on         = [kubectl_manifest.service]
  yaml_body          = file("${local.k8s_manifests}/app-ingress.yaml")
  override_namespace = local.k8s_namespace
}
