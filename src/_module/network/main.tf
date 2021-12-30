# Network設定(VPC, Subnet, IGW, RouteTable  の設定)

# ==============================================================
# VPC
# cidr,tag_name
# ==============================================================
# VPC 作成(最低限: sidr とtag )
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true  # DNS解決を有効化
  enable_dns_support   = true  # DNSホスト名を有効化

  tags = {
    Name = var.app_name
  }
}
#================================================================
# Subnet
# VPC選択, name, AZ, cidr
#================================================================
# Subnets(Public)
resource "aws_subnet" "publics" {
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true   # instanceにパブリックIPを自動的に割り当てる

  tags = {
    Name = "${var.app_name}-public-${count.index}"
  }
}

# RDS, ECS
resource "aws_subnet" "privates" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  availability_zone = var.azs[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]

  tags = {
    Name = "${var.app_name}-private-${count.index}"
  }
}

# EC2用(踏み台) private subnet
resource "aws_subnet" "ec2" {
  cidr_block        = "10.0.100.0/24"
  availability_zone = "ap-northeast-1a"
  vpc_id            = aws_vpc.main.id

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-ec2"
  }
}

# ==================================================================
# IGW (インターネットゲートウェイ)
# tag_name, vpc選択(Attached)
# ==================================================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.app_name
  }
}

# ==================================================================
# RouteTable
# VPC作成時に自動生成される項目
# IGW => public に流す設定
# ==================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-route_table"
  }
}

# Route  :RouteTable に IGW へのルートを指定してあげる
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.public.id
  gateway_id = aws_internet_gateway.main.id
}

# RouteTableAssociation(Public)  :RouteTable にsubnet を関連付け => インターネット通信可能に
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id = element(aws_subnet.publics.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# RouteTableAssociation(EC2) EC2 subnet と関連付け
resource "aws_route_table_association" "ec2" {
  subnet_id = aws_subnet.ec2.id
  route_table_id = aws_route_table.public.id
}

# ==================================================================
# NAT gate way          *インターネットからprivate には直接通信ができないため
# count で同時に複数作成
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
# ==================================================================
# NAT (1NAT : 1EIP が必要)
resource "aws_nat_gateway" "ecs" {
  count         = length(aws_subnet.publics)
  allocation_id = aws_eip.natgateway[count.index].id
  # Publicに配置するのでsubnet_idはpublicとする。
  subnet_id = aws_subnet.publics[count.index].id

  tags = {
    Name = "${var.app_name}-Fargate-NAT gw"
  }
}

# Fargate用のNAT gateway用EIP
resource "aws_eip" "natgateway" {
  vpc   = true
  count = length(aws_subnet.publics)
  tags = {
    Name = "${var.app_name}-Fargate"
  }
}

resource "aws_route_table" "private" {
  count  = length(aws_subnet.publics)
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.app_name}-private-${count.index}"
  }
}

# RouteTable にsubnet を関連付け、FargateにDockerPullできるように設定
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id = element(aws_subnet.privates.*.id, count.index)
  route_table_id = aws_route_table.private[count.index].id
}

# RouteTable に NAT へのルートを指定してあげる(Nat 設定はこれでおｋ)
resource "aws_route" "private" {
  count                  = length(aws_subnet.privates)
  route_table_id         = aws_route_table.private[count.index].id
  nat_gateway_id         = aws_nat_gateway.ecs[count.index].id
  destination_cidr_block = "0.0.0.0/0"
}