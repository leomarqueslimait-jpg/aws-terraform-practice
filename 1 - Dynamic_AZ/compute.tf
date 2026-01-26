

resource "aws_instance" "web_servers" {
  count = 3
  ami = local.ami_id
  instance_type = var.server_config.instance_type
    

}