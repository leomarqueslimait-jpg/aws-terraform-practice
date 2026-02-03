variable "vpc_main" {
    type = object({
      cidr_block = string
      name = string
    })
}

variable "subnet_public" {
    type = map (object({
        
        az = string
    }))
}

variable "subnet_private" {
    type = map (object ({
        cidr_block = string
        az = string
    }))
}

