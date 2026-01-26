
variable "public_subnets" {
  type = map(object({
    cidr_block = string
    az_index   = number
    public     = bool
  }))
}

variable "server_config" {
  type = object({
    instance_type = string
    root_block_device = object({
      volume_size = number
      volume_type = string
    })

  })
}
