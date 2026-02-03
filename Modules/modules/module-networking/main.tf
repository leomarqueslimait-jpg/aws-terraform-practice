resource "aws_vpc" "main" {
    cidr_block = var.vpc_main.cidr_block

    tags = {
        Name = var.vpc_main.name
    }

}

resource "aws_subnet" "private" {
    for_each = var.subnet_private
    cidr_block = each.key.cidr_block
    availability_zone = each.value.az
    vpc_id = aws_vpc.main.id

    tags = {
        Name = each.key
    }
}

resource "aws_subnet" "public" { 
    for_each = var.subnet_public
    availability_zone = each.value.az
    vpc_id = aws_vpc.main

    tags = {
        Name = each.key
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    count = length(var.subnet_public) > 0 ? 1 : 0
}

resource "aws_route_table" "public_rtb" {
    vpc_id = aws_vpc.main.id
    count = length(var.subnet_public) > 0 ? 1: 0

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw[0].id
    }
}
#create nat gateway
resource "aws_nat_gateway" "ngw" {
    allocation_id =
    subnet_id = aws.subnet_public
} 