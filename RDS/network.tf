resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Project = "My first RDS project"
        Name = "Main VPC"
    }
}

resource "aws_subnet" "private" {
    for_each = var.subnet_rds
    cidr_block = each.value.cidr_block
    vpc_id = aws_vpc.main.id
    availability_zone = each.value.az_index
    

    tags = {
        Project = "My first RDS project"
        Name = "RDS subnet ${each.key}"
    }

}

resource "aws_security_group" "rds_sg" {
    name = "rds_sg"
    description = "Allow database traffic"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    egress = {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/16"]
    }
}