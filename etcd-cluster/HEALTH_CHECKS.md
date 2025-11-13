# etcd Health Check Endpoints

This document explains the different health check endpoints available in etcd v3.6.0.

## Overview

etcd provides multiple health check endpoints for different purposes. Understanding which endpoint to use is crucial for proper monitoring and orchestration.

## Available Endpoints

### 1. `/readyz` (Recommended for Load Balancers)

**Since:** v3.4.29
**Purpose:** Check if the node is ready to serve client traffic
**Use Case:** Load balancer health checks, traffic routing decisions

```bash
# Basic check
curl http://etcd1:2379/readyz
# Response: ok (200 status) or error message (503 status)

# Verbose check
curl http://etcd1:2379/readyz?verbose
# Response:
# [+]data_corruption ok
# [+]serializable_read ok
# [+]linearizable_read ok
# ok
```

**Individual Checks:**
- `data_corruption` - Verifies database integrity
- `serializable_read` - Tests ability to perform serializable reads
- `linearizable_read` - Tests ability to perform linearizable reads

**When to Use:**
- ✅ Load balancer health checks
- ✅ Service mesh readiness probes
- ✅ Deciding whether to route traffic to the node
- ✅ Kubernetes readinessProbe

**Exclude specific checks:**
```bash
curl http://etcd1:2379/readyz?exclude=serializable_read
```

---

### 2. `/livez` (Recommended for Container Orchestration)

**Since:** v3.4.29
**Purpose:** Check if the process is alive and functioning
**Use Case:** Container restart decisions, process monitoring

```bash
# Basic check
curl http://etcd1:2379/livez
# Response: ok (200 status) or error message (503 status)

# Verbose check
curl http://etcd1:2379/livez?verbose
# Response:
# [+]serializable_read ok
# ok
```

**Individual Checks:**
- `serializable_read` - Basic ability to read data

**When to Use:**
- ✅ Kubernetes livenessProbe
- ✅ Container restart decisions
- ✅ Process monitoring
- ✅ Detecting if the process needs a restart

**Difference from `/readyz`:**
- `/livez` checks if the process is alive (less strict)
- `/readyz` checks if the node can serve traffic (more strict)
- A node might be "alive" but not "ready" (e.g., during startup or recovery)

---

### 3. `/health` (Legacy)

**Since:** v3.3.0
**Purpose:** General health status check
**Use Case:** Backward compatibility, simple monitoring

```bash
curl http://etcd1:2379/health
# Response: {"health":"true"}
```

**When to Use:**
- ⚠️ Legacy systems that expect `/health`
- ⚠️ Simple monitoring setups
- ℹ️ Prefer `/readyz` or `/livez` for new deployments

---

## Comparison Table

| Endpoint | Purpose | Checks | Response Format | Use Case |
|----------|---------|--------|-----------------|----------|
| `/readyz` | Ready for traffic? | data_corruption, serializable_read, linearizable_read | `ok` or error | Load balancers, traffic routing |
| `/livez` | Process alive? | serializable_read | `ok` or error | Container orchestration, restart decisions |
| `/health` | General health | Basic health | JSON | Legacy monitoring |

---

## Kubernetes Integration

### Recommended Configuration

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: etcd
spec:
  containers:
  - name: etcd
    image: gcr.io/etcd-development/etcd:v3.6.0
    ports:
    - containerPort: 2379
      name: client
    - containerPort: 2380
      name: peer
    livenessProbe:
      httpGet:
        path: /livez
        port: 2379
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /readyz
        port: 2379
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 5
      failureThreshold: 3
```

### Explanation

- **livenessProbe** → `/livez`: Restart the container if the process is dead
- **readinessProbe** → `/readyz`: Stop sending traffic if the node isn't ready

---

## Zeabur Configuration

In the Zeabur template, we use `/readyz` for the health check:

```yaml
healthCheck:
  type: HTTP
  port: client
  http:
    path: /readyz
