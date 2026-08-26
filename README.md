# Infra

Infrastructure as Code (Terraform) para subir a mesma aplicação documentada em
[`../README.md`](../README.md) num cluster **EKS** real na AWS, reaproveitando os
manifests de [`../k8s/`](../k8s/).

## Visão geral

Esta pasta provisiona:
- A rede e o cluster **EKS** (VPC, subnets, node group) onde a aplicação roda;
- Um repositório **ECR** para a imagem da aplicação;
- Os mesmos recursos Kubernetes de `../k8s/` (Namespace, ConfigMap, Secret, Postgres,
  Deployment, Service, Ingress, HPA, PDB), aplicados via provider `kubectl` — não via
  Kustomize.

Providers usados: `aws` (recursos de rede/EKS/ECR), `kubectl` (aplica os manifests
Kubernetes) e `kubernetes` (configurado, mas nenhum recurso `kubernetes_*` é usado nos
arquivos `.tf` desta pasta).

Para o passo a passo operacional completo (configurar segredos, `terraform apply`,
publicar a imagem no ECR, testar via port-forward, autoscaling, `terraform destroy`),
veja a seção **"☁️ Deploy na AWS (EKS via Terraform)"** em [`../README.md`](../README.md).
Este documento foca na infraestrutura em si: o que existe, como as peças se relacionam
e como o Terraform se relaciona com `../k8s/`.

## Estrutura

```text
infra/
├── providers.tf                # Terraform + providers: aws, kubectl, kubernetes
├── backend.tf                  # Backend remoto do state (S3)
├── vars.tf                     # Variáveis de entrada (não sensíveis e sensíveis)
├── output.tf                   # Outputs (ex.: comando pronto pra configurar o kubectl)
├── locals.tf                   # Namespace k8s e caminho pra ../k8s/
├── data.tf                     # Data sources (conta AWS, cluster EKS, token de auth)
├── terraform.tfvars.example    # Template das variáveis sensíveis (copiar → terraform.tfvars)
│
├── vpc.tf, subnet.tf, route-table.tf,
│   internet-gw.tf, security-group.tf     # Rede: VPC, 3 subnets públicas, IGW, rota default, Security Group
├── eks-cluster.tf, eks-node.tf,
│   launch-template.tf, access_entry.tf   # Cluster EKS, node group e acesso da role do AWS Academy
├── ecr.tf                                # Repositório ECR da imagem da aplicação
│
└── k8s-namespace.tf, k8s-configmap.tf, k8s-secret.tf,
    k8s-postgres-service.tf, k8s-postgres-statefulset.tf,
    k8s-storageclass.tf, k8s-ebs-csi-addon.tf,
    k8s-service.tf, k8s-deployment.tf, k8s-hpa.tf,
    k8s-ingress.tf, k8s-pdb.tf, k8s-metrics-server.tf   # Aplicam os manifests de ../k8s/ via kubectl_manifest
```

## Pré-requisitos

Conforme declarado nos arquivos Terraform:
- **Terraform** `>= 0.13` (`providers.tf`) — sem versão fixada para o provider `aws`;
  `kubectl` (gavinbunney/kubectl) `>= 1.19.0` e `kubernetes` (hashicorp/kubernetes) `>= 2.36.0`.
- **AWS CLI** configurado com credenciais válidas (usadas pelo provider `aws` e pelo
  backend S3) — no AWS Academy, as credenciais temporárias do Learner Lab.
- **Acesso de leitura/escrita** ao bucket S3 do backend remoto: `tech-challenge-soat16-grupo15`
  (`backend.tf`).
- **kubectl** e **Docker**, necessários nos passos seguintes ao `apply` (publicar a
  imagem no ECR, port-forward) — ver `../README.md`.

## Providers

| Provider | Origem | Versão | Uso |
|---|---|---|---|
| `aws` | hashicorp | não fixada em `required_providers` | Rede, EKS, ECR, EKS Access Entry |
| `kubectl` | gavinbunney/kubectl | `>= 1.19.0` | Aplica os manifests de `../k8s/` como recursos `kubectl_manifest` |
| `kubernetes` | hashicorp/kubernetes | `>= 2.36.0` | Declarado e configurado em `providers.tf`, mas nenhum recurso `kubernetes_*` é usado nos arquivos analisados |

Os providers `kubectl` e `kubernetes` são configurados com as mesmas credenciais,
obtidas do próprio cluster criado nesta pasta (`data.aws_eks_cluster`,
`data.aws_eks_cluster_auth` em `data.tf`): endpoint, CA e um token de autenticação.

