# PostgreSQL High Availability Cluster

High availability PostgreSQL cluster with Patroni and etcd. Provides automatic failover and replication for production-grade database deployments.

## Architecture

This template deploys a complete HA PostgreSQL cluster:

- **3x etcd nodes**: Distributed consensus and configuration storage
- **3x Patroni/PostgreSQL nodes**: Database nodes with automatic failover
- **Built-in replication**: Synchronous and asynchronous replication support
- **Health monitoring**: REST API and health checks on all nodes

## Quick Start

1. Deploy the `PostgreSQL HA` template from Zeabur marketplace
2. Wait for all 6 services to become healthy (3 etcd + 3 Patroni)
3. Use connection details from any Patroni node's Instructions tab
4. Patroni automatically routes connections to the master node

## Connection Information

Connect to the cluster using any Patroni node:

- **Host**: Use hostname of `patroni1`, `patroni2`, or `patroni3`
- **Port**: 5432
- **Superuser**: `postgres` / (see password in dashboard)
- **Admin User**: `admin` / (see password in dashboard)

### User Accounts

| Account | Username | Privileges | Use Case |
|---------|----------|------------|----------|
| **Superuser** | `postgres` | Full system privileges, bypass all permission checks | System administration, backup/restore, emergency maintenance |
| **Admin** | `admin` | `CREATEDB`, `CREATEROLE` privileges | Application connections, daily development, creating databases and users |

> **Security Recommendation**: Use `admin` or create dedicated users for applications. Avoid using `superuser` directly, as it grants full database control and poses security risks if compromised.

Connection string format:
```
postgresql://postgres:PASSWORD@patroni1:5432/postgres
```

Patroni will automatically route writes to the master node and can distribute reads to replicas.

## Cluster Management

### Scaling the Cluster

The 3-node configuration provides standard production HA (tolerates 1 node failure). You can scale to 5 nodes for higher availability (tolerates 2 node failures).

#### Why Add Nodes?

- **Higher availability**: 5-node cluster tolerates 2 simultaneous failures
- **Read scaling**: More replicas for read-only queries
- **Geographic distribution**: Spread nodes across different regions/zones
- **Replace failed nodes**: Add new nodes to maintain cluster size

#### Cluster Size Recommendations

| Nodes | Fault Tolerance | Quorum | Use Case |
|-------|----------------|--------|----------|
| 1     | 0 failures     | 1/1    | ❌ Development only |
| 2     | 0 failures     | 2/2    | ❌ Never use (worse than 1) |
| 3     | 1 failure      | 2/3    | ✅ Production (standard) |
| 4     | 1 failure      | 3/4    | ❌ Expensive, same tolerance as 3 |
| 5     | 2 failures     | 3/5    | ✅ Production (high availability) |

⚠️ **Important**: Always use odd numbers for cluster sizes (1, 3, 5). Even numbers don't improve fault tolerance.

## Adding Nodes to the Cluster

### Overview

To scale from 3 to 5 nodes, you need to:
1. Add 2 more etcd nodes (for consensus)
2. Update existing Patroni nodes with new etcd endpoints
3. Add 2 more Patroni nodes (for database replication)

### Quick Method: Use Dedicated Templates

Use these pre-configured templates for easy scaling:

| Step | Template | URL |
|------|----------|-----|
| 1 | etcd4 | https://zeabur.com/templates/X877ER |
| 2 | etcd5 | https://zeabur.com/templates/DYGT7Y |
| 3 | Patroni4 | https://zeabur.com/templates/3ZC549 |
| 4 | Patroni5 | https://zeabur.com/templates/LNFEJI |

### Step 1: Add etcd4

1. Register node in cluster (use etcd instruction panel or run externally):
   ```bash
   curl -X POST http://etcd1:2379/v3/cluster/member/add -d '{"peerURLs":["http://etcd4:2380"]}'
   ```

