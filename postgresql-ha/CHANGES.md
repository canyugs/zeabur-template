# PostgreSQL HA Template - Changes Log

## Latest Changes (2024)

### New Dedicated Expansion Templates

Created specific templates for expanding from 3 to 5 nodes:

#### etcd Templates
- **etcd4** (`zeabur-template-X877ER-etcd4.yaml`)
  - Template URL: https://zeabur.com/templates/X877ER
  - Pre-configured for 4th etcd node
  - No variables needed, just deploy

- **etcd5** (`zeabur-template-DYGT7Y-etcd5.yaml`)
  - Template URL: https://zeabur.com/templates/DYGT7Y
  - Pre-configured for 5th etcd node
  - Includes etcd4 in INITIAL_CLUSTER

#### Patroni Templates
- **Patroni4** (`zeabur-template-patroni4-3ZC549.yaml`)
  - Template URL: https://zeabur.com/templates/3ZC549
  - Pre-configured for 4th PostgreSQL node
  - Requires password input (must match existing cluster)
  - Configurable ETCD3_HOSTS

- **Patroni5** (`zeabur-template-patroni5-LNFEJI.yaml`)
  - Template URL: https://zeabur.com/templates/LNFEJI
  - Pre-configured for 5th PostgreSQL node
  - Requires password input (must match existing cluster)
  - Configurable ETCD3_HOSTS

### etcd Changes

#### Image Update
- Changed from `gcr.io/etcd-development/etcd:v3.6.0` to `gcr.io/etcd-development/etcd:v3.6.6`
- Note: v3.6+ uses distroless image (no shell)

#### HTTP API Instructions
Since distroless image has no shell/etcdctl, added HTTP API instructions to all etcd services:
- Client Endpoint
- List Members
- Add Member (replace service name)
- Delete Member (replace member-id)
- Cluster Health
- Put Key (test=hello)
- Get Key (test)

### Patroni Changes

#### CLI Instructions
- Added `Cluster Status (run in container)` instruction to all Patroni services
- Command: `patronictl list pg-ha`
- Updated documentation to use `patronictl` instead of `curl` (container may not have curl)

#### ETCD3_HOSTS Variable
- Added `ETCD3_HOSTS` variable to patroni4/patroni5 templates
- Users can configure which etcd nodes to connect to
- Recommendation: Update all Patroni services after adding new etcd nodes

### Documentation Updates

#### Main Template (postgresql-ha-IOYTRN)
- Updated "Scaling the Cluster" section with links to new templates
- Updated "Related Templates" section
- Added Step 3: Update Patroni ETCD3_HOSTS after adding etcd nodes
- Changed Management/Troubleshooting to use `patronictl` commands

#### Expansion Template READMEs
Simplified to essential steps only:

**etcd4/etcd5:**
```
Step 1: Register Node (curl command)
Step 2: Deploy & Verify
Step 3: Update Patroni (Recommended)
```

**patroni4/patroni5:**
```
⚠️ Use the same passwords as your existing cluster.
Deploy & Verify (patronictl list pg-ha)
```

### File Structure

```
postgresql-ha/
├── zeabur-template-postgresql-ha-IOYTRN.yaml   # Main 3-node HA cluster
├── zeabur-template-X877ER-etcd4.yaml           # etcd 4th node
├── zeabur-template-DYGT7Y-etcd5.yaml           # etcd 5th node
├── zeabur-template-patroni4-3ZC549.yaml        # Patroni 4th node
├── zeabur-template-patroni5-LNFEJI.yaml        # Patroni 5th node
├── zeabur-template-R7Q86W-etcd-single.yaml     # Generic etcd expansion (legacy)
├── zeabur-template-D5ZSEA-patroni-single.yaml  # Generic Patroni expansion (legacy)
├── README.md
└── CHANGES.md
```

### User Workflow (3 → 5 Nodes)

1. **Add etcd4**:
   - Run: `curl -X POST http://etcd1:2379/v3/cluster/member/add -d '{"peerURLs":["http://etcd4:2380"]}'`
   - Deploy etcd4 template

2. **Add etcd5**:
   - Run: `curl -X POST http://etcd1:2379/v3/cluster/member/add -d '{"peerURLs":["http://etcd5:2380"]}'`
   - Deploy etcd5 template

3. **Update Patroni ETCD3_HOSTS** (all existing patroni1/2/3):
   ```
   etcd1:2379,etcd2:2379,etcd3:2379,etcd4:2379,etcd5:2379
   ```

4. **Add patroni4**:
   - Enter same passwords as existing cluster
   - Enter ETCD3_HOSTS
   - Deploy

5. **Add patroni5**:
   - Enter same passwords as existing cluster
   - Enter ETCD3_HOSTS
   - Deploy

6. **Verify**:
   - Run in any patroni container: `patronictl list pg-ha`
   - Should see 5 members (1 leader + 4 replicas)

### Template Links

| Template | ID | URL |
|----------|-----|-----|
| PostgreSQL HA (Main) | IOYTRN | https://zeabur.com/templates/IOYTRN |
| etcd4 | X877ER | https://zeabur.com/templates/X877ER |
| etcd5 | DYGT7Y | https://zeabur.com/templates/DYGT7Y |
| Patroni4 | 3ZC549 | https://zeabur.com/templates/3ZC549 |
| Patroni5 | LNFEJI | https://zeabur.com/templates/LNFEJI |
