

resource "aws_instance" "web_servers" {
  for_each               = aws_subnet.public
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.server_config.instance_type
  subnet_id              = each.value.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  root_block_device {
    volume_size = var.server_config.root_block_device.volume_size
    volume_type = var.server_config.root_block_device.volume_type

  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              echo "<h1>Web Server ${each.key}</h1>" > /var/www/html/index.html
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name    = "${local.project}-${each.key}"
    Project = local.project
  }
}

resource "aws_instance" "app_servers" {
  for_each               = aws_subnet.private
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.server_config.instance_type
  subnet_id              = each.value.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name    = "${local.project}-app-${each.key}"
    Project = local.project
    Type    = "AppServer"
  }
}