```

**Why `/readyz`?**
- Ensures the node is ready to handle traffic before routing requests
- Provides comprehensive checks (data corruption, read capabilities)
- Aligns with Kubernetes best practices

---

## Response Codes

| Status Code | Meaning | Action |
|-------------|---------|--------|
| 200 | OK - Node is healthy | Continue routing traffic |
| 503 | Service Unavailable | Remove from load balancer pool |
| Other | Error | Investigate and possibly restart |

---

## Verbose Output Examples

### Healthy Node

```bash
$ curl http://etcd1:2379/readyz?verbose
[+]data_corruption ok
[+]serializable_read ok
[+]linearizable_read ok
ok
```

### Unhealthy Node (Data Corruption)

```bash
$ curl http://etcd1:2379/readyz?verbose
[-]data_corruption failed: database corruption detected
[+]serializable_read ok
[+]linearizable_read ok
fail
```

### Unhealthy Node (Not Ready During Startup)

```bash
$ curl http://etcd1:2379/readyz?verbose
[+]data_corruption ok
[-]serializable_read failed: etcdserver: no leader
[+]linearizable_read ok
fail
```

---

## Excluding Checks

You can exclude specific checks if needed:

```bash
# Exclude linearizable read check
curl http://etcd1:2379/readyz?exclude=linearizable_read

# Exclude multiple checks
curl http://etcd1:2379/readyz?exclude=linearizable_read,serializable_read
```

**Use Case:** During maintenance or testing when you want to keep the node in rotation but expect certain checks to fail.

---

## Metrics Integration

For comprehensive monitoring, combine health checks with metrics:

```bash
# Health check
curl http://etcd1:2379/readyz

# Prometheus metrics
curl http://etcd1:2379/metrics
```

**Key Metrics to Monitor:**
- `etcd_server_has_leader` - Whether the cluster has a leader
- `etcd_server_health_failures` - Number of failed health checks
- `etcd_disk_backend_commit_duration_seconds` - Disk performance
- `etcd_network_peer_round_trip_time_seconds` - Network latency

---

## Testing

### Manual Testing

```bash
# Test all health endpoints
curl http://etcd1:2379/livez
curl http://etcd1:2379/readyz
curl http://etcd1:2379/health

# Verbose output
curl http://etcd1:2379/readyz?verbose
curl http://etcd1:2379/livez?verbose
```

### Automated Testing

```bash
#!/bin/bash
# Test script for health checks

ETCD_ENDPOINT="http://etcd1:2379"

echo "Testing /livez..."
if curl -sf "$ETCD_ENDPOINT/livez" > /dev/null; then
    echo "✓ Liveness check passed"
else
    echo "✗ Liveness check failed"
fi

echo "Testing /readyz..."
if curl -sf "$ETCD_ENDPOINT/readyz" > /dev/null; then
    echo "✓ Readiness check passed"
else
    echo "✗ Readiness check failed"
fi

echo "Testing /readyz?verbose..."
curl "$ETCD_ENDPOINT/readyz?verbose"
```

---

## Best Practices

1. **Use `/readyz` for load balancers**: Ensures traffic only goes to ready nodes
2. **Use `/livez` for container orchestration**: Detects when a restart is needed
3. **Monitor both endpoints**: Different failure modes require different responses
4. **Set appropriate timeouts**: Health checks should be fast (< 5 seconds)
5. **Configure proper thresholds**: Allow for transient failures before taking action
6. **Use verbose mode for debugging**: Helps identify specific issues
7. **Monitor metrics alongside health checks**: Provides comprehensive visibility

---

## Troubleshooting

### Node Shows as Not Ready

```bash
# Check detailed status
curl http://etcd1:2379/readyz?verbose

# Common causes:
# - No leader elected yet (wait for cluster to stabilize)
# - Database corruption (restore from backup)
# - Disk I/O issues (check disk performance)
# - Network partition (verify network connectivity)
```

### Node Fails Liveness Check

```bash
# Check process status
docker ps | grep etcd

# Check logs
docker logs etcd1

# Common causes:
# - Process crashed (restart container)
# - Deadlock or hang (restart container)
# - Out of memory (increase memory limits)
```

### All Checks Pass But Still Having Issues

```bash
# Check metrics
curl http://etcd1:2379/metrics | grep etcd_server

# Check cluster status
etcdctl endpoint status --cluster -w table

# Check network latency
etcdctl check perf
```

---

## References

- [etcd Health Check Documentation](https://etcd.io/docs/v3.6/op-guide/monitoring/)
- [Kubernetes Enhancement Proposal (KEP)](https://github.com/kubernetes/enhancements/tree/master/keps/sig-api-machinery/1679-health-check-api)
- [etcd v3.4.29 Release Notes](https://github.com/etcd-io/etcd/releases/tag/v3.4.29)
- [Prometheus Monitoring](https://etcd.io/docs/v3.6/op-guide/monitoring/)
