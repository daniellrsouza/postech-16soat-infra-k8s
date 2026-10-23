# Contrato com os demais repositórios (P4).
locals {
  ssm_parameters = {
    "k8s-namespace"              = kubernetes_namespace_v1.this.metadata[0].name
    "app-node-port"              = tostring(local.node_port)
    "apigateway-api-id"          = aws_apigatewayv2_api.this.id
    "apigateway-api-endpoint"    = aws_apigatewayv2_api.this.api_endpoint
    "apigateway-execution-arn"   = aws_apigatewayv2_api.this.execution_arn
    "apigateway-app-integration" = aws_apigatewayv2_integration.app.id
  }
}

resource "aws_ssm_parameter" "env" {
  for_each = local.ssm_parameters

  name  = "${local.env_prefix}/${each.key}"
  type  = "String"
  value = each.value
}
