# metrics-server: fonte das métricas de CPU/memória usadas pelo HPA da
# aplicação (escalabilidade exigida no PDF).
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_chart_version
  namespace  = "kube-system"

  depends_on = [aws_eks_node_group.this]
}

# Integração Kubernetes do New Relic (RFC-005): CPU e memória de nós e pods,
# estado dos objetos (kube-state-metrics), eventos do cluster e metadados do
# Kubernetes nos traces do APM. Logs dos pods desligados: o agente Java da
# aplicação já envia os logs, e duplicar consumiria a cota do free tier.
resource "helm_release" "newrelic" {
  count = var.newrelic_license_key == "" ? 0 : 1

  name             = "newrelic-bundle"
  repository       = "https://helm-charts.newrelic.com"
  chart            = "nri-bundle"
  version          = var.nri_bundle_chart_version
  namespace        = "newrelic"
  create_namespace = true

  set = [
    { name = "global.cluster", value = aws_eks_cluster.this.name },
    { name = "global.lowDataMode", value = "true" },
    { name = "newrelic-infrastructure.enabled", value = "true" },
    { name = "kube-state-metrics.enabled", value = "true" },
    { name = "nri-kube-events.enabled", value = "true" },
    { name = "nri-metadata-injection.enabled", value = "true" },
    { name = "newrelic-logging.enabled", value = "false" },
    { name = "newrelic-prometheus-agent.enabled", value = "false" },
    { name = "newrelic-pixie.enabled", value = "false" },
    { name = "pixie-chart.enabled", value = "false" },
    { name = "k8s-agents-operator.enabled", value = "false" },
  ]

  set_sensitive = [
    { name = "global.licenseKey", value = var.newrelic_license_key },
  ]

  depends_on = [aws_eks_node_group.this, helm_release.metrics_server]
}
