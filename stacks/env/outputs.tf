output "environment" {
  value = var.environment
}

output "api_endpoint" {
  description = "URL pública da API do ambiente"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "app_node_port" {
  value = local.node_port
}

output "k8s_namespace" {
  value = kubernetes_namespace_v1.this.metadata[0].name
}
