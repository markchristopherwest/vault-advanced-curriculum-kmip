# Vault Advanced Curriculum KMIP

This repo will spin up a Mongo Enterprise & Vault instance using docker compose.  Using init containers, setup Vault then Mongo including KMIP via TF.  

## Create Vault & MongoDB via Docker Compose

```bash

./run all
./run cleanup

```

## Create Vault & MongoDB via k8s

```bash

# Use MongoDB Developer GitHub to Configure Encryption via Python:

# https://github.com/mongodb-developer/mongodb-kmip-fle-queryable

# As a heads up, there is also a mongo provider for TF w/ encryption options:

# https://github.com/mongodb/terraform-provider-mongodbatlas

# To verify your install:

docker exec -it tools-mongo-1 /usr/bin/mongosh --eval "db.version()"

# To verify your version:

docker exec -it tools-mongo-1 /usr/bin/mongosh --eval "db.version()" | grep "Using Mongo"

# To verify your mongo init container logs:

docker logs tools-mongosetup-1

# To verify your mongo service container logs:

docker logs tools-mongo-1

# To verify your vault init container logs:

docker logs tools-vaultsetup-1

# To verify your vault service container logs:

docker logs tools-vault-1



```


