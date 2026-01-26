

resource "aws_instance" "web_servers" {
  for_each      = aws_subnet.public
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.server_config.instance_type
  subnet_id = each.value.id
  root_block_device {
    volume_size = var.server_config.root_block_device.volume_size
    volume_type = var.server_config.root_block_device.volume_type
    
  }
  tags = {
    Name    = "${local.project}-${each.key}"
    Project = local.project
  }
}
