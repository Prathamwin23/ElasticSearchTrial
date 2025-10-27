#!/bin/bash
set -e

echo "Building Elasticsearch Secure Cluster..."

# Build the custom image
docker build -t elasticsearch-secure-cluster:8.13 .

echo "Starting 5-node Elasticsearch cluster..."

# Start the cluster
docker-compose up -d

echo "Waiting for cluster to initialize..."
sleep 30

echo "Cluster started! Checking status..."

# Wait for master node to be ready
echo "Waiting for master node..."
until curl -k -u elastic:elastic https://localhost:9200/_cluster/health 2>/dev/null; do
    echo "Waiting for Elasticsearch master..."
    sleep 5
done

echo ""
echo "✅ Elasticsearch Secure Cluster is ready!"
echo ""
echo "🔐 Access URLs:"
echo "  Master Node: https://localhost:9200"
echo "  Username: elastic"
echo "  Password: elastic"
echo ""
echo "📊 Verification Commands:"
echo "  docker-compose ps"
echo "  curl -k -u elastic:elastic https://localhost:9200/_cluster/health?pretty"
echo "  curl -k -u elastic:elastic https://localhost:9200/_nodes?pretty"
echo "  curl -k -u elastic:elastic https://localhost:9200/_cat/nodes?v"
