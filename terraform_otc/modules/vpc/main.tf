variable "vpc_cidr" {}
variable "vpc_name" {}
variable "vpc_subnet_cdr" {}
variable "vpc_subnet_name" {}
variable "vpc_subnet_gateway_ip" {}
variable "vpc_subnet_az" {}
variable "tags" {}

resource "opentelekomcloud_vpc_v1" "vpc" {
  name   = var.vpc_name
  cidr   = var.vpc_cidr
  tags   = var.tags
}

resource "opentelekomcloud_vpc_subnet_v1" "subnet" {
  name              = var.vpc_subnet_name
  cidr              = var.vpc_subnet_cdr
  vpc_id            = opentelekomcloud_vpc_v1.vpc.id
  gateway_ip        = var.vpc_subnet_gateway_ip
  dhcp_enable       = true
  primary_dns       = "100.125.4.25"
  secondary_dns     = "100.125.129.199"
  availability_zone = var.vpc_subnet_az
  tags              = var.tags
}

output "vpc_id" {
  value = opentelekomcloud_vpc_v1.vpc.id
}

output "subnet_id" {
  value = opentelekomcloud_vpc_subnet_v1.subnet.subnet_id
}

output "subnet_network_id" {
  value = opentelekomcloud_vpc_subnet_v1.subnet.id
}
