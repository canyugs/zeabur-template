# PostgreSQL HA Template - Single Node Add/Remove Plan

## Current State Analysis

### Architecture
- **3 etcd nodes**: Distributed consensus layer
- **3 Patroni nodes**: PostgreSQL HA with automatic failover
- **Fixed cluster size**: Hard-coded for 3-node configuration

### Issues Identified

1. **etcd cluster**:
   - `ETCD_INITIAL_CLUSTER` hard-codes all 3 nodes
   - Cannot run with 1 node (would need `ETCD_INITIAL_CLUSTER_STATE: new` with single node)
   - Cannot easily add/remove nodes without reconfiguration

2. **Patroni cluster**:
   - `ETCD3_HOSTS` references all 3 etcd nodes
   - Dependencies force all 3 etcd nodes to exist
   - Cannot run standalone without etcd cluster

## Challenges for Scaling

### Technical Constraints

1. **etcd Consensus Requirements**:
   - 1 node: No HA, but functional (quorum of 1/1)
   - 2 nodes: **NOT RECOMMENDED** (can't maintain quorum if 1 fails)
   - 3 nodes: Tolerates 1 failure (quorum 2/3) ✅
   - 5 nodes: Tolerates 2 failures (quorum 3/5) ✅

2. **Patroni Requirements**:
   - Needs at least 1 etcd node for DCS (Distributed Configuration Store)
   - 1 Patroni node: No HA, standalone PostgreSQL
   - 2 Patroni nodes: Basic replication, no automatic failover (no quorum)
   - 3+ Patroni nodes: Full HA with automatic failover ✅

3. **Zeabur Template Limitations**:
   - Cannot conditionally include/exclude services based on variables
   - Cannot use loops or dynamic service generation
   - Service names must be predefined

## Proposed Solutions

### Option 1: Multiple Template Variants (RECOMMENDED)

Create separate templates for different deployment scenarios:

1. **PostgreSQL Standalone** (`zeabur-template-postgresql-standalone.yaml`)
   - 1 PostgreSQL service (no Patroni, no etcd)
   - Simplest deployment, no HA
   - Use case: Development, testing, small projects

2. **PostgreSQL HA - 3 Nodes** (`zeabur-template-postgresql-ha.yaml` - current)
   - 3 etcd + 3 Patroni nodes
   - Production-ready HA
   - Use case: Production workloads requiring HA

3. **PostgreSQL HA - 5 Nodes** (`zeabur-template-postgresql-ha-5.yaml`)
   - 5 etcd + 5 Patroni nodes
   - Higher availability (tolerates 2 node failures)
   - Use case: Critical production workloads

**Pros**:
- Clear, purpose-built configurations
- No complexity for users
- Easy to maintain and test
- No conditional logic needed

**Cons**:
- Multiple template files to maintain
- Code duplication

### Option 2: Instructions for Manual Scaling

Keep current 3-node template but add detailed README instructions for:

1. **Scaling down to 1 node** (Development mode):
   - Instructions to remove 2 etcd nodes
   - Instructions to remove 2 Patroni nodes
   - How to update `ETCD_INITIAL_CLUSTER` env var
   - How to update `ETCD3_HOSTS` in Patroni

2. **Scaling up to 5 nodes**:
   - Instructions to add 2 more etcd nodes
   - Instructions to add 2 more Patroni nodes
   - How to update cluster configuration
   - Proper member addition procedure (etcd member add)

**Pros**:
- Single template to maintain
- Flexibility for advanced users

**Cons**:
- Complex manual steps
- High risk of misconfiguration
- Not beginner-friendly
- Cannot be done during initial deployment

### Option 3: Hybrid Approach

Provide 3-node HA template (current) with:

1. **Clear documentation** explaining:
   - When to use this template (production HA scenarios)
   - Link to standalone PostgreSQL template for development
   - Link to 5-node variant for critical workloads

2. **Post-deployment scaling guide**:
   - How to safely add nodes to running cluster
   - How to safely remove nodes from running cluster
   - etcd member management commands
   - Patroni cluster management

**Pros**:
- Best of both worlds
- Clear guidance for users
- Supports both simple and complex use cases

**Cons**:
- Still requires multiple templates for optimal UX

## Recommended Approach

### Implement Option 3 (Hybrid)

1. **Keep current template** for 3-node HA deployment
2. **Create standalone template** for single-node development
3. **Create 5-node template** for critical production workloads
4. **Add comprehensive README sections**:

#### In Main README

```markdown
## Deployment Scenarios

Choose the template that matches your needs:

### Development / Testing
- **Template**: PostgreSQL Standalone
- **Nodes**: 1 PostgreSQL instance
- **High Availability**: No
- **Use Case**: Development, testing, small projects
- **Cost**: Low

### Production (Standard)
- **Template**: PostgreSQL HA (3 nodes) - This template
- **Nodes**: 3 etcd + 3 Patroni/PostgreSQL
- **High Availability**: Yes (tolerates 1 node failure)
- **Use Case**: Production workloads
- **Cost**: Medium

### Production (High Availability)
- **Template**: PostgreSQL HA (5 nodes)
- **Nodes**: 5 etcd + 5 Patroni/PostgreSQL
- **High Availability**: Yes (tolerates 2 node failures)
- **Use Case**: Critical production workloads
- **Cost**: High

## Scaling Guide

### Adding Nodes to Existing Cluster

⚠️ **Important**: Cluster scaling should be done carefully to avoid data loss.

#### Prerequisites
- Cluster must be healthy
- All nodes must be running
- Take backup before scaling operations

#### Add etcd Node

1. Add new etcd member to cluster:
   ```bash
   # From any etcd node
   etcdctl member add etcd4 --peer-urls=http://etcd4:2380
   ```

2. Deploy new etcd4 service with:
   - `ETCD_INITIAL_CLUSTER_STATE: existing`
   - Updated `ETCD_INITIAL_CLUSTER` with all members

3. Update all Patroni nodes' `ETCD3_HOSTS` to include new node

#### Add Patroni Node

1. Ensure etcd cluster is healthy
2. Deploy new Patroni node with same `SCOPE` and `ETCD3_HOSTS`
3. Patroni will automatically join cluster and start replication

### Removing Nodes from Cluster

#### Remove Patroni Node

1. Identify replica node (not master)
2. Stop the Patroni service
3. Remove from monitoring

#### Remove etcd Node

1. Remove member from cluster:
   ```bash
   # Get member ID
   etcdctl member list

   # Remove member
   etcdctl member remove <member-id>
   ```

2. Update remaining nodes' configuration
3. Update all Patroni nodes' `ETCD3_HOSTS`

⚠️ **Warning**: Never reduce etcd cluster below 3 nodes in production. This breaks HA guarantees.
```

#### Configuration Examples

```markdown
## Manual Configuration for Single Node (Advanced)

If you need to run a single-node setup from this template:

### etcd Configuration Changes

For `etcd1` service, update environment variables:
```yaml
ETCD_INITIAL_CLUSTER: etcd1=http://etcd1:2380
ETCD_INITIAL_CLUSTER_STATE: new
```

Remove `etcd2` and `etcd3` services.

### Patroni Configuration Changes

For `patroni1` service, update:
```yaml
ETCD3_HOSTS: etcd1:2379
```

Remove `patroni2` and `patroni3` services.

**Note**: This removes all HA capabilities. Use the standalone template instead.
```

## Implementation Tasks

1. ✅ Analyze current template structure
2. ⬜ Create plan document (this file)
3. ⬜ Update current template README with:
   - Deployment scenario guidance
   - Scaling instructions
   - Configuration examples
4. ⬜ Create standalone PostgreSQL template (optional)
5. ⬜ Create 5-node HA template (optional)
6. ⬜ Add links between related templates

## Technical Notes

### etcd Dynamic Reconfiguration

etcd supports runtime member addition/removal:
- `etcdctl member add` - Add new member
- `etcdctl member remove` - Remove member
- Requires `ETCD_INITIAL_CLUSTER_STATE: existing` for joining nodes

### Patroni Dynamic Cluster Management

Patroni automatically handles:
- New node discovery via etcd
- Replication setup
- Failover elections
- No manual configuration needed for adding replicas

### Zeabur Platform Limitations

- Cannot use variables in service count
- Cannot conditionally include services
- Must predefine all service names
- Best approach: Multiple purpose-built templates

## Conclusion

**Recommendation**: Implement hybrid approach with:

1. Keep current 3-node HA template as default
2. Add comprehensive scaling documentation to README
3. Optionally create standalone and 5-node variants
4. Link templates in a deployment decision tree

This provides the best balance of:
- Ease of use for common scenarios
- Flexibility for advanced users
- Maintainability
- Clear guidance