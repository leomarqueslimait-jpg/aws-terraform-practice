resource "aws_security" "web_sg" {
    vpc_id = aws_vpc.principal.vpc_id
    description = "Security group for web servers"
    name = "${local.project}-web_sg"

    ingress {
        description = "HTTPS from the internet"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_block = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH from my IP"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_block = var.allowed_ssh_cidr
    }

    egress {
        description = "Allow all outbound traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_block = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${local.project}-web_sg"
        project = local.project
    }
}