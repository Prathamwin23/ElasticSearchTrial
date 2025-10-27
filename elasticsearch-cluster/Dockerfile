# Elasticsearch 8.13 Custom Secure Cluster Image
FROM docker.elastic.co/elasticsearch/elasticsearch:8.13.0

# Switch to root for setup
USER root

# Install required tools for certificate generation
RUN yum update -y && \
    yum install -y openssl && \
    yum clean all

# Create directories for certificates and configuration
RUN mkdir -p /usr/share/elasticsearch/config/certs && \
    mkdir -p /usr/share/elasticsearch/config/cluster

# Generate CA and node certificates during build
COPY generate-certs.sh /tmp/generate-certs.sh
RUN chmod +x /tmp/generate-certs.sh && \
    /tmp/generate-certs.sh && \
    rm /tmp/generate-certs.sh

# Copy custom elasticsearch configuration
COPY elasticsearch.yml /usr/share/elasticsearch/config/elasticsearch.yml
COPY cluster-entrypoint.sh /usr/local/bin/cluster-entrypoint.sh

# Set proper permissions
RUN chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/config && \
    chmod +x /usr/local/bin/cluster-entrypoint.sh && \
    chmod 600 /usr/share/elasticsearch/config/certs/*

# Switch back to elasticsearch user
USER elasticsearch

# Expose ports
EXPOSE 9200 9300

ENTRYPOINT ["/usr/local/bin/cluster-entrypoint.sh"]
