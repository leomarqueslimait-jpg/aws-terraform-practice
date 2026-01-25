locals {
  ami_ids = {
    ubuntu = data.aws_ami.ubuntu.id
    nginx  = data.aws_ami.nginx.id
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "nginx" {
  most_recent = true


  filter {
    name   = "name"
    values = ["bitnami-nginx-1.28.1-r02-debian-12-amd64-f5774628-e459-457a-b058-3b513caefdee"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "from_count" {
  count         = var.ec2_instance_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.main[count.index % length(aws_subnet.main)].id

  tags = {
    Project = local.project
    Name    = "${local.project}-${count.index}"
  }
}

resource "aws_instance" "from_list" {
  count         = length(var.ec2_config_list)
  ami           = local.ami_ids[var.ec2_config_list[count.index].ami]
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.main[count.index % length(aws_subnet.main)].id

  tags = {
    Project = local.project
    Name    = "${local.project}-${count.index}"
  }
}

resource "aws_instance" "from_map" {
  for_each      = var.ec2_config_map
  ami           = local.ami_ids[each.value.ami]
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.main[each.value.subnet_index].id

  tags = {
    Project = local.project
    Name    = "${local.project}-${each.key}"
  }
}