# Entrada privada do cluster (P7): API Gateway → VPC Link → NLB interno →
# NodePort do Service da aplicação em cada namespace. Listener e target
# group de cada ambiente ficam no stack env; aqui só o que é compartilhado.
resource "aws_lb" "internal" {
  name                             = "nlb-${var.project_name}"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = aws_subnet.private[*].id
  enable_cross_zone_load_balancing = true
}

resource "aws_security_group" "vpc_link" {
  name        = "vpclink-${var.project_name}"
  description = "VPC Link do API Gateway: so sai para dentro da VPC"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "vpclink-${var.project_name}" }
}

resource "aws_vpc_security_group_egress_rule" "vpc_link_to_vpc" {
  security_group_id = aws_security_group.vpc_link.id
  description       = "Trafego para o NLB interno"
  cidr_ipv4         = aws_vpc.main.cidr_block
  ip_protocol       = "tcp"
  from_port         = 30000
  to_port           = 32767
}

# Um VPC Link compartilhado pelas APIs de homolog e prod (D9).
resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "vpclink-${var.project_name}"
  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_link.id]
}
