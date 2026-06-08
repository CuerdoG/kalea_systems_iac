variable "pm_password" {
  description = "Password de Proxmox"
  sensitive   = true
}

variable "ad_password" {
   description = "password del usuario admin"
   sensitive = true
}
