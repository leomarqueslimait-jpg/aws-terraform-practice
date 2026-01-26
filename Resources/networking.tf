resource "aws_vpc" "principal" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = locals.project
    }
}

resource "aws_subnet" "public" {
    cidr_block = "10.0.0.0/24"
    vpc_id = aws_vpc.principal

    tags = {
        Project = local.project
        Name = "Principal"
    }
}

resource "aws_subnet" "private" {
    c
}