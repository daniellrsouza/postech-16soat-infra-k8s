resource "kubectl_manifest" "deployment" {
  depends_on = [
    kubectl_manifest.configmap,
    kubectl_manifest.secret,
    kubectl_manifest.postgres_service,
    kubectl_manifest.postgres_statefulset,
  ]
  # k8s/app-deployment.yaml usa "tech-challenge-backend:latest" (imagem local,
  # carregada via `kind load docker-image` no fluxo de dev com Kind). No EKS
  # nao existe equivalente, entao trocamos pela imagem publicada no ECR aqui,
  # sem precisar duplicar ou "templatizar" o manifest compartilhado.
  yaml_body = replace(
    file("${local.k8s_manifests}/app-deployment.yaml"),
    "image: tech-challenge-backend:latest",
    "image: ${aws_ecr_repository.app.repository_url}:latest"
  )
  override_namespace = local.k8s_namespace

  # O token de auth do EKS (data.aws_eks_cluster_auth) e gerado uma vez no
  # inicio do apply e expira em 15min - nao e renovado durante a execucao.
  # Esperar o rollout aqui arrisca estourar esse prazo (ainda mais se o pod
  # ficar preso por imagem ausente no ECR). Confirme o rollout manualmente
  # com `kubectl -n tech-challenge get pods -w` depois do apply.
  wait_for_rollout = false
}
