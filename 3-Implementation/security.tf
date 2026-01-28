resource "aws_security_group" "web_sg" {
  vpc_id      = aws_vpc.principal.id
  description = "Security group for web servers"
  name        = "${local.project}-web_sg"

  ingress {
    description = "HTTPS from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks  = var.allowed_ssh_cidr
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${local.project}-web_sg"
    project = local.project
  }
}

resource "aws_security_group" "app_sg" {
  vpc_id      = aws_vpc.principal.id
  description = "Security Group for Application"
  name        = "${local.project}-app_sg"

  ingress {
    description = "Traffic from web servers"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${local.project}-alb-sg"
    Project = local.project
  }
}
    