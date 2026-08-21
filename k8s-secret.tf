resource "kubectl_manifest" "secret" {
  depends_on = [kubectl_manifest.namespace]

  # Ao contrario dos outros recursos, este NAO le k8s/secret.yaml - aquele
  # arquivo fica so com placeholders para o fluxo local com Kind (e pode
  # ficar versionado por isso). Aqui os valores reais vem de variaveis
  # sensitive, preenchidas via terraform.tfvars (gitignored) ou TF_VAR_*.
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name = "tech-challenge-secrets"
    }
    type = "Opaque"
    stringData = {
      DB_USER       = var.db_user
      DB_PASS       = var.db_pass
      JWT_SECRET    = var.jwt_secret
      MAIL_USERNAME = var.mail_username
      MAIL_PASSWORD = var.mail_password
    }
  })

  override_namespace = local.k8s_namespace
}
