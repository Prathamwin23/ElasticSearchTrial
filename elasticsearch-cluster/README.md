# Elasticsearch 8.13 Secure Multi-Node Cluster

## Architecture Overview

**5-Node Cluster Configuration:**
- 1 Master Node (elasticsearch-master) - Master + Hot Data + Ingest
- 2 Hot Data Nodes (elasticsearch-hot-1, elasticsearch-hot-2) - Hot Data + Ingest
- 2 Warm Data Nodes (elasticsearch-warm-1, elasticsearch-warm-2) - Warm Data

## Security Features

✅ **TLS Encryption**: Transport and HTTP layers encrypted  
✅ **Baked-in Certificates**: Generated during Docker build  
✅ **No Host Mounts**: All security inside containers  
✅ **Auto-Clustering**: Nodes discover each other automatically  
✅ **Role-Based Access**: Different node roles via ENV variables  

## Quick Start

```bash
# Make scripts executable
chmod +x *.sh

# Build and start cluster
./build-and-run.sh

# Verify cluster health
./verify-cluster.sh
```

## Manual Commands

```bash
# Build image
docker build -t elasticsearch-secure-cluster:8.13 .

# Start cluster
docker-compose up -d

# Check status
docker-compose ps
```

## Access Information

- **URL**: https://localhost:9200
- **Username**: elastic
- **Password**: elastic
- **TLS**: Self-signed certificates (use -k with curl)

## Verification Commands

```bash
# Cluster health
curl -k -u elastic:elastic https://localhost:9200/_cluster/health?pretty

# Node information
curl -k -u elastic:elastic https://localhost:9200/_cat/nodes?v

# Security info
curl -k -u elastic:elastic https://localhost:9200/_xpack/security/_authenticate?pretty
```

## Node Role Mapping

| Container | Role | IP | Heap | Purpose |
|-----------|------|----|----- |---------|
| elasticsearch-master | master | 172.20.0.10 | 2g | Cluster coordination + Hot data |
| elasticsearch-hot-1 | hot | 172.20.0.11 | 2g | Recent/active data |
| elasticsearch-hot-2 | hot | 172.20.0.12 | 2g | Recent/active data |
| elasticsearch-warm-1 | warm | 172.20.0.13 | 1g | Older/less accessed data |
| elasticsearch-warm-2 | warm | 172.20.0.14 | 1g | Older/less accessed data |

## Internal TLS Communication

- **Transport Layer**: Node-to-node communication encrypted with mutual TLS
- **HTTP Layer**: Client connections encrypted with TLS
- **Certificate Authority**: Self-signed CA generated during build
- **SAN Coverage**: All container names and IPs included

## Cluster Formation Process

1. Master node starts first and initializes cluster
2. Data nodes connect to master using discovery.seed_hosts
3. TLS handshake validates certificates
4. Nodes join cluster based on their configured roles
5. Cluster reaches green status when all nodes are connected