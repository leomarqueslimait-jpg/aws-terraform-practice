resource "aws_instance" "ec2_instances" {
    subnet_id = aws_subnet.principal


}