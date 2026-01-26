
variable "public_subnets" {
  type = map(object({
    cidr_block = string
    az_index   = number
    public     = bool
  }))
}

