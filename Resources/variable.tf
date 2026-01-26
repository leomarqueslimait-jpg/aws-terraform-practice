

variable "subnets" {
    type = map(object({
        cidr_block = string
        availability_zone = string
        public = bool
    }))
}

variable "server_config" {
    type = object({
      ami = 
    })
}