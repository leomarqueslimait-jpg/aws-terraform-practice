resource "aws_db_subnet_group" "rds_subnet" {
    name = "rds-subnet-group"
    subnet_ids = [for subnet in aws_subnet.private : subnet.id]
}

resource "aws_db_subnet_group" "rds_subnet" {
    
}