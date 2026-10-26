# Namespace do ambiente (D9); os recursos da aplicação dentro dele são
# aplicados pelo pipeline do repo postech-16soat-app.
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.environment

    labels = {
      "app.kubernetes.io/part-of" = "postech-16soat"
      environment                 = var.environment
    }
  }
}
