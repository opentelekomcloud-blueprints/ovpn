variable "ssh_key_name" {}
variable "ssh_public_key" {}

resource "opentelekomcloud_compute_keypair_v2" "mysshkey" {
  name       = var.ssh_key_name
  public_key = var.ssh_public_key
}

output "ssh_key_name" {
  value = opentelekomcloud_compute_keypair_v2.mysshkey.name
}