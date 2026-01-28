resource "aws_vpc" "principal" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = local.project
  }
}

resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  cidr_block              = each.value.cidr_block
  vpc_id                  = aws_vpc.principal.id
  availability_zone       = data.aws_availability_zones.zones.names[each.value.az_index]
  map_public_ip_on_launch = true

  tags = {
    Project = local.project
    Name    = "${local.project}-${each.key}"
    Type    = "Public"
  }
}

resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  cidr_block        = each.value.cidr_block
  vpc_id            = aws_vpc.principal.id
  availability_zone = data.aws_availability_zones.zones.names[each.value.az_index]

  tags = {
    Project = local.project
    Name    = "${local.project}-${each.key}"
    Type    = "Private"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name    = "${local.project}-igw"
    Project = local.project
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  for_each   = var.public_subnets
  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name    = "${local.project}-nat_eip_${each.key}"
    Project = local.project
  }
}

# NAT Gateways (one per public subnet for high availability)
resource "aws_nat_gateway" "main" {
  for_each      = var.public_subnets
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name    = "${local.project}-nat_eip_${each.key}"
    Project = local.project
  }
}

# Public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${local.project}-public_rt"
    Project = local.project
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_rta" {
  for_each       = var.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  for_each = var.private_subnets
  vpc_id   = aws_vpc.principal.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[local.az_to_public_subnet[each.value.az_index]].id
  }

  tags = {
    Name    = "${local.project}-private-rt-${each.key}"
    Project = local.project
  }
}

resource "aws_route_table_association" "private_rta" {
  for_each       = var.private_subnets
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private_rt[each.key].id
}