# Storage Upload Bug: "Invalid Compact JWS" with Basic Auth

## Executive Summary

File uploads through the Studio Storage Explorer fail with "Invalid Compact JWS" error when self-hosted Supabase uses Kong's `basic-auth` plugin to protect the Studio/Dashboard. This affects all self-hosted deployments using the default Kong configuration.

## Environment

- **Deployment**: Self-hosted Supabase (Docker Compose / Zeabur)
- **Storage API**: v1.28.1
- **Studio**: 2025.10.20-sha-5005fc6
- **Kong**: Latest (from official Supabase docker-compose)
- **Configuration**: Kong's `basic-auth` plugin enabled for Dashboard route

## Problem Statement

### Symptoms

When attempting to upload files through Studio's Storage Explorer:
- Upload fails immediately
- Storage logs show: `Invalid Compact JWS` error
- HTTP Status: 400
- Status Code: 403

### Impact

- **Severity**: High - Storage feature is unusable through Studio UI
- **Scope**: All self-hosted deployments with basic-auth enabled
- **Workaround**: Files can only be uploaded programmatically via API

## Steps to Reproduce

1. Deploy self-hosted Supabase with default Kong configuration:
   ```yaml
   - name: dashboard
     url: http://studio:3000/
     routes:
       - name: dashboard-all
         paths:
           - /
     plugins:
       - name: basic-auth
         config:
           hide_credentials: true
   ```

2. Access Studio at `https://your-domain.com`

3. Login with basic-auth credentials:
   - Username: `supabase`
   - Password: Configured `DASHBOARD_PASSWORD`

4. Navigate to Storage → Buckets → Any bucket

5. Attempt to upload any file

**Expected**: File uploads successfully

**Actual**: Upload fails with "Invalid Compact JWS" error

## Root Cause Analysis

### The Request Headers Problem

When Studio uploads a file via TUS resumable upload, the browser sends:

```http
POST /storage/v1/upload/resumable HTTP/1.1
Host: test-supa.zeabur.app
apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
authorization: Basic c3VwYWJhc2U6cTk1U1dOOHNRSUhUZ2UwM3BEQUo0bzF3emg2bUcyazc=
content-type: application/offset+octet-stream
tus-resumable: 1.0.0
```

**Key Observation**: Two authentication headers are present:
1. ✅ `apikey`: Contains valid service_role JWT token
2. ❌ `authorization`: Contains Basic Auth credentials

### Why Both Headers Exist

#### The `apikey` Header (Correct)

Studio correctly sends JWT via `apikey` header.

**Source**: `apps/studio/state/storage-explorer.tsx` (lines 1197-1204)

```typescript
onBeforeRequest: async (req) => {
  try {
    const data = await getTemporaryAPIKey({ projectRef: state.projectRef })
    req.setHeader('apikey', data.api_key)  // ← JWT set here
  } catch (error) {
    throw error
  }
}
```

The `getTemporaryAPIKey` function returns:

**Source**: `apps/studio/pages/api/platform/projects/[ref]/api-keys/temporary.ts` (lines 27-33)

```typescript
const handlePost = async (req: NextApiRequest, res: NextApiResponse) => {
  const response = {
    api_key: process.env.SUPABASE_SERVICE_KEY ?? '',
  }
  return res.status(200).json(response)
}
```

**Decoded JWT from `apikey` header**:
```json
{
  "role": "service_role",
  "iss": "supabase-demo",
  "iat": 1641769200,
  "exp": 1799535600
}
```

This is **correct and valid**.

#### The `authorization` Header (Incorrect)

The Basic Auth header comes from the browser's credential cache.

**Decoded Basic Auth**:
```
c3VwYWJhc2U6cTk1U1dOOHNRSUhUZ2UwM3BEQUo0bzF3emg2bUcyazc=
↓ base64 decode ↓
supabase:q95SWN8sQIHTge03pDAJ4o1wzh6mG2k7
```

**Why this happens**:
1. User logs into Studio using Kong's basic-auth
2. Browser stores these credentials for the domain
3. Browser **automatically** includes `Authorization: Basic ...` in all subsequent requests to same origin
4. This includes AJAX requests from Studio to `/storage/v1/*`

### The Storage JWT Plugin Bug

**Source**: `storage/src/http/plugins/jwt.ts` (line 36)

