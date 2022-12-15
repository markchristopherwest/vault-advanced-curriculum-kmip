# Work with kmip secrets engine
path "kmip/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

# Enable secrets engine
path "sys/mounts/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

# List enabled secrets engine
path "sys/mounts" {
  capabilities = [ "read", "list" ]
}
