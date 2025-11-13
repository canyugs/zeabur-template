# Testing Guide

This guide explains how to test your etcd cluster in different environments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Local Testing (Docker Compose)](#local-testing-docker-compose)
- [Remote Testing (Zeabur/Production)](#remote-testing-zeaburproduction)
- [Test Coverage](#test-coverage)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### For Local Testing

- Docker 20.10+
- Docker Compose 2.0+
- Bash shell

### For Remote Testing

- etcdctl command-line tool
- Network access to etcd cluster
- (Optional) Authentication credentials

### Installing etcdctl

**macOS:**
```bash
brew install etcd
```

**Linux (Debian/Ubuntu):**
```bash
apt-get install etcd-client
```

**Linux (RHEL/CentOS):**
```bash
yum install etcd
```

**From source:**
```bash
ETCD_VER=v3.6.0
wget https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf etcd-${ETCD_VER}-linux-amd64.tar.gz
sudo mv etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/
```

## Local Testing (Docker Compose)

### Quick Start

```bash
# Start the cluster
docker-compose up -d

# Run tests
./test.sh

# View results
# Tests will output with colored status indicators:
# ✓ = Passed (green)
# ✗ = Failed (red)
# ℹ = Info (yellow)
```

### Expected Output

```
========================================
etcd Cluster Test Suite
========================================

Starting tests at Fri Nov 14 02:53:21 CST 2025

ℹ Running in LOCAL mode (Docker Compose)

========================================
Checking Container Status
========================================

✓ Container etcd1 is running
✓ Container etcd2 is running
✓ Container etcd3 is running

... (more tests)

========================================
Test Summary
========================================

Tests Passed: 20
Tests Failed: 0
Total Tests: 20

All tests passed! ✓
```

## Remote Testing (Zeabur/Production)

### Basic Remote Testing

Test a remote etcd cluster by specifying endpoints:

```bash
ETCD_ENDPOINTS=https://etcd1.zeabur.app:2379,https://etcd2.zeabur.app:2379,https://etcd3.zeabur.app:2379 ./test.sh
```

### With Authentication

If your cluster requires authentication:

```bash
ETCD_ENDPOINTS=https://etcd.example.com:2379 \
ETCD_USER=root \
ETCD_PASSWORD=secretpassword \
./test.sh
```

### Testing Zeabur Deployment

After deploying on Zeabur:

1. **Get Service URLs**
   - Go to Zeabur dashboard
   - Click on each etcd service
   - Copy the public domain or internal hostname

2. **Set Environment Variables**
   ```bash
   # Example with Zeabur domains
   export ETCD_ENDPOINTS="https://etcd1-abc123.zeabur.app:2379,https://etcd2-def456.zeabur.app:2379,https://etcd3-ghi789.zeabur.app:2379"
   ```

3. **Run Tests**
   ```bash
   ./test.sh
   ```

### Example: Testing Internal Services

For services within the same Zeabur project:

```bash
# Using internal hostnames
ETCD_ENDPOINTS=http://etcd1:2379,http://etcd2:2379,http://etcd3:2379 ./test.sh
```

## Test Coverage

The test suite includes 20 tests across 11 categories:

### 1. Connection & Health (3 tests)
- Container/connection status
- Cluster health check
- Member list verification

### 2. Basic Operations (4 tests)
- PUT operation
- GET operation
- DELETE operation
- Deletion verification

### 3. Data Replication (3 tests)
- Write to cluster
- Read consistency
- Multi-read verification

### 4. Prefix Operations (2 tests)
- Prefix-based queries
- Prefix-based deletion

### 5. Transactions (1 test)
- Atomic multi-key operations

### 6. Lease Operations (3 tests)
- Lease creation
- Key attachment to lease
- Automatic cleanup after lease revocation

### 7. Watch Functionality (1 test)
- Watch capability validation

### 8. Endpoint Status (1 test)
- Cluster-wide status check

### 9. Performance (1 test)
- Write throughput (100 keys)

## Environment Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `ETCD_ENDPOINTS` | No* | Comma-separated list of etcd endpoints | `http://etcd1:2379,http://etcd2:2379` |
| `ETCD_USER` | No | Username for authentication | `root` |
| `ETCD_PASSWORD` | No | Password for authentication | `secretpassword` |

\* Required for remote testing, optional for local testing

## Testing Modes

### Mode Detection

The script automatically detects the testing mode:

- **LOCAL mode**: No `ETCD_ENDPOINTS` set → Uses Docker Compose containers
- **REMOTE mode**: `ETCD_ENDPOINTS` is set → Uses etcdctl directly

### Mode-Specific Behavior

| Feature | Local Mode | Remote Mode |
|---------|-----------|-------------|
| Container check | ✓ Checks Docker containers | ✗ Skips, tests connection |
| Command execution | `docker exec etcd1 etcdctl` | `etcdctl --endpoints=...` |
| Authentication | Not required | Optional with `ETCD_USER`/`ETCD_PASSWORD` |

## Advanced Usage

### Testing Specific Endpoints

Test only one or two nodes:

```bash
# Single endpoint
ETCD_ENDPOINTS=https://etcd1.zeabur.app:2379 ./test.sh

# Two endpoints
ETCD_ENDPOINTS=https://etcd1.zeabur.app:2379,https://etcd2.zeabur.app:2379 ./test.sh
```

### Custom Port

If your etcd uses custom ports:

```bash
ETCD_ENDPOINTS=https://etcd.example.com:12379 ./test.sh
```

### Testing with TLS

For clusters with TLS enabled:

```bash
# Endpoints must use https://
ETCD_ENDPOINTS=https://secure-etcd1.com:2379,https://secure-etcd2.com:2379 ./test.sh

# With client certificates (modify test.sh to add --cert and --key flags)
# See: https://etcd.io/docs/v3.6/op-guide/security/
```

## Troubleshooting

### Common Issues

#### 1. "Failed to connect to remote etcd cluster"

**Symptoms:**
```
✗ Failed to connect to remote etcd cluster
ℹ Endpoints: https://etcd.example.com:2379
```

**Solutions:**
- Check if endpoints are reachable: `ping etcd.example.com`
- Verify ports are open: `telnet etcd.example.com 2379`
- Check if HTTPS is required: Try with `https://` prefix
- Verify firewall rules

#### 2. "Authentication required"

**Symptoms:**
```
Error: etcdserver: user name is empty
```

**Solution:**
```bash
ETCD_ENDPOINTS=... \
ETCD_USER=root \
ETCD_PASSWORD=yourpassword \
./test.sh
```

#### 3. "etcdctl: command not found" (Remote mode)

**Solution:**
Install etcdctl (see [Prerequisites](#prerequisites))

#### 4. Timeout errors

**Symptoms:**
```
context deadline exceeded
```

**Solutions:**
- Increase network timeout (modify test.sh)
- Check network latency: `ping etcd-host`
- Verify cluster is not overloaded

#### 5. Certificate errors (HTTPS)

**Symptoms:**
```
x509: certificate signed by unknown authority
```

**Solutions:**
- Ensure certificates are valid
- Add `--insecure-skip-tls-verify` flag (not recommended for production)
- Configure proper CA certificates

### Debug Mode

Enable verbose output:

```bash
# Add debug flag to etcdctl
# Edit test.sh and add --debug flag to etcd_exec functions
```

### Manual Testing

Test individual operations:

```bash
# Health check
etcdctl --endpoints=https://etcd1.zeabur.app:2379 endpoint health

# Put/Get
etcdctl --endpoints=https://etcd1.zeabur.app:2379 put testkey testvalue
etcdctl --endpoints=https://etcd1.zeabur.app:2379 get testkey

# Cluster status
etcdctl --endpoints=https://etcd1.zeabur.app:2379 endpoint status --cluster
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Test etcd Cluster

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Start etcd cluster
        run: docker-compose up -d

      - name: Wait for cluster
        run: sleep 10

      - name: Run tests
        run: ./test.sh

      - name: Cleanup
        run: docker-compose down -v
```

### Testing Zeabur Deployment in CI

```yaml
      - name: Test Zeabur deployment
        env:
          ETCD_ENDPOINTS: ${{ secrets.ETCD_ENDPOINTS }}
          ETCD_USER: ${{ secrets.ETCD_USER }}
          ETCD_PASSWORD: ${{ secrets.ETCD_PASSWORD }}
        run: ./test.sh
```

## Performance Benchmarking

For more detailed performance testing:

```bash
# Benchmark tool
etcdctl --endpoints=https://etcd.zeabur.app:2379 \
  check perf --load="s"

# Or use the official benchmark tool
# https://github.com/etcd-io/etcd/tree/main/tools/benchmark
```

## Further Reading

- [etcd Testing Guide](https://etcd.io/docs/v3.6/op-guide/recovery/)
- [etcdctl Command Reference](https://etcd.io/docs/v3.6/dev-guide/interacting_v3/)
- [Zeabur Documentation](https://zeabur.com/docs)
