# P7: um listener + target group por ambiente no NLB interno compartilhado,
# apontando para o NodePort fixo do Service da aplicação neste namespace.
resource "aws_lb_target_group" "app" {
  name        = "tg-${var.project_name}-${var.environment}"
  port        = local.node_port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = local.shared["vpc-id"]

  health_check {
    protocol            = "HTTP"
    path                = var.app_health_path
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = local.shared["nlb-arn"]
  port              = local.node_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Registra os nós do node group (via Auto Scaling Group) no target group.
resource "aws_autoscaling_attachment" "app" {
  autoscaling_group_name = local.shared["eks-node-asg-name"]
  lb_target_group_arn    = aws_lb_target_group.app.arn
}

# Os nós usam o security group do cluster; libera só o NodePort deste
# ambiente para dentro da VPC (NLB e VPC Link).
resource "aws_vpc_security_group_ingress_rule" "node_port" {
  security_group_id = local.shared["eks-cluster-sg-id"]
  description       = "NodePort da aplicacao (${var.environment}) a partir da VPC"
  cidr_ipv4         = local.shared["vpc-cidr"]
  ip_protocol       = "tcp"
  from_port         = local.node_port
  to_port           = local.node_port
}