```typescript
fastify.addHook('preHandler', async (request) => {
  request.jwt = (request.headers.authorization || '').replace(BEARER, '')
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // Only reads Authorization header, ignores apikey header!

  if (!request.jwt && request.routeOptions.config.allowInvalidJwt) {
    request.jwtPayload = { role: 'anon' }
    request.isAuthenticated = false
    return
  }

  const { secret, jwks } = await getJwtSecret(request.tenantId)

  try {
    const payload = await (jwtCachingEnabled
      ? verifyJWTWithCache(request.jwt, secret, jwks || null)
      : verifyJWT(request.jwt, secret, jwks || null))
    // Tries to verify "Basic c3VwYWJhc2U6..." as JWT → FAILS
```

**The Problem**:
1. Storage reads JWT from `Authorization` header only
2. Gets `Basic c3VwYWJhc2U6...` instead of JWT
3. Attempts to verify Basic Auth string as JWT token
4. Fails with "Invalid Compact JWS"
5. **The valid JWT in `apikey` header is completely ignored**

### Why This Works on Platform but Fails Self-Hosted

| Aspect | Platform (Cloud) | Self-Hosted |
|--------|-----------------|-------------|
| Studio Protection | OAuth / Custom auth | Kong basic-auth |
| Browser Credentials | None | Basic Auth cached |
| `apikey` header | ✅ JWT sent | ✅ JWT sent |
| `authorization` header | ❌ Not sent | ❌ Basic Auth sent |
| Storage receives | Only `apikey` | Both headers |
| Storage reads from | `Authorization` (empty) → fallback? | `Authorization` (Basic Auth) |
| Result | ✅ Works | ❌ Fails |

### Comparison with Other Services

**Auth, REST, Realtime services** work correctly because they have `key-auth` plugin:

**Source**: Kong configuration (e.g., auth-v1 route)

```yaml
- name: auth-v1
  url: http://auth:9999/
  routes:
    - name: auth-v1-all
      paths:
        - /auth/v1/
  plugins:
    - name: cors
    - name: key-auth        # ← This is the key!
      config:
        hide_credentials: false
    - name: acl
      config:
        hide_groups_header: true
        allow:
          - admin
          - anon
```

**How `key-auth` plugin helps**:
1. Kong reads `apikey` header
2. Validates the JWT token
3. **Overwrites `Authorization` header** with `Bearer <apikey-value>`
4. Forwards request to backend service
5. Backend receives clean `Authorization: Bearer <JWT>` header

**Storage route is different**:

```yaml
- name: storage-v1
  url: http://storage:5000/
  routes:
    - name: storage-v1-all
      paths:
        - /storage/v1/
  plugins:
    - name: cors
    # No key-auth plugin!
    # Comment says: "the storage server manages its own auth"
```

**Why Storage has no `key-auth`**:
- Original design: "storage server manages its own auth"
- Storage is supposed to handle JWT validation internally
- **But Storage's JWT plugin doesn't support `apikey` header!**

## Proposed Solutions

### Solution 1: Fix Storage JWT Plugin ⭐ (Recommended)

**Modify**: `storage/src/http/plugins/jwt.ts` (line 35-42)

**Current code**:
```typescript
fastify.addHook('preHandler', async (request) => {
  request.jwt = (request.headers.authorization || '').replace(BEARER, '')

  if (!request.jwt && request.routeOptions.config.allowInvalidJwt) {
    request.jwtPayload = { role: 'anon' }
    request.isAuthenticated = false
    return
  }
```

**Proposed fix**:
```typescript
fastify.addHook('preHandler', async (request) => {
  // Priority: apikey header > Authorization header
  // This is needed because when Studio is protected by Kong's basic-auth,
  // browsers automatically send Basic Auth credentials in all requests,
  // but Studio sends the actual JWT via the apikey header
  const apikeyHeader = request.headers.apikey as string | undefined
  request.jwt = apikeyHeader || (request.headers.authorization || '').replace(BEARER, '')

  if (!request.jwt && request.routeOptions.config.allowInvalidJwt) {
    request.jwtPayload = { role: 'anon' }
    request.isAuthenticated = false
    return
  }
```

**Pros**:
- ✅ Fixes the issue for all self-hosted deployments with basic-auth
- ✅ Backward compatible (falls back to Authorization header if no apikey)
- ✅ Aligns with how Studio actually sends credentials
- ✅ No Kong configuration changes needed
- ✅ Minimal code change (3 lines)
- ✅ No breaking changes for existing deployments

