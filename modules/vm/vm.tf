terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.8.0"
    }
  }
}

// We need this SSH key pair to SSH into
// the machine we create here

module "ssh_key_pair" {
  source  = "cloudposse/ssh-key-pair/tls"
  version = "0.6.0"

  ssh_public_key_path = "./.temp/ssh_keys"
  name                = "terraform"
}

// Variables

variable "digitalocean_token" {
  type      = string
  sensitive = true
}

variable "ssh_public_key" {
  type = string
}

// Provider configuration

provider "digitalocean" {
  token = var.digitalocean_token
}

// DigitalOcean resources

resource "digitalocean_ssh_key" "default" {
  name       = "SSH key"
  public_key = var.ssh_public_key
}

resource "digitalocean_ssh_key" "terraform" {
  name       = "SSH key"
  public_key = module.ssh_key_pair.public_key
}

resource "digitalocean_floating_ip" "aether" {
  droplet_id = digitalocean_droplet.aether.id
  region     = digitalocean_droplet.aether.region
}

resource "digitalocean_droplet" "aether" {
  name   = "aether"
  image  = "ubuntu-20-04-x64"
  size   = "s-1vcpu-1gb"
  region = "ams3"

  ssh_keys = [
    digitalocean_ssh_key.default.fingerprint,
    digitalocean_ssh_key.terraform.fingerprint
  ]

  user_data = file("init.cfg")

  backups     = true
  monitoring  = true
  resize_disk = false

  provisioner "local-exec" {
    command = "sh ./scripts/initialize-k3s.sh ${self.ipv4_address}"
  }
}

resource "digitalocean_project" "aether" {
  name        = "Aether"
  environment = "Production"

  resources = [
    digitalocean_floating_ip.aether.urn,
    digitalocean_droplet.aether.urn
  ]
}

output "aether_ip" {
  value = digitalocean_droplet.aether.ipv4_address
}
