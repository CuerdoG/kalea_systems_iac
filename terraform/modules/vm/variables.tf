variable "name" {}
variable "node_name" {}
variable "vm_id" {}
variable "template_id" {}

variable "cores" {}
variable "memory" {}
variable "disk_size" {}
variable "datastore" {}

variable "username" {}
variable "ssh_key" {}

variable "networks" {
  type = list(object({
    bridge  = string
    vlan_id = optional(number)
  }))
}

variable "ip_configs" {
  type = list(object({
    address = string
    gateway = optional(string)
  }))
}
