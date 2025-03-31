#
# OpenVPN server offering a encrypted connection for save Internet connection
# - SSH key: only public key is pushed to OTC, assuming private key is known to operator
# - VPC: small, somewhat exotic RFC1918 IP range to prevent likelihood of collision with most LANs
# - ECS Linux with static local IP + EIP
# - Ansible:
#   install/configure OpenVPN and other required packages
#   manage OVPN clients (create/revoke)
#

module "keypair" {
  source         = "./modules/keypair"
  ssh_key_name   = var.SSH_KEY_NAME
  ssh_public_key = var.SSH_PUBLIC_KEY
}

module "vpc" {
  source                = "./modules/vpc"
  vpc_cidr              = var.VPC_CIDR
  vpc_name              = var.VPC_NAME
  vpc_subnet_cdr        = var.VPC_SUBNET_CDR
  vpc_subnet_name       = var.VPC_SUBNET_NAME
  vpc_subnet_gateway_ip = var.VPC_SUBNET_GATEWAY_IP
  vpc_subnet_az         = var.AVAILABILITY_ZONE
  tags                  = var.TAGS
}

module "ovpn" {
  source            = "./modules/ovpn"
  name              = var.OPENVPN_HOSTNAME
  flavor_id         = local.ecs_ovpn_flavor_id
  image_name        = local.ecs_ovpn_image_name
  availability_zone = var.AVAILABILITY_ZONE
  ssh_key_name      = var.SSH_KEY_NAME
  network_name      = module.vpc.vpc_id
  network_id        = module.vpc.subnet_network_id
  subnet_id         = module.vpc.subnet_id
  tags              = var.TAGS
  ip                = var.OPENVPN_IP
  depends_on        = [module.vpc, module.keypair]
  ovpn_port         = var.OPENVPN_PORT
  ovpn_proto        = var.OPENVPN_PROTO
}

module "dns" {
  source   = "./modules/dns"
  tags     = var.TAGS
  region   = var.REGION
  vpc_id   = module.vpc.vpc_id
  domain   = var.PRV_DOMAIN
  hostname = var.OPENVPN_HOSTNAME
  host_ip  = var.OPENVPN_IP
  email    = var.DNS_EMAIL
}

resource "local_file" "ovpn_host_eip" {
  filename        = "../otc-backend.ovpn_host_eip"
  file_permission = "0644"
  content         = module.ovpn.ovpn_eip
}

resource "local_file" "ansible_inventory" {
  filename        = "../otc-backend.ansible_inventory"
  file_permission = "0644"
  content         = <<EOF
[vpnserver]
${module.ovpn.ovpn_eip}

[vpnserver:vars]
ansible_user=ubuntu
tf_platform=${var.PLATFORM}
tf_hostname=${var.OPENVPN_HOSTNAME}
tf_prv_domain=${var.PRV_DOMAIN}
tf_region=${var.REGION}
tf_public_ip=${module.ovpn.ovpn_eip}
tf_local_ip=${var.OPENVPN_IP}
tf_ovpn_port=${var.OPENVPN_PORT}
tf_subnet_cidr=${var.VPC_SUBNET_CDR}
tf_subnet_network=${var.VPC_SUBNET_NETWORK}
tf_subnet_netmask=${var.VPC_SUBNET_NETMASK}
tf_openvpn_network=${var.OPENVPN_NETWORK}
tf_openvpn_netmask=${var.OPENVPN_NETMASK}
tf_openvpn_cidr=${var.OPENVPN_CIDR}
tf_vpn_pub_fqdn=${var.OPENVPN_FQDN}
tf_openvpn_proto=${var.OPENVPN_PROTO}
tf_openvpn_dev=${var.OPENVPN_DEV}
tf_openvpn_nic=${var.OPENVPN_NIC}
tf_openvpn_dns=${var.OPENVPN_DNS}
tf_openvpn_cipher=${var.OPENVPN_CIPHER}
tf_easy_rsa_key_country=${var.EASY_RSA_KEY_COUNTRY}
tf_easy_rsa_key_province=${var.EASY_RSA_KEY_PROVINCE}
tf_easy_rsa_key_city=${var.EASY_RSA_KEY_CITY}
tf_easy_rsa_key_org=${var.EASY_RSA_KEY_ORG}
tf_easy_rsa_key_email=${var.EASY_RSA_KEY_EMAIL}
tf_easy_rsa_key_ou=${var.EASY_RSA_KEY_OU}
tf_easy_rsa_key_size=${var.EASY_RSA_KEY_SIZE}
tf_easy_rsa_ca_expire=${var.EASY_RSA_CA_EXPIRE}
tf_easy_rsa_key_expire=${var.EASY_RSA_KEY_EXPIRE}
tf_easy_rsa_crl_expire=${var.EASY_RSA_KEY_EXPIRE}
EOF
}
