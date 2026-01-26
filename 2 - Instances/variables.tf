
variable "public_subnets" {
  type = map(object({
    cidr_block = string
    az_index   = number
    public     = bool
  }))
}

variable "server_configs" {
    type = map(object({
        ami = string
        instance_type = string
        
    }))
}