2. Deploy [**etcd4**](https://zeabur.com/templates/X877ER) template

3. Verify:
   ```bash
   curl -X POST http://etcd1:2379/v3/cluster/member/list
   ```

### Step 2: Add etcd5

1. Register node in cluster:
   ```bash
   curl -X POST http://etcd1:2379/v3/cluster/member/add -d '{"peerURLs":["http://etcd5:2380"]}'
   ```

2. Deploy [**etcd5**](https://zeabur.com/templates/DYGT7Y) template

3. Verify:
   ```bash
   curl -X POST http://etcd1:2379/v3/cluster/member/list
   ```

### Step 3: Update Existing Patroni Nodes

Update `ETCD3_HOSTS` in all existing Patroni services (patroni1, patroni2, patroni3):

```
ETCD3_HOSTS=etcd1:2379,etcd2:2379,etcd3:2379,etcd4:2379,etcd5:2379
```

Restart each Patroni service one by one (wait for healthy before next).

### Step 4: Add Patroni4

1. Deploy [**Patroni4**](https://zeabur.com/templates/3ZC549) template
2. Enter:
   - Same passwords as existing cluster
   - ETCD3_HOSTS: `etcd1:2379,etcd2:2379,etcd3:2379,etcd4:2379,etcd5:2379`

3. Verify (run inside any patroni container):
   ```bash
   patronictl list pg-ha
   ```

### Step 5: Add Patroni5

1. Deploy [**Patroni5**](https://zeabur.com/templates/LNFEJI) template
2. Enter:
   - Same passwords as existing cluster
   - ETCD3_HOSTS: `etcd1:2379,etcd2:2379,etcd3:2379,etcd4:2379,etcd5:2379`

3. Verify (run inside any patroni container):
   ```bash
   patronictl list pg-ha
   ```

### Step 6: Verify Complete Cluster

```bash
# Check etcd cluster (use instruction panel or external)
curl -X POST http://etcd1:2379/v3/cluster/member/list

# Check Patroni cluster (run inside any patroni container)
patronictl list pg-ha

# Check PostgreSQL replication (run inside any patroni container)
psql -U postgres -c "SELECT * FROM pg_stat_replication;"
```

You should see:
- 5 healthy etcd members
- 5 Patroni nodes (1 leader, 4 replicas)
- 4 replication connections in PostgreSQL

## Removing Nodes from the Cluster

### Important Considerations

⚠️ **Before removing nodes:**
- Never reduce etcd cluster below 3 nodes in production
- Never reduce Patroni cluster below 3 nodes for HA
- Always maintain odd number of nodes
- Ensure cluster is healthy before removing nodes
- Take backup before major changes

### Step 1: Remove Patroni Node

#### 1.1 Identify Node to Remove

Only remove **replica nodes**, never the leader:

```bash
# Run inside any patroni container to check cluster status
patronictl list pg-ha
```

The output shows which node is `Leader` and which are `Replica`. Choose a replica node to remove (e.g., patroni5).

#### 1.2 Remove the Patroni Service

1. In Zeabur dashboard, find the Patroni service to remove
2. Stop the service
3. Delete the service

The remaining Patroni nodes will automatically detect the removal via etcd.

#### 1.3 Verify Patroni Cluster

```bash
# Run inside any patroni container
patronictl list pg-ha
```

You should see the removed node is no longer in the cluster.

### Step 2: Remove etcd Node

#### 2.1 Get Member ID

**Using HTTP API:**
```bash
curl -X POST http://etcd1:2379/v3/cluster/member/list
```

**Using etcdctl:**
```bash
etcdctl --endpoints=http://etcd1:2379 member list

# Example output:
# 8e9e05c52164694d, started, etcd1, http://etcd1:2380, http://etcd1:2379, false
# 91bc3c398fb3c146, started, etcd2, http://etcd2:2380, http://etcd2:2379, false
# fd422379fda50e48, started, etcd3, http://etcd3:2380, http://etcd3:2379, false
# a1b2c3d4e5f67890, started, etcd4, http://etcd4:2380, http://etcd4:2379, false
# 1234567890abcdef, started, etcd5, http://etcd5:2380, http://etcd5:2379, false
```

#### 2.2 Remove Member from Cluster

**Using HTTP API:**
```bash
# Remove etcd5 using its member ID
curl -X POST http://etcd1:2379/v3/cluster/member/remove \
  -d '{"ID":"1234567890abcdef"}'
```

**Using etcdctl:**
```bash
etcdctl --endpoints=http://etcd1:2379 member remove 1234567890abcdef
```

#### 2.3 Delete the etcd Service

1. In Zeabur dashboard, find the etcd service to remove
2. Stop the service
3. Delete the service

#### 2.4 Verify etcd Cluster

**Using HTTP API:**
```bash
curl http://etcd1:2379/health
curl -X POST http://etcd1:2379/v3/cluster/member/list
```

**Using etcdctl:**
```bash
etcdctl --endpoints=http://etcd1:2379 endpoint health
etcdctl --endpoints=http://etcd1:2379 member list
```

### Step 3: Update Patroni Configuration (Optional)

If you want to update Patroni nodes to remove references to deleted etcd nodes:

1. Go to each remaining Patroni service
2. Update environment variable:

```
ETCD3_HOSTS=etcd1:2379,etcd2:2379,etcd3:2379,etcd4:2379
ETCD_HOSTS=etcd1:2379,etcd2:2379,etcd3:2379,etcd4:2379
```

3. Restart Patroni services one by one

**Note**: This step is optional. Patroni will automatically handle unreachable etcd nodes, but cleaning up the configuration is cleaner.

## Troubleshooting

### etcd Issues

**Problem**: etcd node won't join cluster

**Solutions**:
- Verify `ETCD_INITIAL_CLUSTER_STATE` is set to `existing`
- Ensure `ETCD_INITIAL_CLUSTER` includes all members (including this new one)
- Check cluster token matches
- Verify network connectivity to existing nodes
- Check logs for specific errors

**Problem**: etcd cluster loses quorum

**Solutions**:
- Ensure majority of nodes are running (2/3 or 3/5)
- Check network connectivity between nodes
- Review logs for split-brain conditions
- If unrecoverable, may need to restore from backup

### Patroni Issues

**Problem**: New Patroni node won't join cluster

**Solutions**:
- Verify passwords match existing cluster exactly
- Check `SCOPE` matches existing cluster (e.g., `pg-ha`)
- Ensure `ETCD_HOSTS` points to accessible etcd nodes
- Verify etcd cluster is healthy first
- Check Patroni logs for specific errors

**Problem**: Replication lag is high

**Solutions**:
- Check network bandwidth between nodes
- Review PostgreSQL `max_wal_senders` and `wal_keep_size` settings
- Monitor disk I/O on replica nodes
- Consider using asynchronous replication for some replicas

**Problem**: Automatic failover not working

**Solutions**:
- Verify etcd cluster has quorum
- Check Patroni can reach etcd
- Review Patroni TTL settings
- Ensure network connectivity between all nodes

### Health Checks

Use these commands to diagnose issues:

**etcd Health (using HTTP API):**
```bash
# Check etcd cluster health
curl http://etcd1:2379/health

# Check etcd cluster members
curl -X POST http://etcd1:2379/v3/cluster/member/list
```

**etcd Health (using etcdctl):**
```bash
etcdctl --endpoints=http://etcd1:2379 endpoint health
etcdctl --endpoints=http://etcd1:2379 member list
```

**Patroni & PostgreSQL (run inside any patroni container):**
```bash
# Check Patroni cluster status
patronictl list pg-ha

# Show cluster configuration
patronictl show-config pg-ha

# Check PostgreSQL replication
psql -U postgres -c "SELECT * FROM pg_stat_replication;"
psql -U postgres -c "SELECT * FROM pg_stat_wal_receiver;"
```

## Backup and Recovery

### Backup Strategies

1. **PostgreSQL logical backup** (pg_dump):
   ```bash
   pg_dump -U postgres -h patroni1 -d mydatabase > backup.sql
   ```

2. **PostgreSQL physical backup** (pg_basebackup):
   ```bash
   pg_basebackup -U postgres -h patroni1 -D /backup -Ft -z -P
   ```

3. **etcd backup**:
   ```bash
   etcdctl snapshot save snapshot.db
   ```

### Recovery Procedures

Recovery procedures depend on the failure scenario:

- **Single node failure**: Cluster automatically handles via failover
- **Majority nodes failed**: May need to restore from backup
- **Data corruption**: Restore from PostgreSQL backup
- **Complete cluster loss**: Rebuild cluster and restore data

Always test backup and recovery procedures in a non-production environment first.

## Performance Tuning

### PostgreSQL Settings

Key settings for HA cluster (adjust based on workload):

```sql
-- Replication settings
max_wal_senders = 10
wal_keep_size = 1GB
max_replication_slots = 10

-- Performance settings
shared_buffers = 25% of RAM
effective_cache_size = 75% of RAM
maintenance_work_mem = 1GB
checkpoint_completion_target = 0.9
```

### etcd Settings

For larger clusters, consider tuning:

```bash
# Heartbeat interval (default 100ms)
ETCD_HEARTBEAT_INTERVAL=100

# Election timeout (default 1000ms)
ETCD_ELECTION_TIMEOUT=1000

# Snapshot count (default 100000)
ETCD_SNAPSHOT_COUNT=100000
```

## Security Considerations

### Network Security

- Use Zeabur's built-in network isolation
- Only expose necessary ports via public domains
- Use SSL/TLS for client connections (configure in Patroni)
- Enable etcd authentication for production (requires additional configuration)

### Authentication

- Change default passwords immediately after deployment
- Use strong passwords for all database users
- Create separate users for applications (don't use superuser)
- Regularly rotate passwords

## Changing Passwords

### Important Considerations

⚠️ **Before changing passwords:**
- Ensure cluster is healthy (`patronictl list pg-ha`)
- Schedule maintenance window (brief service interruption possible)
- Update ALL Patroni nodes with new passwords
- Change passwords in correct order

### Password Types

| Password | Used For | Environment Variables |
|----------|----------|----------------------|
| **Superuser** | postgres user, system admin | `PATRONI_SUPERUSER_PASSWORD`, `PGPASSWORD_SUPERUSER`, `POSTGRES_PASSWORD`, `PASSWORD` |
| **Replication** | Replication between nodes | `PATRONI_REPLICATION_PASSWORD`, `PGPASSWORD_STANDBY` |
| **Admin** | Application connections | `PATRONI_admin_PASSWORD`, `PGPASSWORD_ADMIN` |

### Step-by-Step: Change Superuser Password

#### Step 1: Change Password in PostgreSQL

Connect to the leader node and change the password:

```bash
# Run inside any patroni container
psql -U postgres -c "ALTER USER postgres PASSWORD 'new_secure_password';"
```

#### Step 2: Update Environment Variables

In Zeabur Dashboard, update these variables for **ALL Patroni services** (patroni1, patroni2, patroni3, etc.):

```
PATRONI_SUPERUSER_PASSWORD=new_secure_password
PGPASSWORD_SUPERUSER=new_secure_password
POSTGRES_PASSWORD=new_secure_password
PASSWORD=new_secure_password
```

#### Step 3: Restart Services (Rolling Restart)

Restart Patroni services one by one:

1. Check current leader: `patronictl list pg-ha`
2. Restart replica nodes first (wait for healthy between each)
3. Restart leader node last (triggers failover, then failback)

#### Step 4: Verify

```bash
# Test new password
psql -U postgres -c "SELECT 1;"

# Verify cluster health
patronictl list pg-ha
```

### Step-by-Step: Change Replication Password

#### Step 1: Change Password in PostgreSQL

```bash
psql -U postgres -c "ALTER USER replicator PASSWORD 'new_replication_password';"
```

#### Step 2: Update Environment Variables

Update in **ALL Patroni services**:

```
PATRONI_REPLICATION_PASSWORD=new_replication_password
PGPASSWORD_STANDBY=new_replication_password
```

#### Step 3: Rolling Restart

Same as superuser password change.

### Step-by-Step: Change Admin Password

#### Step 1: Change Password in PostgreSQL

```bash
psql -U postgres -c "ALTER USER admin PASSWORD 'new_admin_password';"
```

#### Step 2: Update Environment Variables

Update in **ALL Patroni services**:

```
PATRONI_admin_PASSWORD=new_admin_password
PGPASSWORD_ADMIN=new_admin_password
```

#### Step 3: Rolling Restart

Same as superuser password change.

### Troubleshooting Password Changes

**Problem**: Replication stops working after password change

**Solution**:
- Ensure ALL nodes have the same password
- Check `PGPASSWORD_STANDBY` matches PostgreSQL replicator password
- Verify with: `psql -U postgres -c "SELECT * FROM pg_stat_replication;"`

**Problem**: Patroni can't connect after restart

**Solution**:
- Verify environment variables match PostgreSQL passwords
- Check Patroni logs for authentication errors
- Ensure etcd is healthy: `curl http://etcd1:2379/health`

### Access Control

```sql
-- Create application user with limited privileges
CREATE USER myapp WITH PASSWORD 'strong-password';
CREATE DATABASE myapp_db OWNER myapp;

-- Grant only necessary privileges
GRANT CONNECT ON DATABASE myapp_db TO myapp;
GRANT USAGE ON SCHEMA public TO myapp;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO myapp;
```

## Monitoring

### Key Metrics to Monitor

**etcd**:
- Cluster health status
- Member availability
- Consensus latency
- Disk sync duration

**Patroni**:
- Cluster topology (master/replicas)
- Failover events
- API response times

**PostgreSQL**:
- Replication lag
- Connection count
- Query performance
- Disk usage
- Cache hit ratio

### Monitoring Endpoints

```bash
# etcd metrics (Prometheus format)
curl http://etcd1:2381/metrics

# Patroni cluster status (run inside any patroni container)
patronictl list pg-ha

# PostgreSQL statistics
psql -U postgres -h patroni1 -c "SELECT * FROM pg_stat_database;"
```

## Resources

- [Patroni Documentation](https://patroni.readthedocs.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [etcd Documentation](https://etcd.io/docs/)
- [Spilo (Patroni Docker Image)](https://github.com/zalando/spilo)
- [Zeabur Documentation](https://zeabur.com/docs)

## Related Templates

**Main Template:**
- [**PostgreSQL HA**](https://zeabur.com/templates/IOYTRN): Main 3-node HA cluster template

**Dedicated Expansion Templates (Recommended):**
| Template | ID | URL |
|----------|-----|-----|
| etcd4 | X877ER | https://zeabur.com/templates/X877ER |
| etcd5 | DYGT7Y | https://zeabur.com/templates/DYGT7Y |
| Patroni4 | 3ZC549 | https://zeabur.com/templates/3ZC549 |
| Patroni5 | LNFEJI | https://zeabur.com/templates/LNFEJI |

**Generic Expansion Templates (Legacy):**
- [**etcd Node (Expanding)**](https://zeabur.com/templates/R7Q86W): Add individual etcd nodes (requires configuration)
- [**Patroni PostgreSQL (Expanding)**](https://zeabur.com/templates/D5ZSEA): Add individual Patroni nodes (requires configuration)

## Support

For issues and questions:

- [Zeabur Discord](https://discord.gg/zeabur)
- [GitHub Issues](https://github.com/canyugs/zeabur-template/issues)
- Template source: [GitHub Repository](https://github.com/canyugs/zeabur-template)
