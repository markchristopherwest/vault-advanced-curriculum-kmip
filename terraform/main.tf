terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "3.12.0"
    }
  }
}

provider "vault" {
  # Configuration options
  address = "http://127.0.0.1:8200"
  skip_tls_verify = true
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

locals {
  encryption_types = toset([
    "FLE",
    "QUERYABLE",
  ])
}

resource "vault_kmip_secret_backend" "default" {
  path        = "kmip"
  description = "Vault KMIP backend"
}

resource "vault_kmip_secret_scope" "mongodb" {
  path  = vault_kmip_secret_backend.default.path
  scope = "mongodb"
  force = true
}

resource "vault_kmip_secret_scope" "vmware" {
  path  = vault_kmip_secret_backend.default.path
  scope = "vmware"
  force = true
}

resource "vault_kmip_secret_scope" "my-service" {
  path  = vault_kmip_secret_backend.default.path
  scope = "my-service"
  force = true
}

resource "vault_kmip_secret_role" "mongodb_admin" {
  path                     = vault_kmip_secret_scope.mongodb.path
  scope                    = vault_kmip_secret_scope.mongodb.scope
  role                     = "admin"
  tls_client_key_type      = "rsa"
  tls_client_key_bits      = 2048
  operation_activate       = true
  operation_get            = true
  operation_get_attributes = true
  operation_create         = true
  operation_destroy        = true
}


resource "vault_kmip_secret_role" "vmware_admin" {
  path                     = vault_kmip_secret_scope.vmware.path
  scope                    = vault_kmip_secret_scope.vmware.scope
  role                     = "admin"
  tls_client_key_type      = "rsa"
  tls_client_key_bits      = 2048
  operation_activate       = true
  operation_get            = true
  operation_get_attributes = true
  operation_create         = true
  operation_destroy        = true
}


resource "vault_kmip_secret_role" "my-service" {
  path                     = vault_kmip_secret_scope.my-service.path
  scope                    = vault_kmip_secret_scope.my-service.scope
  role                     = "admin"
  tls_client_key_type      = "rsa"
  tls_client_key_bits      = 2048
  operation_all            = true
}
