# etcd Cluster

A production-ready etcd cluster setup with 3 nodes for high availability. This configuration follows the official [etcd container guide](https://etcd.io/docs/v3.6/op-guide/container/).

## Deployment Options

### 1. Deploy on Zeabur (Recommended for Production)

[![Deploy on Zeabur](https://zeabur.com/button.svg)](https://zeabur.com/templates)

Zeabur provides:
- Automatic scaling and load balancing
- Built-in monitoring and logging
- Zero-downtime deployments
- Automatic SSL/TLS certificates
- Managed storage and backups

### 2. Local Development with Docker Compose

For local testing and development, use Docker Compose.

## Architecture

This setup creates a 3-node etcd cluster for high availability and fault tolerance:
- **etcd1**: Node 1 (ports 2379, 2380)
- **etcd2**: Node 2 (ports 2389, 2390)
- **etcd3**: Node 3 (ports 2399, 2400)

Each node runs in its own container with persistent storage and communicates with other nodes via a dedicated Docker network.

## Quick Start

```bash
# Start the cluster
docker-compose up -d

# Verify all containers are running
docker-compose ps

# Check cluster health (etcdctl)
docker exec etcd1 etcdctl endpoint health --cluster

# Check readiness (HTTP endpoint, v3.4.29+)
curl http://localhost:2379/readyz

# Check liveness (HTTP endpoint, v3.4.29+)
curl http://localhost:2379/livez

# Verbose health check
curl http://localhost:2379/readyz?verbose

# Check cluster members
docker exec etcd1 etcdctl member list -w table

# Run comprehensive tests
./test.sh

# Stop the cluster
docker-compose down

# Stop and remove all data
docker-compose down -v
```

## Usage Examples

### Basic Operations

```bash
# Set a value
docker exec etcd1 etcdctl put mykey "Hello etcd"

# Get a value
docker exec etcd1 etcdctl get mykey

# Get all keys with prefix
docker exec etcd1 etcdctl get "" --prefix

# Delete a key
docker exec etcd1 etcdctl del mykey
```

### Cluster Operations

```bash
# Check endpoint status for all nodes
docker exec etcd1 etcdctl endpoint status --cluster -w table

# Check cluster health
docker exec etcd1 etcdctl endpoint health --cluster

# List all members
docker exec etcd1 etcdctl member list -w table

# Get cluster snapshot
docker exec etcd1 etcdctl snapshot save /etcd-data/snapshot.db
```

## Configuration

- **Image**: gcr.io/etcd-development/etcd:v3.6.0
- **Ports** (per node):
  - **2379**: Client API (gRPC/HTTP)
  - **2380**: Peer communication (cluster internal)
  - **2381**: Metrics and health checks
- **External Ports** (Docker Compose):
  - etcd1: 2379, 2380, 2381
  - etcd2: 2389, 2390, 2391
  - etcd3: 2399, 2400, 2401
- **Data Directory**: /etcd-data (persisted via Docker volumes)
- **Cluster Token**: etcd-cluster-1
- **Initial Cluster State**: new

See [PORTS.md](PORTS.md) for detailed port configuration and usage.

## Connecting to the Cluster

You can connect to any node using the client port:

```bash
# Connect to etcd1
etcdctl --endpoints=localhost:2379 put key1 value1

# Connect to etcd2
etcdctl --endpoints=localhost:2389 put key2 value2

# Connect to etcd3
etcdctl --endpoints=localhost:2399 put key3 value3

# Connect to all endpoints
etcdctl --endpoints=localhost:2379,localhost:2389,localhost:2399 get "" --prefix
```

## Features

- ✅ 3-node cluster for high availability
- ✅ Persistent data storage with Docker volumes
- ✅ Automatic restart on failure
- ✅ Dedicated network for cluster communication
- ✅ Health checks and monitoring support

## Troubleshooting

### View logs
```bash
docker-compose logs -f etcd1
docker-compose logs -f etcd2
docker-compose logs -f etcd3
```

### Restart a specific node
```bash
docker-compose restart etcd1
```

### Check if cluster is working
```bash
docker exec etcd1 etcdctl endpoint health --cluster
```

## Key Features

- **High Availability**: 3-node cluster with automatic failover
- **Data Persistence**: Each node has dedicated volume for data storage
- **Network Isolation**: Dedicated Docker network for cluster communication
- **Auto Recovery**: Containers automatically restart on failure
- **Official Image**: Uses gcr.io/etcd-development/etcd:v3.6.0
- **Advanced Health Checks**: `/readyz` and `/livez` endpoints (v3.4.29+)

## Important Notes

### For Development/Testing
- This configuration uses HTTP (not HTTPS) for simplicity
- Suitable for local development and testing environments
- All nodes run on the same Docker host

### For Production
Consider these enhancements:
- Enable TLS/SSL for secure communication
- Use host network mode (`--net=host`) for better performance
- Deploy nodes on separate physical/virtual machines
- Configure firewall rules for ports 2379 and 2380
- Set up monitoring and alerting
- Regular backup of cluster data using snapshots

### Network Considerations
- Uses Docker bridge network by default
- For cross-host clusters, consider overlay networks or host networking
- Ensure DNS resolution works between containers
- Advertise URLs should be accessible from all cluster members

## Test Suite

A comprehensive test script is included to verify cluster functionality in both local and remote environments.

### Local Testing (Docker Compose)

```bash
# Run all tests against local cluster
./test.sh
```

### Remote Testing (Zeabur/Production)

```bash
# Test remote cluster
ETCD_ENDPOINTS=https://etcd1.zeabur.app:2379,https://etcd2.zeabur.app:2379,https://etcd3.zeabur.app:2379 ./test.sh

# Test with authentication
ETCD_ENDPOINTS=https://etcd.example.com:2379 \
ETCD_USER=root \
ETCD_PASSWORD=secret \
./test.sh
```

### Test Coverage

The test suite includes 20 tests across 11 categories:
- **Connection & Health**: Container/connection status, cluster health, member list
- **Basic Operations**: PUT, GET, DELETE operations
- **Data Replication**: Write consistency and multi-read verification
- **Prefix Operations**: Prefix-based queries and deletion
- **Transactions**: Atomic multi-key operations
- **Lease Operations**: TTL-based key expiration
- **Watch Functionality**: Change notification capability
- **Endpoint Status**: Cluster-wide statistics
- **Performance**: Write throughput (100 keys)

All 20 tests should pass on a healthy cluster.

For detailed testing documentation, see [TESTING.md](TESTING.md).

## Backup and Restore

### Create Backup
```bash
# Create snapshot
docker exec etcd1 etcdctl snapshot save /etcd-data/backup.db

# Copy snapshot from container
docker cp etcd1:/etcd-data/backup.db ./backup.db

# Verify snapshot
docker exec etcd1 etcdctl snapshot status /etcd-data/backup.db -w table
```

### Restore from Backup
```bash
# Stop the cluster
docker-compose down -v

# Restore will be done on first start with the backup file
# Place backup.db in appropriate location before starting
docker-compose up -d
```

## Zeabur Deployment

### Prerequisites
- Zeabur account ([Sign up](https://zeabur.com))
- Access to Zeabur dashboard

### Deployment Steps

1. Click the "Deploy on Zeabur" button above
2. Select your project or create a new one
3. Wait for all 3 etcd nodes to be deployed
4. Access your cluster using the provided endpoints

### Zeabur Features

- **High Availability**: Automatic failover and recovery
- **Persistent Storage**: Data persisted across restarts
- **Service Discovery**: Internal DNS for service-to-service communication
- **Health Monitoring**: Automatic health checks and alerts
- **Scaling**: Easy horizontal scaling (odd numbers: 3, 5, 7)

### Connecting to Zeabur Cluster

```bash
# Use the provided endpoints from Zeabur dashboard
etcdctl --endpoints=<etcd1-endpoint>:2379,<etcd2-endpoint>:2379,<etcd3-endpoint>:2379 \
  endpoint health --cluster

# Put a value
etcdctl --endpoints=<etcd1-endpoint>:2379 put mykey "myvalue"

# Get a value
etcdctl --endpoints=<etcd1-endpoint>:2379 get mykey
```

## Additional Documentation

- [PORTS.md](PORTS.md) - Port configuration and usage guide
- [HEALTH_CHECKS.md](HEALTH_CHECKS.md) - Detailed health check endpoint documentation
- [TESTING.md](TESTING.md) - Comprehensive testing guide
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment strategies and best practices

## References

- [Official etcd Documentation](https://etcd.io/docs/v3.6/)
- [Running etcd in Containers](https://etcd.io/docs/v3.6/op-guide/container/)
- [etcd Configuration Guide](https://etcd.io/docs/v3.6/op-guide/configuration/)
- [etcd Health Check Endpoints](https://etcd.io/docs/v3.6/op-guide/monitoring/)
- [Zeabur Documentation](https://zeabur.com/docs)
