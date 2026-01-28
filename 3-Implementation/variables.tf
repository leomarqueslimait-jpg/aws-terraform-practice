
variable "public_subnets" {
  type = map(object({
    cidr_block = string
    az_index   = number
    public     = bool
  }))

  validation {
    condition = alltrue([
      for subnet in var.public_subnets :
      can(cidrhost(subnet.cidr_block, 0))
    ])
    error_message = "All CIDR blocks must be a valid IPV4 CIDR notation."
  }
}

variable "server_config" {
  type = object({
    instance_type = string

    root_block_device = object({
      volume_size = number
      volume_type = string
    })
  })
  validation {
    condition     = var.server_config.root_block_device.volume_size >= 10 && var.server_config.root_block_device.volume_size <= 100
    error_message = "Volume size needs to be between 10 and 100 GB."
  }

  validation {
    condition     = contains(["gp3", "io2", "io3"], var.server_config.root_block_device.volume_type)
    error_message = "Volume type must be gp3, io2 or io3"
  }

  validation {
    condition     = contains(["t3.micro", "t3.small", "c7i-flex.large"], var.server_config.instance_type)
    error_message = "Volume type must be t3.micro, t3.small and c7i-flex.large"
  }


}

variable "private_subnets" {
  type = map(object({
    cidr_block = string
    az_index   = number
    public     = string
  }))

  validation {
    condition = alltrue([
      for subnet in var.private_subnets :
      can(cidrhost(subnet.cidr_block, 0))
    ])
    error_message = "All CIDR blocks must be a valid IPV4 CIDR notation."
  }
}

variable "allowed_ssh_cidr" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH to instances"
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.allowed_ssh_cidr : can(cidrhost(cidr, 0))
    ])
    error_message = "All SSH CIDR blocks must be valid IPv4 CIDR notation."
  }
}