terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "3.10.0"
    }
  }
}

provider "vault" {
  # Configuration options
  address = "http://127.0.0.1:8200"
  skip_tls_verify = true
  token = "hvs.nlqKigaigbIrq9ewwJE4X4DY"
}

data "vault_policy_document" "kmip" {
  rule {
    path         = "kmip/*"
    capabilities = ["create", "read", "update", "delete", "list"]
    description  = "Work with kmip secrets engine"
  }
  rule {
    path         = "sys/mounts/*"
    capabilities = ["create", "read", "update", "delete", "list"]
    description  = "Enable secrets engine"
  }
  rule {
    path         = "sys/mounts"
    capabilities = [ "read", "list"]
    description  = "List enabled secrets engine"
  }
}

resource "vault_policy" "kmip" {
  name   = "kmip_policy"
  policy = data.vault_policy_document.kmip.hcl
}

resource "vault_kmip_secret_backend" "default" {
  path        = "kmip"
  description = "Vault KMIP backend"
}

resource "vault_kmip_secret_scope" "dev" {
  path  = vault_kmip_secret_backend.default.path
  scope = "dev"
  force = true
}

resource "vault_kmip_secret_role" "admin" {
  path                     = vault_kmip_secret_scope.dev.path
  scope                    = vault_kmip_secret_scope.dev.scope
  role                     = "admin"
  tls_client_key_type      = "ec"
  tls_client_key_bits      = 256
  operation_activate       = true
  operation_get            = true
  operation_get_attributes = true
  operation_create         = true
  operation_destroy        = true
}