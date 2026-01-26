resource "aws_vpc" "principal" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = local.project
  }
}

resource "aws_subnet" "public" {
  for_each          = var.public_subnets
  cidr_block        = each.value.cidr_block
  vpc_id            = aws_vpc.principal.id
  availability_zone = data.aws_availability_zones.zones.names[each.value.az_index]
  tags = {
    Project = local.project
    Name    = "${local.project}-${each.key}"
  }
}

