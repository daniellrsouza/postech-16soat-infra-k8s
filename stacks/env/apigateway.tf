# Uma HTTP API por ambiente (D9). As rotas e o Lambda Authorizer são criados
# pelo repo postech-16soat-lambda (D14), usando o id da API e da integração
# publicados no SSM.
resource "aws_apigatewayv2_api" "this" {
  name          = "api-${var.project_name}-${var.environment}"
  protocol_type = "HTTP"
  description   = "Entrada da API da oficina (${var.environment})"
}

resource "aws_cloudwatch_log_group" "access" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.this.name}"
  retention_in_days = var.access_log_retention_days
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  # Access log em JSON. $context.requestId é obrigatório no formato e é o
  # mesmo valor repassado ao backend no header X-Correlation-Id.
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      correlationId      = "$context.requestId"
      requestTime        = "$context.requestTime"
      httpMethod         = "$context.httpMethod"
      routeKey           = "$context.routeKey"
      path               = "$context.path"
      status             = "$context.status"
      responseLatency    = "$context.responseLatency"
      integrationLatency = "$context.integrationLatency"
      integrationStatus  = "$context.integrationStatus"
      integrationError   = "$context.integrationErrorMessage"
      authorizerError    = "$context.authorizer.error"
      errorMessage       = "$context.error.message"
      sourceIp           = "$context.identity.sourceIp"
      userAgent          = "$context.identity.userAgent"
    })
  }
}

# Integração privada com a aplicação no EKS: VPC Link → listener do NLB do
# ambiente. Com stage $default o path chega inteiro; não há reescrita.
resource "aws_apigatewayv2_integration" "app" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = aws_lb_listener.app.arn
  connection_type    = "VPC_LINK"
  connection_id      = local.shared["apigateway-vpc-link-id"]

  # Correlação entre requisições (E5.2): o backend recebe o mesmo id do
  # access log do gateway.
  request_parameters = {
    "overwrite:header.X-Correlation-Id" = "$context.requestId"
  }
}
