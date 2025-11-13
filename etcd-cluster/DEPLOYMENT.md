# Deployment Guide

This guide covers different ways to deploy the etcd cluster.

## Table of Contents

- [Zeabur Deployment (Recommended)](#zeabur-deployment)
- [Docker Compose (Local)](#docker-compose-local)
- [Kubernetes](#kubernetes)
- [Production Considerations](#production-considerations)

## Zeabur Deployment

### Quick Start

1. **Visit Zeabur Template Marketplace**
   - Go to [Zeabur Templates](https://zeabur.com/templates)
   - Search for "etcd Cluster"
   - Click "Deploy"

2. **Configure Deployment**
   - Select or create a project
   - Choose region
   - Review configuration
   - Click "Deploy"

3. **Access Cluster**
   - Wait for all 3 nodes to be healthy
   - Get endpoints from service details
   - Use etcdctl or HTTP API to interact

### Zeabur Architecture

```
┌─────────────────────────────────────┐
│         Zeabur Project              │
├─────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐        │
│  │  etcd1   │  │  etcd2   │        │
│  │  :2379   │  │  :2379   │        │
│  └────┬─────┘  └────┬─────┘        │
│       │             │               │
│       └─────┬───────┘               │
│             │                       │
│       ┌─────┴─────┐                │
│       │  etcd3    │                │
│       │  :2379    │                │
│       └───────────┘                │
└─────────────────────────────────────┘
```

### Advantages

- ✅ Automatic SSL/TLS
- ✅ Built-in monitoring
- ✅ Automatic backups
- ✅ One-click deployment
- ✅ Managed infrastructure
- ✅ Auto-scaling ready

## Docker Compose (Local)

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 2GB RAM minimum
- 10GB disk space

### Steps

```bash
# Clone repository
git clone https://github.com/your-username/zeabur-template.git
cd zeabur-template/etcd-cluster

# Start cluster
docker-compose up -d

# Verify health
docker exec etcd1 etcdctl endpoint health --cluster

# Run tests
./test.sh

# View logs
docker-compose logs -f

# Stop cluster
docker-compose down

# Remove all data
docker-compose down -v
```

### Ports

- `2379`: Client connections
- `2380`: Peer communication
- `2389`, `2399`: Additional client ports (etcd2, etcd3)

## Kubernetes

### Using Helm

```bash
# Add etcd-operator Helm repository
helm repo add stable https://charts.helm.sh/stable
helm repo update

# Install etcd cluster
helm install my-etcd stable/etcd-operator \
  --set cluster.size=3 \
  --set cluster.version=3.6.0

# Check status
kubectl get pods -l app=etcd
```

### Manual Deployment

```yaml
apiVersion: v1
kind: Service
metadata:
  name: etcd
spec:
  clusterIP: None
  ports:
  - port: 2379
    name: client
  - port: 2380
    name: peer
  selector:
    app: etcd
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: etcd
spec:
  serviceName: etcd
  replicas: 3
  selector:
    matchLabels:
      app: etcd
  template:
    metadata:
      labels:
        app: etcd
    spec:
      containers:
      - name: etcd
        image: gcr.io/etcd-development/etcd:v3.6.0
        ports:
        - containerPort: 2379
          name: client
        - containerPort: 2380
          name: peer
        volumeMounts:
        - name: data
          mountPath: /etcd-data
        command:
        - /usr/local/bin/etcd
        - --name=$(POD_NAME)
        - --data-dir=/etcd-data
        - --initial-cluster=etcd-0=http://etcd-0.etcd:2380,etcd-1=http://etcd-1.etcd:2380,etcd-2=http://etcd-2.etcd:2380
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
```

## Production Considerations

### Hardware Requirements

**Minimum per node:**
- 2 CPU cores
- 8GB RAM
- 50GB SSD storage
- 1Gbps network

**Recommended:**
- 4+ CPU cores
- 16GB+ RAM
- 100GB+ NVMe SSD
- 10Gbps network

### Security

1. **Enable TLS/SSL**
   ```bash
   etcd --cert-file=/path/to/server.crt \
        --key-file=/path/to/server.key \
        --client-cert-auth \
        --trusted-ca-file=/path/to/ca.crt
   ```

2. **Enable Authentication**
   ```bash
   etcdctl user add root
   etcdctl auth enable
   ```

3. **Firewall Rules**
   ```bash
   # Allow etcd client port
   ufw allow 2379/tcp

   # Allow etcd peer port (only from cluster nodes)
   ufw allow from <node-ip> to any port 2380
   ```

### Monitoring

1. **Health Check Endpoints (v3.4.29+)**
   ```bash
   # Readiness check (is node ready to serve traffic?)
   curl http://etcd1:2379/readyz

   # Liveness check (does node need a restart?)
   curl http://etcd1:2379/livez

   # Legacy health check
   curl http://etcd1:2379/health

   # Verbose output with detailed checks
   curl http://etcd1:2379/readyz?verbose
   ```

   See [HEALTH_CHECKS.md](HEALTH_CHECKS.md) for detailed documentation.

2. **Prometheus Metrics**
   ```yaml
   scrape_configs:
     - job_name: 'etcd'
       static_configs:
         - targets: ['etcd1:2379', 'etcd2:2379', 'etcd3:2379']
   ```

3. **Key Metrics to Monitor**
   - `etcd_server_has_leader`: Leader election status
   - `etcd_server_health_failures`: Failed health check count
   - `etcd_disk_backend_commit_duration_seconds`: Disk performance
   - `etcd_network_peer_round_trip_time_seconds`: Network latency
   - `etcd_mvcc_db_total_size_in_bytes`: Database size

### Backup Strategy

```bash
# Create snapshot
etcdctl snapshot save /backup/etcd-$(date +%Y%m%d-%H%M%S).db

# Verify snapshot
etcdctl snapshot status /backup/etcd-*.db

# Restore from snapshot
etcdctl snapshot restore /backup/etcd-backup.db \
  --data-dir=/new-data-dir
```

### Performance Tuning

1. **Disk I/O**
   - Use SSD storage
   - Separate WAL and data directories
   - Enable disk write cache

2. **Network**
   - Use dedicated network for peer communication
   - Enable jumbo frames if possible
   - Monitor network latency

3. **Memory**
   - Set appropriate cache size
   - Monitor memory usage
   - Use memory limits

## Troubleshooting

### Common Issues

1. **Split Brain**
   ```bash
   # Check cluster status
   etcdctl endpoint status --cluster

   # Force new cluster if needed
   etcd --force-new-cluster
   ```

2. **Performance Issues**
   ```bash
   # Check latency
   etcdctl check perf

   # Compact database
   etcdctl compact $(etcdctl endpoint status --write-out="json" | jq -r '.[] | .Status.header.revision')

   # Defragment
   etcdctl defrag --cluster
   ```

3. **Disk Space**
   ```bash
   # Check database size
   etcdctl endpoint status --cluster -w table

   # Set quota
   etcd --quota-backend-bytes=8589934592  # 8GB
   ```

## Support

- [etcd Documentation](https://etcd.io/docs/)
- [Zeabur Support](https://zeabur.com/docs)
- [GitHub Issues](https://github.com/etcd-io/etcd/issues)