**Cons**:
- Changes Storage authentication behavior
- Needs testing across different deployment scenarios

**Testing checklist**:
- [ ] File upload works with basic-auth protected Studio
- [ ] File upload still works without basic-auth
- [ ] REST API clients using `Authorization: Bearer` still work
- [ ] REST API clients using `apikey` header work
- [ ] S3 API compatibility not affected

### Solution 2: Add `key-auth` Plugin to Storage Route

**Modify**: Kong configuration in docker-compose volumes

**Current**:
```yaml
- name: storage-v1
  _comment: 'Storage: /storage/v1/* -> http://storage:5000/*'
  url: http://storage:5000/
  routes:
    - name: storage-v1-all
      strip_path: true
      paths:
        - /storage/v1/
  plugins:
    - name: cors
```

**Proposed**:
```yaml
- name: storage-v1
  _comment: 'Storage: /storage/v1/* -> http://storage:5000/*'
  url: http://storage:5000/
  routes:
    - name: storage-v1-all
      strip_path: true
      paths:
        - /storage/v1/
  plugins:
    - name: cors
    - name: key-auth
      config:
        hide_credentials: false
    - name: acl
      config:
        hide_groups_header: true
        allow:
          - admin
          - anon
```

**Pros**:
- ✅ Consistent with other services (Auth, REST, Realtime)
- ✅ Kong handles authentication uniformly
- ✅ No Storage code changes needed
- ✅ Kong automatically transforms `apikey` → `Authorization: Bearer`

**Cons**:
- Changes the original design intent
- Requires configuration changes in all deployments
- Needs documentation update
- May affect users who customized Kong configuration

### Solution 3: Remove Basic-Auth from Dashboard

**Modify**: Kong configuration

**Current**:
```yaml
- name: dashboard
  _comment: 'Studio: /* -> http://studio:3000/*'
  url: http://studio:3000/
  routes:
    - name: dashboard-all
      strip_path: true
      paths:
        - /
  plugins:
    - name: cors
    - name: basic-auth
      config:
        hide_credentials: true
```

**Proposed**:
```yaml
- name: dashboard
  _comment: 'Studio: /* -> http://studio:3000/*'
  url: http://studio:3000/
  routes:
    - name: dashboard-all
      strip_path: true
      paths:
        - /
  plugins:
    - name: cors
    # Remove basic-auth plugin
```

**Pros**:
- ✅ Simplest fix
- ✅ No code changes
- ✅ No Storage changes

**Cons**:
- ❌ Studio becomes publicly accessible
- ❌ Security concern for production deployments
- ❌ Not recommended for production use

## Recommended Implementation Path

### Phase 1: Quick Fix (Solution 1)
1. Modify Storage JWT plugin to support `apikey` header
2. Submit PR to `supabase/storage` repository
3. Release as patch version

### Phase 2: Long-term (Solution 2)
1. Add `key-auth` to Storage route in Kong configuration
2. Update documentation to reflect this change
3. Mark as breaking change (or provide migration path)
4. Consider keeping Solution 1 for backward compatibility

## Additional Context

### Related Issues and Discussions

- **n8n bug with similar header conflict**: https://github.com/n8n-io/n8n/issues/17020
  - Similar issue where Kong prioritizes `Authorization` over `apikey`
  - Their solution: Use only `apikey` header, remove `Authorization`
  - Our issue is inverse: Storage ignores `apikey`, only reads `Authorization`

### TUS Protocol Considerations

Storage uses TUS (Tus Resumable Upload Protocol) for file uploads.

**Allowed headers** (source: `storage/src/http/routes/tus/index.ts` line 144):
```typescript
allowedHeaders: ['Authorization', 'X-Upsert', 'Upload-Expires', 'ApiKey', 'x-signature']
```

Note: `ApiKey` is in the allowed list, but the JWT plugin doesn't read it.

### Browser Behavior

Modern browsers automatically include credentials (Basic Auth) in requests when:
1. User authenticated to a domain with Basic Auth
2. Subsequent requests go to same origin
3. Applies to both navigation and AJAX/fetch requests

This is **standard browser behavior** and cannot be disabled from server-side.

## Testing and Verification

### Test Environment Setup

