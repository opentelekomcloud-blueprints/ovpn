# Setup and Maintain Point-to-Site VPN Connections between Development Machines and a VPC using Terraform and Ansible

## Description

Engineers access sites from almost anywhere, thus being called road warriors. In order to make sure, access is as secure as possible, VPNs are a good choice. The goal of this project is to deliver an easy way to setup, configure and manage an [OpenVPN](https://openvpn.net/) Server and its users. The OpenVPN Server will push a default route to its clients to make sure all traffic is routed through the VPN.

***Please be aware that all traffic that will be routed through the VPN creates additional costs!***

The current Terraform code:
- creates a VPC and Subnet 
- creates an ECS (Ubuntu Linux box)
- creates security groups for incoming traffic on tcp/22 (SSH) and udp/1194 (OpenVPN)
- creates a private DNS domain

The current Ansible code:
- installs and configures OpenVPN
- installs and configures EasyRSA
- setups local firewall (ufw)
- maintains users
  - creating/revoking user certificates
  - creating OpenVPN client configurations
  - packaging OpenVPN client configurations and certificates in ZIP archives ready to deliver to the users
  - offers backup/restore capability for the OpenVPN users, RSA setup, and OpenVPN Server configuration


## Requirements

- a Linux box, git
- SSH key (private and public)
- otc-auth >=2.2.1 [https://github.com/iits-consulting/otc-auth](https://github.com/iits-consulting/otc-auth)
- Terraform Version v1.5.7 (Open Telekom CLoud Provider >= v1.36.31)
  - Install Terraform: [https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) 
  - or use tfenv instead: [https://github.com/tfutils/tfenv](https://github.com/tfutils/tfenv)
- Ansible >= 10.7.0 (ansible-core >= 2.17.8)
  - [https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

### Create SSH key

If you don't have a SSH key yet, create one.

```
ssh-keygen -t rsa -C "user@example.com" -b 4096 -f ~/.ssh/ssh-private-key
chmod 600 ~/.ssh/ssh-private-key
```

### Install Terraform

You can use [tfenv](https://github.com/tfutils/tfenv) project to maintain your Terraform installation, or refer to the Terraform Website on [howto install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

```bash
git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH=$PATH:$HOME/.tfenv/bin' >> ~/.bashrc
export PATH=$PATH:$HOME/.tfenv/bin
tfenv install 1.5.7
```

### Authentication with otc-auth

Example on how to install otc-auth:

```bash
mkdir otc-auth
cd otc-auth
curl -OL https://github.com/iits-consulting/otc-auth/releases/download/v2.2.4/otc-auth-2.2.4-1-x86_64.pkg.tar.zst
tar -xfz otc-auth-2.2.4-1-x86_64.pkg.tar.zst
export PATH=$PATH:$HOME/otc-auth/usr/bin/
echo 'export PATH=$PATH:$HOME/otc-auth/usr/bin/' >> ~/.bashrc
otc-auth --version
```

### Terraform state file in OBS

Ignore this topic if you want to have a local state file.

It is recommended to use an OBS S3 Bucket to store your Terraform state file. You can follow this [guide](https://community.open-telekom-cloud.com/community?id=community_blog&sys_id=40959a3113985810d15a246ea67441c4&view_source=searchResult) in our Community Portal on how to create an OBS bucket. After that, edit and adjust **terraform_otc/settings.tf** accordingly.

### Install Ansible

You can refer to the Ansible Website on [howto install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html), or try following these quick steps:

```bash
python3 -m pip install --upgrade pip
pip install --upgrade ansible==10.7.0
```

## Install/Maintain your OpenVPN infrastructure with Terraform on your OTC environment

Initially you need to clone [https://github.com/opentelekomcloud-blueprints/ovpn.git](https://github.com/opentelekomcloud-blueprints/ovpn.git) (or fork and clone depending on your needs):

```bash
git clone --branch main --single-branch https://github.com/opentelekomcloud-blueprints/ovpn.git
cd ovpn
```

and provide the necessary configuration values:

1. The main configuration is done in a JSON file, use the template **./config.json**, e.g. copy it to a new file like `cp config.json otc-backend.config.json` before editing.
2. Place your SSH public key string in the variable `SSH_PUBLIC_KEY`.
3. Make sure the VPC/Subnet IP network does not have any overlapping with existing VPCs/Subnets you'd like to create a peering with, or with the usual private networks used by your users.

### Create a temporary token

Create a file on your system, or in the root of this repository, e.g. named **otc-backend.auth** with the following content:

```bash
export ENV_OTC_DOMAIN="OTCxxxxxxxxxxxxxxxxxxxxxx"
export ENV_OTC_DOMAIN_ID="*** a.k.a. Account ID ***"
export ENV_OTC_REGION="e.g. eu-de"
export ENV_OTC_PROJECT_NAME="e.g. eu-de_MyProjectName"
export ENV_OTC_PROJECT_ID="***"
export ENV_OTC_USERNAME="IAM username"
export ENV_OTC_PASSWORD="IAM password"
export ENV_OTC_AUTH_URL="https://iam.eu-de.otc.t-systems.com/v3"
```

Please make sure that the credentials are not accessed by unauthorized people.

The token will be valid 4h. You can change that value in `get_token.sh`

```bash
source ./otc-backend.auth
source ./get_token.sh
```

### Initialize Terraform

```bash
terraform -chdir=./terraform_otc init
```

### Plan and Apply

```bash
terraform -chdir=./terraform_otc plan -var-file=../otc-backend.config.json
terraform -chdir=./terraform_otc apply -var-file=../otc-backend.config.json
```

### Login to the ECS Linux box

You can login using SSH if necessary.

```bash
ssh -i ~/.ssh/ssh-private-key ubuntu@$(cat otc-backend.ovpn_host_eip)
```

### Destroy, CAUTION! This will remove everything!

```bash
terraform -chdir=./terraform_otc destroy -var-file=../otc-backend.config.json
```


## Install OpenVPN Server

- The Ansible playbook was tested with Ansible 10.7.0 (ansible-core 2.17.8)
- You may need to install `community.general` using the command ```ansible-galaxy collection install community.general```
- Make sure you have your SSH private key accessible, e.g. `... --private-key ~/.ssh/ssh-private-key ...`

### Initial install / configuration

- Please login to the OpenVPN host and reboot after the initial installation!
- Please change the password for the default user ubuntu (and store that safely)! E.g. ```sudo passwd ubuntu```
- Please create a reminder to run this step again on regular basis to apply any security updates available at the time!

```bash
ansible-playbook -i otc-backend.ansible_inventory ansible/openvpn.yml \
 --private-key ~/.ssh/ssh-private-key \
 -t base_configuration
```

### Install / Configure Easy-RSA, Openvpn, and the setup the firewall

```bash
ansible-playbook -i otc-backend.ansible_inventory ansible/openvpn.yml \
 --private-key ~/.ssh/ssh-private-key \
 -t easy-rsa,openvpn,firewall
```

### Check Status

This task will always run. 

```bash
ansible-playbook -i otc-backend.ansible_inventory ansible/openvpn.yml \
 --private-key ~/.ssh/ssh-private-key
```

## User Management

### Create users

Create users, and/or download ZIP archive(s) with user configuration(s). 
Pass archives to the users. 

- Users are listed in the file `./ansible/vars/main.yml` in the variable `vpn_users`.
- Make sure Users are not listed twice, or also listed in the variable `vpn_users_to_revoke`!
- ZIP archive will be downloaded to `../otc-backend.vpns/`
- If Users already exist, only the ZIP archive will be downloaded


```yaml
...
vpn_users:
  - user1
  - user2
...
```

```bash
ansible-playbook -i otc-backend.ansible_inventory ansible/openvpn.yml \
 --private-key ~/.ssh/ssh-private-key \
 -t create_users
```

You can also overwrite the variable `vpn_users` during a `create_users` call, in order to speed up, when you already have a lot of users. 
But please make sure putting every user into `./ansible/vars/main.yml:vpn_users` as well in order to keep track of your users.

```bash
ansible-playbook -i otc-backend.ansible_inventory ansible/openvpn.yml \
 --private-key ~/.ssh/ssh-private-key \
 -t create_users \
 --extra-vars "vpn_users=USERNAME"
```

or a couple of users:

```bash
ansible-playbook -i otc-backend.ansible_inventory ansible/openvpn.yml \
 --private-key ~/.ssh/ssh-private-key \
 -t create_users \
 --extra-vars='{"vpn_users": [USER1,USER2,USER3]}'
```

### Revoke users

- Revoked Users are listed in the file `./ansible/vars/main.yml` in the variable `vpn_users_to_revoke`.
- Make sure Revoked Users are not listed twice, or also listed in the variable `vpn_users`!

```yaml
...
vpn_users_to_revoke:
  - user3
  - user4
...
```

```bash
ansible-playbook -i otc-backend.ansible_inventory ansible/openvpn.yml \
 --private-key ~/.ssh/ssh-private-key \
 -t revoke_users
```

### Check EasyRSA Index

Check the EasyRSA Index, in order to compare and track users being created, or revoked.

```bash
ansible-playbook -i otc-backend.ansible_inventory ansible/openvpn.yml \
 --private-key ~/.ssh/ssh-private-key \
 -t easyrsa_index
```

## Managing OpenVPN Server Backups

### Creating a Backup

This Ansible Playbook will create a backup (tgz archive) of the `/etc/openvpn` directory and it will stored it in `HOME/ovpn_backup/ovpn<iso8601_basic>.tgz` and locally under `otc-backend.backups/ovpn.<iso8601_basic>.tgz`.

```bash
ansible-playbook -i otc-backend.ansible_inventory ansible/openvpn.yml \
 --private-key ~/.ssh/ssh-private-key \
 -t backup
```

### Restoring from a Backup

- This Ansible Playbook will upload a backup archive to the OpenVPN server `HOME/ovpn_restore` and restore `/etc/openvpn` directory.
- A fresh Backup will be created prior restore.
- Files will be overwritten, but files not existing in the archive will remain in the destination directory untouched (no prior purge).
- You will be prompted to confirm before the restore will start.
- You will have to enter the local path to the backup archive that should be used to restore, e.g. `... --extra-vars backup=/path/to/otc-backend.backups/ovpn.<iso8601_basic>.tgz`.
- The OpenVPN service will be restarted after restore.

```bash
ansible-playbook -i otc-backend.ansible_inventory ansible/openvpn.yml \
 --private-key ~/.ssh/ssh-private-key \
 -t restore \
 --extra-vars backup=/path/to/otc-backend.backups/ovpn.<iso8601_basic>.tgz
```