## Recursos provisionados

```text
Terraform
├── Rede — VPC (var.cidr_vpc), 3 subnets públicas (us-east-1a/b/c), Internet Gateway,
│          tabela de rotas (default → IGW), Security Group (ingress HTTP 80 aberto)
├── EKS — Cluster (versão 1.36, autenticação via Access Entry API), Node Group
│         (var.instance_types, 2–3 nós), Launch Template (IMDS hop limit 2, exigido
│         pelo EBS CSI driver), EKS Access Entry para a role `voclabs` (sessão pessoal
│         do AWS Academy, acesso de admin no cluster)
├── ECR — Repositório da imagem da aplicação + lifecycle policy (mantém só as 5
│         imagens mais recentes)
├── Addon — aws-ebs-csi-driver (necessário para a StorageClass usada pelo Postgres)
└── Recursos Kubernetes (aplicados a partir de ../k8s/, ver seção abaixo) — Namespace,
    ConfigMap, Secret, StorageClass, Service + StatefulSet do Postgres, Service +
    Deployment da aplicação, HPA, Ingress, PodDisruptionBudget, metrics-server
```

## Relação com a pasta k8s

O Terraform **não usa Kustomize**. Cada arquivo `k8s-*.tf` lê o YAML correspondente em
`../k8s/` com `file("${local.k8s_manifests}/<arquivo>.yaml")` (`local.k8s_manifests =
"${path.module}/../k8s"`, definido em `locals.tf`) e aplica o conteúdo como um recurso
`kubectl_manifest`, com `override_namespace = "tech-challenge"` — o namespace que,
no fluxo local com Kind, é injetado pelo `kustomization.yaml` (ver `../k8s/README.md`).

Fluxo, confirmado pelo código:

```text
../k8s/<arquivo>.yaml
        │  file(...)
        ▼
kubectl_manifest (provider kubectl, override_namespace = "tech-challenge")
        │
        ▼
Cluster EKS
```

Três exceções a esse padrão direto, todas documentadas em comentário no próprio
arquivo `.tf`:

- **`k8s-secret.tf`** não lê `../k8s/secret.yaml`. Esse arquivo só tem placeholders
  (fluxo local com Kind); o Secret real é construído em Terraform com `yamlencode()`,
  preenchido pelas variáveis sensíveis (`var.db_user`, `var.db_pass`, `var.jwt_secret`,
  `var.mail_username`, `var.mail_password`).
- **`k8s-deployment.tf`** lê `../k8s/app-deployment.yaml` mas troca a imagem local
  (`tech-challenge-backend:latest`, usada com `kind load docker-image` no fluxo local)
  pela imagem publicada no ECR (`replace()` na string do manifest).
- **`k8s-metrics-server.tf`** usa `data.kubectl_file_documents` para separar
  `../k8s/metrics-server.yaml` (múltiplos documentos YAML) e aplica cada um com
  `for_each`. Esse arquivo — e `../k8s/storage-class.yaml` — são específicos de EKS e
  **não** fazem parte do `kustomization.yaml` (não seriam aplicados por
  `kubectl apply -k k8s/` no Kind), mas são aplicados normalmente pelo Terraform.

## Variáveis

| Variável | Descrição | Obrigatória | Default |
|---|---|---|---|
| `aws_region` | Região AWS | Não | `us-east-1` |
| `project_name` | Nome usado para nomear os recursos (cluster, node group, SG) | Não | `tech-challenge` |
| `cidr_vpc` | Bloco CIDR da VPC | Não | `10.0.0.0/16` |
| `tags` | Tags aplicadas aos recursos | Não | `{ Name = "tech-challenge" }` |
| `awsAcademyRole` | ARN da role usada pelo cluster e pelo node group | Não | ARN da `LabRole` do AWS Academy |
| `instance_types` | Tipos de instância do node group | Não | `["t3.medium"]` |
| `db_user` | Usuário do Postgres | **Sim** | — (sensível) |
| `db_pass` | Senha do Postgres | **Sim** | — (sensível) |
| `jwt_secret` | Chave HMAC para assinatura dos JWT (mínimo 32 bytes) | **Sim** | — (sensível) |
| `mail_username` | Usuário SMTP | **Sim** | — (sensível) |
| `mail_password` | Senha/app-password SMTP | **Sim** | — (sensível) |

