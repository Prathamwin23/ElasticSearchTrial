#!/bin/bash
set -e

# Default values
NODE_ROLE=${NODE_ROLE:-"master"}
NODE_NAME=${NODE_NAME:-"elasticsearch-node"}
HEAP_SIZE=${HEAP_SIZE:-"1g"}

echo "Starting Elasticsearch node: $NODE_NAME with role: $NODE_ROLE"

# Set JVM heap size
export ES_JAVA_OPTS="-Xms${HEAP_SIZE} -Xmx${HEAP_SIZE}"

# Create keystores from PEM certificates
CERT_DIR="/usr/share/elasticsearch/config/certs"
KEYSTORE_PASSWORD="elastic-cluster-password"

# Create transport keystore
if [ ! -f "$CERT_DIR/transport.p12" ]; then
    echo "Creating transport keystore..."
    openssl pkcs12 -export \
        -in "$CERT_DIR/node-cert.pem" \
        -inkey "$CERT_DIR/node-key.pem" \
        -certfile "$CERT_DIR/ca-cert.pem" \
        -out "$CERT_DIR/transport.p12" \
        -passout pass:$KEYSTORE_PASSWORD
fi

# Create HTTP keystore
if [ ! -f "$CERT_DIR/http.p12" ]; then
    echo "Creating HTTP keystore..."
    openssl pkcs12 -export \
        -in "$CERT_DIR/http-cert.pem" \
        -inkey "$CERT_DIR/http-key.pem" \
        -certfile "$CERT_DIR/ca-cert.pem" \
        -out "$CERT_DIR/http.p12" \
        -passout pass:$KEYSTORE_PASSWORD
fi

# Configure keystore passwords
echo "$KEYSTORE_PASSWORD" | /usr/share/elasticsearch/bin/elasticsearch-keystore add -x 'xpack.security.transport.ssl.keystore.secure_password' --stdin || true
echo "$KEYSTORE_PASSWORD" | /usr/share/elasticsearch/bin/elasticsearch-keystore add -x 'xpack.security.transport.ssl.truststore.secure_password' --stdin || true
echo "$KEYSTORE_PASSWORD" | /usr/share/elasticsearch/bin/elasticsearch-keystore add -x 'xpack.security.http.ssl.keystore.secure_password' --stdin || true
echo "$KEYSTORE_PASSWORD" | /usr/share/elasticsearch/bin/elasticsearch-keystore add -x 'xpack.security.http.ssl.truststore.secure_password' --stdin || true

# Set built-in user passwords
echo "elastic" | /usr/share/elasticsearch/bin/elasticsearch-keystore add -x 'bootstrap.password' --stdin || true

# Configure node-specific settings
CONFIG_FILE="/usr/share/elasticsearch/config/elasticsearch.yml"

# Add node-specific configuration
cat >> $CONFIG_FILE << EOF

# Node-specific configuration
node.name: $NODE_NAME
EOF

# Configure node roles based on NODE_ROLE
case $NODE_ROLE in
    "master")
        cat >> $CONFIG_FILE << EOF
node.roles: [ master, data_content, data_hot, ingest ]
node.attr.data: hot
EOF
        ;;
    "hot")
        cat >> $CONFIG_FILE << EOF
node.roles: [ data_hot, data_content, ingest ]
node.attr.data: hot
EOF
        ;;
    "warm")
        cat >> $CONFIG_FILE << EOF
node.roles: [ data_warm, data_content ]
node.attr.data: warm
EOF
        ;;
    "cold")
        cat >> $CONFIG_FILE << EOF
node.roles: [ data_cold, data_content ]
node.attr.data: cold
EOF
        ;;
    *)
        echo "Unknown node role: $NODE_ROLE"
        exit 1
        ;;
esac

echo "Node configuration completed for role: $NODE_ROLE"
echo "Starting Elasticsearch..."

# Start Elasticsearch
exec /usr/local/bin/docker-entrypoint.sh eswrapper
