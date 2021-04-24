variable "digitalocean_token" {
  type        = string
  sensitive   = true
  description = "A token for your DigitalOcean account."
}

variable "ssh_public_key" {
  type        = string
  description = "The public key you want to add to the Aether VM."
}

module "vm" {
  source = "./modules/vm"

  digitalocean_token = var.digitalocean_token
  ssh_public_key     = var.ssh_public_key
}

module "kubernetes" {
  source = "./modules/kubernetes"

  aether_ip = module.vm.aether_ip
}
