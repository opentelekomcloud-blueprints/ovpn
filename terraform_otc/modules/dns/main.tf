variable "tags" {}
variable "region" {}
variable "vpc_id" {}
variable "domain" {}
variable "hostname" {}
variable "host_ip" {}
variable "email" {}

resource "opentelekomcloud_dns_zone_v2" "local_domain" {
  name        = "${var.domain}."
  email       = var.email
  description = "Openvpn local domain ${var.domain}"
  ttl         = 3000
  type        = "private"
  router {
    router_id     = var.vpc_id
    router_region = var.region
  }
  tags = var.tags
}

resource "opentelekomcloud_dns_recordset_v2" "local_fqdn" {
  zone_id     = opentelekomcloud_dns_zone_v2.local_domain.id
  name        = "${var.hostname}.${var.domain}."
  description = "Openvpn local fqdn"
  ttl         = 3000
  type        = "A"
  records     = ["${var.host_ip}"]
  tags        = var.tags
}
