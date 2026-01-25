/*variable "subnet_count" {
  type    = number
  default = 2
}

/*variable "ec2_instance_count" {
  type    = number
  default = 1
}
*/
variable "subnet_config" {
  type    = map(object({
    cidr_block = string
  }))
  
}

variable "ec2_config_list" {
  type = list(object({
    instance_type = string
    ami           = string
  }))

  default = []

  validation {
    condition = alltrue([
    for config in var.ec2_config_list : contains(["t3.micro", "t3.small"], config.instance_type)])
    error_message = "Only t3.micro and t3.small are allowed"
  }

  validation {
    condition = alltrue([
    for config in var.ec2_config_list : contains(["ubuntu", "nginx"], config.ami)])
    error_message = "At least one of the ami values are not supported. Only ubuntu and nginx ami are allowed"
  }

}
variable "ec2_config_map" {
  type = map(object({
    instance_type = string
    ami           = string
    subnet_name  = optional(string, "default")
  }))
   validation {
    condition = alltrue([
    for key, config in (var.ec2_config_map) : contains(["t3.micro", "t3.small"], config.instance_type)])
    error_message = "Only t3.micro and t3.small are allowed"
  }

  validation {
    condition = alltrue([
    for config in values (var.ec2_config_map) : contains(["ubuntu", "nginx"], config.ami)])
    error_message = "At least one of the ami values are not supported. Only ubuntu and nginx ami are allowed"
  }
}
/*variable "ec2_config_map" {
  type = map(object({
    instance_type = string
    ami           = string
    subnet_index  = optional(number, 0)
  }))
   validation {
    condition = alltrue([
    for key, config in (var.ec2_config_map) : contains(["t3.micro", "t3.small"], config.instance_type)])
    error_message = "Only t3.micro and t3.small are allowed"
  }

  validation {
    condition = alltrue([
    for config in values (var.ec2_config_map) : contains(["ubuntu", "nginx"], config.ami)])
    error_message = "At least one of the ami values are not supported. Only ubuntu and nginx ami are allowed"
  }
}
*/