1. Deploy self-hosted Supabase with basic-auth:
```bash
cd supabase/docker
docker-compose up -d
```

2. Verify Kong configuration includes basic-auth for dashboard

3. Set credentials in `.env`:
```env
DASHBOARD_USERNAME=supabase
DASHBOARD_PASSWORD=your-secure-password
```

### Manual Testing Steps

1. **Access Studio**:
   - Navigate to `https://your-domain.com`
   - Login with basic-auth credentials
   - Verify Studio loads successfully

2. **Check Browser DevTools**:
   - Open DevTools → Network tab
   - Navigate to Storage → Buckets
   - Filter for `/storage/v1/` requests
   - Verify requests include both `apikey` and `authorization` headers

3. **Attempt Upload**:
   - Select any bucket
   - Click "Upload file"
   - Choose a file
   - Click upload
   - **Expected**: Fails with "Invalid Compact JWS"

4. **Check Storage Logs**:
```bash
docker logs supabase-storage -f
```
   - Verify "Invalid Compact JWS" error appears

### Verification After Fix

After applying Solution 1:

1. Rebuild Storage container with patched code
2. Restart services
3. Repeat upload test
4. **Expected**: Upload succeeds
5. Verify Storage logs show successful authentication

## Impact Assessment

### Users Affected
- **All self-hosted deployments** using default Kong configuration
- **Zeabur deployments** using the Supabase template
- **Custom deployments** with basic-auth enabled

### Features Affected
- ❌ File upload via Studio UI
- ✅ File upload via API (workaround available)
- ✅ File download (not affected)
- ✅ Bucket management (not affected)

### Severity Justification
**HIGH** because:
- Default configuration is broken
- Primary UI feature is unusable
- Affects all self-hosted users with basic-auth
- No workaround within Studio UI

## Workarounds

### Temporary Workaround 1: Use API Directly

Upload files programmatically:

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://your-domain.com',
  'your-service-role-key'
)

const { data, error } = await supabase
  .storage
  .from('bucket-name')
  .upload('file-path', file)
```

### Temporary Workaround 2: Disable Basic Auth (Not Recommended)

Remove basic-auth from Kong configuration temporarily for uploads.

**Security Warning**: This exposes Studio publicly!

## References

### Code Locations

- Storage JWT Plugin: `storage/src/http/plugins/jwt.ts`
- Storage TUS Routes: `storage/src/http/routes/tus/index.ts`
- Studio Storage Explorer: `apps/studio/state/storage-explorer.tsx`
- Studio API Keys: `apps/studio/pages/api/platform/projects/[ref]/api-keys/temporary.ts`
- Kong Configuration: `docker/volumes/api/kong.yml`

### Documentation

- [Supabase Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting/docker)
- [Kong Key Auth Plugin](https://docs.konghq.com/hub/kong-inc/key-auth/)
- [TUS Protocol Specification](https://tus.io/protocols/resumable-upload.html)

## Appendix: Full Request Example

```http
POST /storage/v1/upload/resumable HTTP/1.1
Host: test-supa.zeabur.app
Accept: */*
Accept-Encoding: gzip, deflate, br, zstd
Accept-Language: zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7
apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJzZXJ2aWNlX3JvbGUiLAogICAgImlzcyI6ICJzdXBhYmFzZS1kZW1vIiwKICAgICJpYXQiOiAxNjQxNzY5MjAwLAogICAgImV4cCI6IDE3OTk1MzU2MDAKfQ.DaYlNEoUrrEn2Ig7tqibS-PHK5vgusbcbo7X36XVt4Q
authorization: Basic c3VwYWJhc2U6cTk1U1dOOHNRSUhUZ2UwM3BEQUo0bzF3emg2bUcyazc=
content-length: 257181
content-type: application/offset+octet-stream
origin: https://test-supa.zeabur.app
referer: https://test-supa.zeabur.app/project/default/storage/buckets/99999
tus-resumable: 1.0.0
upload-length: 257181
upload-metadata: bucketName OTk5OTk=,objectName MTYxMjM5LnBuZw==,cacheControl MzYwMA==,contentType aW1hZ2UvcG5n
user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36
x-source: supabase-dashboard
```

---

**Document Version**: 1.0
**Last Updated**: 2025-01-26
**Author**: Bug Investigation Team
**Status**: Ready for GitHub Issue Submission
