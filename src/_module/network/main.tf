# Network設定(VPC, Subnet, IGW, RouteTable  の設定)

# ==============================================================
# VPC
# cidr,tag_name
# ==============================================================
# VPC 作成(最低限: sidr とtag )
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true # DNS解決を有効化
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

  availability_zone = var.azs[count.index]
  cidr_block = var.public_subnet_cidrs[count.index]

  tags = {
    Name = "${var.app_name}-public-${count.index}"
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

# RDS用 private subnet
resource "aws_subnet" "privates" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  availability_zone = var.azs[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]

  tags = {
    Name = "${var.app_name}-private-${count.index}"
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
# NAT gate way
# インターネットからprivate には直接通信ができないため
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
# ==================================================================

# EIP (ElasticIP)
resource "aws_eip" "nat_1" {
  vpc = true

  tags = {
    Name = "${var.app_name}-nat-eip-1"
  }
}

# Nat2で使用するEIP(冗長化)
resource "aws_eip" "nat_2" {
  vpc = true

  tags = {
    Name = "${var.app_name}-nat-eip-2"
  }
}

# NAT (1NAT : 1EIP が必要)
resource "aws_nat_gateway" "main_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.publics[1].id

  tags = {
    Name = "${var.app_name}-nat-1"
  }

  depends_on = [aws_internet_gateway.main]
}

# Nat2(冗長化)
resource "aws_nat_gateway" "main_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.publics[2].id

  tags = {
    Name = "${var.app_name}-nat-2"
  }

  depends_on = [aws_internet_gateway.main]
}

# RouteTable に NAT_1 へのルートを指定してあげる(Nat 設定はこれでおｋ)
resource "aws_route" "private_1" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.private.id
  nat_gateway_id = aws_nat_gateway.main_1.id
}

# RouteTable に NAT_2 へのルートを指定してあげる(Nat 設定はこれでおｋ)
resource "aws_route" "private_2" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.private.id
  nat_gateway_id = aws_nat_gateway.main_2.id
}

# NAT => private に流す設定 ( private 用の route-table が別途必要
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

# RouteTableAssociation(Public)  :RouteTable にsubnet を関連付け
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id = element(aws_subnet.privates.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

