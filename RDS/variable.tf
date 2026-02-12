variable "subnet_rds" {
    type = map(object({
        cidr_block = string
        az_index = string
    
}))
}