provider "opentelekomcloud" {
  auth_url       = var.otc_auth
  security_token = var.ak_sk_security_token
  access_key     = var.otc_access_key
  secret_key     = var.otc_secret_key
  domain_name    = var.otc_domain
  tenant_name    = var.otc_project
}
