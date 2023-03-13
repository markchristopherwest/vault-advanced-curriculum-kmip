#!/bin/bash

set -e

sleep 5


apt-get update
apt-get install -y jq wget gpg libcap2-bin

wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main" | tee /etc/apt/sources.list.d/hashicorp.list

apt-get update
apt-get install -y terraform vault

setcap cap_ipc_lock= /usr/bin/vault

which vault

# export VAULT_ROOT_TOKEN="root"
# export VAULT_TOKEN=$VAULT_ROOT_TOKEN
export VAULT_ADDR="http://host.docker.internal:8200"
export VAULT_SKIP_VERIFY=true
# vault login root

echo "Initializing Vault"
vault operator init > /sensitive/vault.txt
# cat /sensitive/vault.txt > /sensitive/vault.txt

echo "Sourcing Vault"
export VAULT_TOKEN=$(cat /sensitive/vault.txt | grep '^Initial' | awk '{print $4}')
export UNSEAL_1=$(cat /sensitive/vault.txt | grep '^Unseal Key 1' | awk '{print $4}')
export UNSEAL_2=$(cat /sensitive/vault.txt | grep '^Unseal Key 2' | awk '{print $4}')
export UNSEAL_3=$(cat /sensitive/vault.txt | grep '^Unseal Key 3' | awk '{print $4}')

echo "Unsealing Vault"
vault operator unseal $UNSEAL_1
vault operator unseal $UNSEAL_2
vault operator unseal $UNSEAL_3

# Handle Vault Login
export ROOT_TOKEN=${VAULT_TOKEN}
vault login ${ROOT_TOKEN}

# TF it
cd /terraform
terraform init
terraform apply -auto-approve

# Back to KMIP
cd /sensitive
vault write -format=json -f kmip/scope/my-service/role/admin/credential/generate > kmip.json
vault_kmip_ca_chain=$(cat kmip.json | jq -r '.data.ca_chain[]')
vault_kmip_certificate=$(cat kmip.json | jq -r '.data.certificate')
vault_kmip_private_key=$(cat kmip.json | jq -r '.data.private_key')
vault_kmip_serial_number=$(cat kmip.json | jq -r '.data.serial_number')

echo "vault_kmip_ca_chain: ${vault_kmip_ca_chain}"
echo "vault_kmip_certificate: ${vault_kmip_certificate}"
echo "vault_kmip_private_key: ${vault_kmip_private_key}"
echo "vault_kmip_serial_number: ${vault_kmip_serial_number}"

echo "Preparing certs for mongo..."
rm -rf /sensitive/*.pem
cat kmip.json | jq -r '.data.ca_chain[]' | tee ca.pem
cat kmip.json | jq -r '.data.certificate' | tee client.pem
