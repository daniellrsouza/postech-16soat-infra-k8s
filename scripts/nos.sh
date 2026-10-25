#!/usr/bin/env bash
# Liga/desliga os nós do EKS para economizar o orçamento do lab (D31).
#
#   scripts/nos.sh desligar   node group em 0 nós (fim do dia)
#   scripts/nos.sh ligar      node group em 2 nós e espera ficarem Ready
#   scripts/nos.sh status     tamanho do node group e nós Ready
#
# O control plane do EKS, o NLB e o RDS continuam cobrando com os nós
# desligados; a aplicação fica fora do ar até religar.
set -euo pipefail

CLUSTER="eks-tech-challenge"
NODEGROUP="nodeg-tech-challenge"
REGION="${AWS_REGION:-us-east-1}"
NOS_LIGADOS=2

escalar() {
  aws eks update-nodegroup-config --region "$REGION" --cluster-name "$CLUSTER" \
    --nodegroup-name "$NODEGROUP" --scaling-config "minSize=0,maxSize=${NOS_LIGADOS},desiredSize=$1" \
    --query "update.status" --output text
}

prontos() {
  kubectl get nodes --no-headers 2>/dev/null | tr -d '\r' | awk '$2 == "Ready"' | wc -l
}

case "${1:-}" in
  desligar)
    escalar 0
    echo "Node group indo para 0 nós. A aplicação fica fora do ar até 'scripts/nos.sh ligar'."
    ;;
  ligar)
    escalar "$NOS_LIGADOS"
    aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER" >/dev/null
    echo "Aguardando ${NOS_LIGADOS} nós Ready..."
    for _ in $(seq 1 40); do
      if [ "$(prontos)" -ge "$NOS_LIGADOS" ]; then
        echo "${NOS_LIGADOS} nós Ready."
        exit 0
      fi
      sleep 15
    done
    echo "Os nós não ficaram Ready em 10 minutos. Rode scripts/atualizar-secrets-aws.sh (repo app) para reiniciar os não registrados." >&2
    exit 1
    ;;
  status)
    aws eks describe-nodegroup --region "$REGION" --cluster-name "$CLUSTER" --nodegroup-name "$NODEGROUP" \
      --query "nodegroup.scalingConfig" --output text
    echo "Nós Ready: $(prontos)"
    ;;
  *)
    sed -n '2,9p' "$0" >&2
    exit 1
    ;;
esac
