# Vault Advanced Curriculum KMIP

## Create Vault & MongoDB via Docker Compose

```bash

./run all
./run cleanup

```

## Create Vault & MongoDB via k8s

```bash

minikube start
minikube status
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm search repo hashicorp/vault
cp ~/Downloads/vault.hclic /tmp/
kubectl create secret generic vault-hclic --from-file=license=/tmp/vault.hclic
kubectl describe secret vault-hclic 
# SERVICE is the name of the Vault service in Kubernetes.
# It does not have to match the actual running service, though it may help for consistency.
export SERVICE=vault-server-tls

# NAMESPACE where the Vault service is running.
export NAMESPACE=vault-namespace

# SECRET_NAME to create in the Kubernetes secrets store.
export SECRET_NAME=vault-server-tls

# TMPDIR is a temporary working directory.
export TMPDIR=/tmp

# CSR_NAME will be the name of our certificate signing request as seen by Kubernetes.
export CSR_NAME=vault-csr

openssl genrsa -out ${TMPDIR}/vault.key 2048

cat <<EOF >${TMPDIR}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${SERVICE}
DNS.2 = ${SERVICE}.${NAMESPACE}
DNS.3 = ${SERVICE}.${NAMESPACE}.svc
DNS.4 = ${SERVICE}.${NAMESPACE}.svc.cluster.local
IP.1 = 127.0.0.1
EOF

openssl req -new -key ${TMPDIR}/vault.key \
    -subj "/O=system:nodes/CN=system:node:${SERVICE}.${NAMESPACE}.svc" \
    -out ${TMPDIR}/server.csr \
    -config ${TMPDIR}/csr.conf

cat <<EOF >${TMPDIR}/csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  groups:
  - system:authenticated
  request: $(cat ${TMPDIR}/server.csr | base64 | tr -d '\r\n')
  signerName: kubernetes.io/kubelet-serving
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

kubectl create -f ${TMPDIR}/csr.yaml

kubectl certificate approve ${CSR_NAME}

kubectl get csr ${CSR_NAME}

serverCert=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')

echo "${serverCert}" | openssl base64 -d -A -out ${TMPDIR}/vault.crt

kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > ${TMPDIR}/vault.ca

kubectl create namespace ${NAMESPACE}

kubectl create secret generic ${SECRET_NAME} \
    --namespace ${NAMESPACE} \
    --from-file=vault.key=${TMPDIR}/vault.key \
    --from-file=vault.crt=${TMPDIR}/vault.crt \
    --from-file=vault.ca=${TMPDIR}/vault.ca

# secret/vault-server-tls created






```

Explore the other containers such as Cassandra and Mysql (default passwords are set via env vars in the docker-compose.yml file).