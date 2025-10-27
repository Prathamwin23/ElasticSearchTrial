#!/bin/bash
set -e

CERT_DIR="/usr/share/elasticsearch/config/certs"
cd $CERT_DIR

# Generate CA private key
openssl genrsa -out ca-key.pem 4096

# Generate CA certificate
openssl req -new -x509 -sha256 -key ca-key.pem -out ca-cert.pem -days 3650 -subj "/C=US/ST=CA/L=SF/O=ElasticCluster/OU=Security/CN=ElasticCA"

# Generate node private key
openssl genrsa -out node-key.pem 4096

# Create certificate signing request
openssl req -new -key node-key.pem -out node.csr -subj "/C=US/ST=CA/L=SF/O=ElasticCluster/OU=Security/CN=elasticsearch-node"

# Create certificate extensions for SAN
cat > node-extensions.conf << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = elasticsearch-master
DNS.3 = elasticsearch-hot-1
DNS.4 = elasticsearch-hot-2
DNS.5 = elasticsearch-warm-1
DNS.6 = elasticsearch-warm-2
DNS.7 = *.elasticsearch-cluster
IP.1 = 127.0.0.1
IP.2 = 172.20.0.10
IP.3 = 172.20.0.11
IP.4 = 172.20.0.12
IP.5 = 172.20.0.13
IP.6 = 172.20.0.14
EOF

# Sign the certificate
openssl x509 -req -in node.csr -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out node-cert.pem -days 365 -extensions v3_req -extfile node-extensions.conf

# Generate HTTP certificate
openssl genrsa -out http-key.pem 4096
openssl req -new -key http-key.pem -out http.csr -subj "/C=US/ST=CA/L=SF/O=ElasticCluster/OU=Security/CN=elasticsearch-http"
openssl x509 -req -in http.csr -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out http-cert.pem -days 365 -extensions v3_req -extfile node-extensions.conf

# Clean up CSR files
rm node.csr http.csr node-extensions.conf

# Set permissions
chmod 600 *.pem
chown elasticsearch:elasticsearch *.pem

echo "Certificates generated successfully"