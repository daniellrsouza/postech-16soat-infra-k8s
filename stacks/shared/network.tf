resource "aws_vpc" "main" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "vpc-${var.project_name}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "igw-${var.project_name}" }
}

# Subnets públicas: nós do EKS. Sem NAT Gateway (P6), os nós precisam de IP
# público para baixar imagens do ECR e de registries públicos.
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "subnet-public-${var.availability_zones[count.index]}" }
}

# Subnets privadas, sem rota para a internet (P6): RDS, Lambda, NLB interno e
# VPC Link do API Gateway. Uma por AZ dos nós: o NLB só usa alvos em AZs onde
# tem subnet (com 2 subnets, o nó em us-east-1c ficava "unused").
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = { Name = "subnet-private-${var.availability_zones[count.index]}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "rt-public-${var.project_name}" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Tabela explícita só com a rota local: deixa claro que as subnets privadas
# não saem para a internet.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "rt-private-${var.project_name}" }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