As 5 variáveis sensíveis não têm default (de propósito, conforme comentário em
`vars.tf`) e precisam ser fornecidas via `terraform.tfvars` (copiado de
`terraform.tfvars.example`, já no `.gitignore`) ou variáveis `TF_VAR_*` — detalhes e
o comando pra gerar um `jwt_secret` válido estão em `../README.md`.

## Outputs

| Output | Descrição |
|---|---|
| `vpc_cidr`, `vpc_id` | CIDR e ID da VPC criada |
| `subnet_cidr`, `subnet_id` | CIDR e ID de cada uma das 3 subnets públicas |
| `eks_cluster_name` | Nome do cluster EKS criado |
| `ecr_repository_url` | URL do repositório ECR criado |
| `configure_kubectl` | Comando pronto (`aws eks update-kubeconfig ...`) pra apontar o `kubectl` local para o cluster |
| `docker_build_and_push` | Comandos prontos (`docker login`/`build`/`push`) pra publicar a imagem da aplicação no ECR |

## Execução

Os comandos abaixo assumem que `terraform.tfvars` já foi criado e preenchido (ver
seção Variáveis) e que as credenciais AWS da sessão estão configuradas.

### Terraform init

```bash
cd infra
terraform init
```

Baixa os providers (`aws`, `kubectl`, `kubernetes`) e configura o backend remoto
(`backend.tf`).

### Terraform plan

```bash
terraform plan
```

Um único `apply` aqui cria rede, cluster EKS, node group e ~13 recursos Kubernetes de
uma vez — vale conferir o `plan` antes, especialmente após qualquer mudança nos
arquivos `.tf` ou nos manifests de `../k8s/`.

### Terraform apply

```bash
terraform apply
```

`kubectl_manifest.deployment` e `kubectl_manifest.postgres_statefulset` são aplicados
com `wait_for_rollout = false` (comentado nos respectivos `.tf`): o token de
`data.aws_eks_cluster_auth` expira em 15 minutos e não é renovado durante a execução,
então o Terraform não espera o rollout — confirme manualmente com
`kubectl -n tech-challenge get pods -w` depois do apply.

### Terraform destroy

```bash
terraform destroy
```

> ⚠️ O cluster EKS e os nodes (`t3.medium`) geram cobrança contínua enquanto
> existirem. Rode `destroy` assim que terminar os testes (mesmo aviso de
> `../README.md`).

## Fluxo de provisionamento

Ordem determinada pelos `depends_on` de cada recurso:

```text
terraform init (providers + backend S3)
        ↓
Rede (VPC, subnets, IGW, rota, security group)
        ↓
Cluster EKS + Node Group (+ launch template, + access entry da role voclabs)
        ↓
aws-ebs-csi-driver (addon)  →  StorageClass gp3
        ↓
Namespace  →  ConfigMap + Secret + Service (postgres)  →  StatefulSet (postgres)
        ↓
Service (app)  →  Deployment (app — imagem do ECR)
        ↓
metrics-server  →  HPA
        ↓
Ingress, PodDisruptionBudget
```

O repositório ECR (`ecr.tf`) é criado de forma independente desse encadeamento; a
publicação da imagem nele é manual, feita depois do `apply` (`terraform output
docker_build_and_push`, detalhado em `../README.md`).

## Troubleshooting

Particularidades específicas desta infraestrutura (para os problemas do cluster local
com Kind, veja `../k8s/README.md`; para os passos do fluxo AWS, `../README.md`):

- **`apply` termina, mas os pods do Deployment/StatefulSet não sobem** — esperado:
  `wait_for_rollout = false` em ambos por causa da expiração do token de autenticação
  do EKS (15 min). Acompanhe com `kubectl -n tech-challenge get pods -w`.
- **`aws-ebs-csi-driver` ou o Postgres falham por credenciais/permissão** — o node
  group usa a `LabRole` do AWS Academy (sem IRSA/OIDC), então o addon depende do
  próprio node alcançar o IMDS. O `launch-template.tf` já ajusta
  `http_put_response_hop_limit = 2` para isso; se o problema persistir, o ponto de
  partida é conferir se o node group está usando esse launch template.
- **Erro ao criar `aws_eks_access_entry`/associar a policy** — a role `voclabs`
  (`access_entry.tf`) é a role da sua própria sessão AWS Academy; precisa existir na
  conta em que o `apply` está rodando.
- **Erro no backend S3 (`backend.tf`)** — o bucket `tech-challenge-soat16-grupo15`
  precisa existir e ser acessível; não há tabela do DynamoDB configurada para lock do
  state, então evite rodar `apply`/`destroy` simultaneamente em duas sessões.
