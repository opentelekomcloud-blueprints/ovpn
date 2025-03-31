variable "PLATFORM" {}
variable "REGION" {}
variable "AVAILABILITY_ZONE" {}
variable "DNS_EMAIL" {}
variable "SSH_KEY_NAME" {}
variable "SSH_PUBLIC_KEY" {}
variable "VPC_CIDR" {}
variable "VPC_NAME" {}
variable "VPC_SUBNET_CDR" {}
variable "VPC_SUBNET_NETWORK" {}
variable "VPC_SUBNET_NETMASK" {}
variable "VPC_SUBNET_NAME" {}
variable "VPC_SUBNET_GATEWAY_IP" {}
variable "OPENVPN_HOSTNAME" {}
variable "OPENVPN_IP" {}
variable "OPENVPN_PORT" {}
variable "OPENVPN_NETWORK" {}
variable "OPENVPN_NETMASK" {}
variable "OPENVPN_CIDR" {}
variable "PRV_DOMAIN" {}
variable "TAGS" { type = map(string) }
variable "OPENVPN_FQDN" {}
variable "OPENVPN_PROTO" {}
variable "OPENVPN_DEV" {}
variable "OPENVPN_NIC" {}
variable "OPENVPN_DNS" {}
variable "OPENVPN_CIPHER" {}
variable "EASY_RSA_KEY_COUNTRY" {}
variable "EASY_RSA_KEY_PROVINCE" {}
variable "EASY_RSA_KEY_CITY" {}
variable "EASY_RSA_KEY_ORG" {}
variable "EASY_RSA_KEY_EMAIL" {}
variable "EASY_RSA_KEY_OU" {}
variable "EASY_RSA_KEY_SIZE" {}
variable "EASY_RSA_CA_EXPIRE" {}
variable "EASY_RSA_KEY_EXPIRE" {}
variable "EASY_RSA_CRL_EXPIRE" {}

locals {
  ecs_ovpn_image_name = "Standard_Ubuntu_22.04_latest"
  ecs_ovpn_flavor_id  = "s3.medium.1"
}

variable "otc_auth" {
  description = "OTC Authentication URL"
  type        = string
  sensitive   = true
  default     = "https://iam.eu-de.otc.t-systems.com/v3"
}

variable "ak_sk_security_token" {
  description = "Temporary Token (otc-auth)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "otc_domain" {
  description = "OTC Domain"
  type        = string
  sensitive   = true
}

variable "otc_project" {
  description = "OTC Project"
  type        = string
  sensitive   = true
}

variable "otc_access_key" {
  description = "OTC Access Key"
  type        = string
  sensitive   = true
}

variable "otc_secret_key" {
  description = "OTC Secret Key"
  type        = string
  sensitive   = true
}
