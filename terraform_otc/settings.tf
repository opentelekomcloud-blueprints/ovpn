terraform {
  required_version = "v1.5.7"
  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = ">=1.36.31"
    }
  }
#  backend "s3" {
#    bucket                      = "<BUCKET NAME>"
#    kms_key_id                  = "arn:aws:kms:<REGION>:<IAM User ID>:key/<KMS ID>"  # the KMS key must be in the main project of the tenant, and not in a sub project!
#    key                         = "<Some Path>/<Project Name>/terraform.tfstate"  # make sure the path to the file exists
#    region                      = "<REGION>"  # OBS Region
#    endpoint                    = "obs.eu-de.otc.t-systems.com"  # adjust to your REGION
#    encrypt                     = true
#    skip_region_validation      = true
#    skip_credentials_validation = true
#  }
}
