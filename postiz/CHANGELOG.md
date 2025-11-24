# Changelog

All notable changes to the Postiz Zeabur template will be documented in this file.

## [v2.0] - 2024-11-24

### 🔧 Breaking Changes

**Template Version Upgrade**
- Migrated from `PREBUILT` to `PREBUILT_V2` template system
- Updated Postiz image from `latest` to fixed version `v2.8.3`

**Security Improvements**
- PostgreSQL password changed from hardcoded `postiz` to randomly generated password using `${PASSWORD}`
- ⚠️ **Action Required**: Existing deployments should redeploy to use secure random passwords

### ✨ Major Features

#### Redis Configuration Optimization

**Memory & Eviction Policy**
- Increased Redis max memory: `256mb` → `512mb`
- Changed eviction policy: `allkeys-lru` → `noeviction`
- **Reason**: Fixes Postiz Worker error: `IMPORTANT! Eviction policy is allkeys-lru. It should be "noeviction"`
- **Impact**: Ensures scheduled posts are never automatically deleted from the job queue

**Connection Strings**
- Added `REDIS_URI_INTERNAL` for container-internal communication
  ```yaml
  REDIS_URI_INTERNAL:
      default: redis://:${REDIS_PASSWORD}@${CONTAINER_HOSTNAME}:6379
      expose: true
  ```
- Existing `REDIS_URI` now used for external connections only
- Postiz service now uses `REDIS_URI_INTERNAL` instead of `REDIS_URI`

#### PostgreSQL Configuration Optimization

**Connection Strings**
- Added `POSTGRES_CONNECTION_STRING_INTERNAL` for container-internal communication
  ```yaml
  POSTGRES_CONNECTION_STRING_INTERNAL:
      default: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${CONTAINER_HOSTNAME}:5432/${POSTGRES_DB}
      expose: true
  ```
- Existing `POSTGRES_CONNECTION_STRING` now used for external connections only
- Postiz service now uses `POSTGRES_CONNECTION_STRING_INTERNAL`

**Security**
- `POSTGRES_PASSWORD`: Changed from `postiz` to `${PASSWORD}` (randomly generated)

#### Postiz Service Improvements

**Volumes**
- Added `/config/` volume for application configuration
  ```yaml
  volumes:
      - id: config
        dir: /config/
      - id: uploads
        dir: /uploads/
  ```

**Ports**
- Added explicit API port definition
  ```yaml
  ports:
      - id: web
        port: 5000
        type: HTTP
      - id: api
        port: 3000
        type: HTTP
  ```

**Environment Variables - New Additions**
- `IS_GENERAL: "true"` - Enable general mode
- `DISABLE_REGISTRATION: "false"` - Allow user registration by default
- `NOT_SECURED: "true"` - Development-friendly defaults
- `STORAGE_PROVIDER: local` - Use local filesystem storage
- `UPLOAD_DIRECTORY: /uploads` - Upload directory path
- `NEXT_PUBLIC_UPLOAD_DIRECTORY: /uploads` - Public upload path

**Environment Variables - Updated**
- `DATABASE_URL`: Now uses `${POSTGRES_CONNECTION_STRING_INTERNAL}`
- `REDIS_URL`: Now uses `${REDIS_URI_INTERNAL}`

**Environment Variables - Removed**
- `HOST: 0.0.0.0` - Handled by Docker image defaults
- `NODE_ENV: production` - Handled by Docker image defaults

### 🐛 Bug Fixes

- Fixed Redis eviction policy warning that appeared in Postiz Worker logs
- Fixed inefficient network routing by using internal container hostnames
- Fixed potential job queue data loss due to `allkeys-lru` eviction policy
- Fixed security vulnerability of hardcoded PostgreSQL password

### 🚀 Performance Improvements

- Container-to-container communication now uses internal network (`CONTAINER_HOSTNAME`)
- Reduced network latency by avoiding external port forwarding for service communication
- Increased Redis memory allocation to prevent OOM errors under normal usage

### 📚 Documentation

- Added comprehensive README.md with Zeabur-specific deployment instructions
- Added first-time setup guide with step-by-step instructions
- Added Redis memory monitoring guide
- Added troubleshooting section for common issues
- All advanced configuration now redirects to official Postiz documentation

### 🔒 Security

- PostgreSQL password now randomly generated per deployment
- Improved isolation between external and internal service connections
- Added security checklist in README

---

## [v1.0] - Initial Release

### Features

- Basic Postiz deployment with Redis and PostgreSQL
- Docker image: `ghcr.io/gitroomhq/postiz-app:latest`
- Redis 7.2 with 256MB memory
- PostgreSQL 17 Alpine
- Basic environment variable configuration

### Known Issues

- Redis eviction policy causes Worker warnings
- PostgreSQL uses hardcoded password
- Services communicate via external port forwarding
- No internal connection strings for container communication

---

## Migration Guide

### From v1.0 to v2.0

**Recommended Approach: Fresh Deployment**

Due to password changes, we recommend a fresh deployment:

1. Export your data from v1.0 deployment
2. Deploy new v2.0 template
3. Import data to v2.0 deployment

**What Changed:**
- ✅ Redis no longer shows eviction policy warnings
- ✅ More secure with random passwords
- ✅ Better performance with internal networking
- ✅ Fixed version for stability

**No Action Required If:**
- You are deploying Postiz for the first time
- You don't have existing data to migrate

---

## Version Comparison

| Feature | v1.0 | v2.0 |
|---------|------|------|
| Template Type | PREBUILT | PREBUILT_V2 |
| Postiz Version | latest | v2.8.3 (fixed) |
| Redis Memory | 256MB | 512MB |
| Redis Eviction | allkeys-lru | noeviction |
| Internal Networking | ❌ | ✅ |
| PostgreSQL Password | hardcoded | random |
| Documentation | Basic | Comprehensive |
| Config Volume | ❌ | ✅ |

---

## Support

- **Template Issues**: [Zeabur Template Repository](https://github.com/zeabur/zeabur)
- **Postiz Issues**: [Postiz GitHub](https://github.com/gitroomhq/postiz-app/issues)
- **Documentation**: See [README.md](./README.md)
