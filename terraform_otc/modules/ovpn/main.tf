variable "image_name" {}
variable "ssh_key_name" {}
variable "name" {}
variable "flavor_id" {}
variable "availability_zone" {}
variable "network_name" {}
variable "tags" {}
variable "network_id" {}
variable "ip" {}
variable "subnet_id" {}
variable "ovpn_port" {}
variable "ovpn_proto" {}

resource "opentelekomcloud_networking_secgroup_v2" "ovpn_sg" {
  name        = "${var.name}_sg"
  description = "Openvpn security group"
  #delete_default_rules = true
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "ovpn_sg_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.ovpn_sg.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "ovpn_sg_ovpn" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = var.ovpn_proto
  port_range_min    = var.ovpn_port
  port_range_max    = var.ovpn_port
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.ovpn_sg.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "ovpn_sg_group_in" {
  direction         = "ingress"
  protocol          = ""
  ethertype         = "IPv4"
  remote_group_id   = opentelekomcloud_networking_secgroup_v2.ovpn_sg.id
  security_group_id = opentelekomcloud_networking_secgroup_v2.ovpn_sg.id
  description       = "Allow all communication within ovpn_sg group on any port."
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "ovpn_sg_group_out" {
  direction         = "egress"
  protocol          = ""
  ethertype         = "IPv4"
  remote_group_id   = opentelekomcloud_networking_secgroup_v2.ovpn_sg.id
  security_group_id = opentelekomcloud_networking_secgroup_v2.ovpn_sg.id
  description       = "Allow all communication within ovpn_sg group on any port."
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "ovpn_sg_internet" {
  direction         = "egress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.ovpn_sg.id
  description       = "Allow all outgoing communication from the ovpn_sg group."
}

resource "opentelekomcloud_networking_port_v2" "port_1" {
  depends_on = [
    opentelekomcloud_networking_secgroup_v2.ovpn_sg,
    opentelekomcloud_networking_secgroup_rule_v2.ovpn_sg_group_in,
    opentelekomcloud_networking_secgroup_rule_v2.ovpn_sg_group_out,
    opentelekomcloud_networking_secgroup_rule_v2.ovpn_sg_internet,
    opentelekomcloud_networking_secgroup_rule_v2.ovpn_sg_ovpn,
    opentelekomcloud_networking_secgroup_rule_v2.ovpn_sg_ssh
  ]
  name                  = "${var.name}-port1"
  network_id            = var.network_id
  admin_state_up        = true
  port_security_enabled = true
  security_group_ids = [
    opentelekomcloud_networking_secgroup_v2.ovpn_sg.id
  ]
  allowed_address_pairs {
    ip_address = "1.1.1.1/0"
  }
  fixed_ip {
    subnet_id  = var.subnet_id
    ip_address = var.ip
  }
}

resource "opentelekomcloud_vpc_eip_v1" "ovpn_eip" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.name}-bandwidth"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
  tags = var.tags
}

data "opentelekomcloud_images_image_v2" "image" {
  name = var.image_name
}

resource "opentelekomcloud_compute_instance_v2" "ovpn" {
  depends_on = [
    opentelekomcloud_vpc_eip_v1.ovpn_eip,
    opentelekomcloud_networking_secgroup_v2.ovpn_sg,
    opentelekomcloud_networking_port_v2.port_1
  ]
  name              = var.name
  flavor_id         = var.flavor_id
  availability_zone = var.availability_zone
  key_pair          = var.ssh_key_name
  tags              = var.tags
  network {
    port = opentelekomcloud_networking_port_v2.port_1.id
  }
  block_device {
    boot_index            = 0
    delete_on_termination = true
    destination_type      = "volume"
    source_type           = "image"
    uuid                  = data.opentelekomcloud_images_image_v2.image.id
    volume_type           = "SSD"
    volume_size           = 20
  }
}

resource "opentelekomcloud_networking_floatingip_associate_v2" "ovpn_eip_association" {
  depends_on = [
    opentelekomcloud_vpc_eip_v1.ovpn_eip,
    opentelekomcloud_networking_secgroup_v2.ovpn_sg,
    opentelekomcloud_networking_port_v2.port_1,
    opentelekomcloud_compute_instance_v2.ovpn
  ]
  floating_ip = opentelekomcloud_vpc_eip_v1.ovpn_eip.publicip[0].ip_address
  port_id     = opentelekomcloud_networking_port_v2.port_1.id
}

output "ovpn_eip" {
  value = opentelekomcloud_vpc_eip_v1.ovpn_eip.publicip[0].ip_address
}
