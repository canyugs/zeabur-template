# Zeabur Template Writing Guide

> **Language**: English | [繁體中文](./README.md) | [简体中文](./README.zh-CN.md)

This document explains how to write and maintain service templates for the Zeabur platform.

## Table of Contents

- [Overview](#overview)
- [Template Structure](#template-structure)
- [Writing Process](#writing-process)
- [Best Practices](#best-practices)
- [Localization Support](#localization-support)
- [Testing and Validation](#testing-and-validation)
- [Examples](#examples)

## Overview

Zeabur templates are defined in YAML format, similar to Kubernetes resource definitions. Each template describes the deployment configuration of one or more services, allowing users to deploy complete application stacks with one click.

### Core Concepts

- **Template Resource**: Template resource definition in YAML format
- **Services**: List of services included in the template (can be Docker images or Git repositories)
- **Variables**: Variables that users need to fill in (such as domain names, passwords, etc.)
- **Localization**: Multi-language support for users in different regions

## Template Structure

### Basic Structure

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
apiVersion: zeabur.com/v1
kind: Template
metadata:
    name: Template Name
spec:
    description: Template description
    icon: Icon URL
    coverImage: Cover image URL
    variables: []
    tags: []
    readme: |
      README content
    services: []
localization:
    zh-TW: {}
    zh-CN: {}
```

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| `apiVersion` | API version, fixed as `zeabur.com/v1` | `zeabur.com/v1` |
| `kind` | Resource type, fixed as `Template` | `Template` |
| `metadata.name` | Template name | `PostgreSQL` |
| `spec.services` | Service list | See below |

### Optional Fields

| Field | Description | Type |
|-------|-------------|------|
| `spec.description` | Template description | string/null |
| `spec.icon` | Template icon URL | string/null |
| `spec.coverImage` | Cover image URL | string/null |
| `spec.variables` | User variables | array |
| `spec.tags` | Tags | array |
| `spec.readme` | README content (Markdown) | string/null |
| `spec.resourceUsage` | Expected resource usage | object |

## Writing Process

### Step 1: Research Target Service

1. **Understand Service Architecture**
   - Read official documentation
   - Review Docker Compose configuration
   - Confirm dependent services (database, cache, etc.)

2. **Collect Necessary Information**
   - Docker image name and tag
   - Default port numbers
   - Environment variables
   - Persistent storage requirements
   - Health check methods

3. **Prepare Assets**
   - Service icon (SVG/PNG, official icon recommended)
   - Screenshot or cover image (WebP format, recommended 1200x630)
   - Documentation links

### Step 2: Create Template File

Create `zeabur-template-{service-name}.yaml` file:

```bash
mkdir {service-name}
cd {service-name}
touch zeabur-template-{service-name}.yaml
```

### Step 3: Define Basic Information

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
apiVersion: zeabur.com/v1
kind: Template
metadata:
    name: ServiceName
spec:
    description: |
      Brief description of the service (1-2 sentences)
    icon: https://example.com/icon.svg
    coverImage: https://example.com/cover.webp
    tags:
      - Category1
      - Category2
```

### Step 4: Define User Variables

```yaml
spec:
    variables:
      - key: PUBLIC_DOMAIN
        type: DOMAIN
        name: Domain
        description: What domain do you want to bind to?
      - key: ADMIN_PASSWORD
        type: STRING
        name: Admin Password
        description: Password for the admin user
```

**Variable Types:**
- `DOMAIN`: Domain name (Zeabur can auto-generate .zeabur.app domains)
- `STRING`: General text input

### Step 5: Define Services

#### 5.1 Database Service Example (PostgreSQL)

```yaml
spec:
    services:
      - name: postgresql
        icon: https://raw.githubusercontent.com/zeabur/service-icons/main/marketplace/postgresql.svg
        template: PREBUILT
        spec:
          source:
              image: postgres:16-alpine
          ports:
              - id: database
                port: 5432
                type: TCP
          volumes:
              - id: data
                dir: /var/lib/postgresql/data
          env:
              POSTGRES_DB:
                  default: myapp_db
              POSTGRES_USER:
                  default: myapp_user
              POSTGRES_PASSWORD:
                  default: ${PASSWORD}
                  expose: true
              POSTGRES_HOST:
                  default: ${CONTAINER_HOSTNAME}
                  expose: true
                  readonly: true
              POSTGRES_PORT:
                  default: ${DATABASE_PORT}
                  expose: true
                  readonly: true
```

#### 5.2 Application Service Example

```yaml
      - name: app
        icon: https://example.com/app-icon.svg
        template: PREBUILT
        domainKey: PUBLIC_DOMAIN
        dependencies:
            - postgresql
        spec:
          source:
            image: myapp/myapp:latest
          ports:
          - id: web
            port: 8080
            type: HTTP
          env:
            DATABASE_URL:
              default: postgresql://${POSTGRES_USERNAME}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DATABASE}
              readonly: true
            APP_URL:
              default: ${ZEABUR_WEB_URL}
              readonly: true
          volumes:
            - id: data
              dir: /app/data
```

### Step 6: Add Documentation

```yaml
spec:
    readme: |
      # ServiceName

      Service introduction

      ## Usage
      - Open `https://${PUBLIC_DOMAIN}`
      - Login with default credentials

      ## Configuration Options
      - `ENV_VAR_1`: Description
      - `ENV_VAR_2`: Description

      ## Documentation
      - Official docs: https://example.com/docs
      - GitHub: https://github.com/example/repo
```

### Step 7: Add Localization

```yaml
localization:
    zh-TW:
        description: |
          Traditional Chinese description
        variables:
          - key: PUBLIC_DOMAIN
            type: DOMAIN
            name: 網域
            description: 你想綁定哪個網域？
          - key: ADMIN_PASSWORD
            type: STRING
            name: 管理員密碼
            description: 管理員使用者的密碼
        readme: |
          # Service Name

          Traditional Chinese documentation...

    zh-CN:
        description: |
          Simplified Chinese description
        variables:
          - key: PUBLIC_DOMAIN
            type: DOMAIN
            name: 域名
            description: 你想绑定哪个域名？
          - key: ADMIN_PASSWORD
            type: STRING
            name: 管理员密码
            description: 管理员用户的密码
        readme: |
          # Service Name

          Simplified Chinese documentation...
```

## Best Practices

### 1. Naming Conventions

- **File naming**: `zeabur-template-{service-name}.yaml`
- **Service names**: Use lowercase letters, hyphens allowed
- **Variable naming**: Use uppercase letters and underscores, e.g., `PUBLIC_DOMAIN`

### 2. Multi-language Support

**Highly recommended to provide multi-language support for all templates**, including at least English, Traditional Chinese, and Simplified Chinese.

#### Required Localized Content

1. **description** - Template description
   ```yaml
   spec:
     description: |
       English description
   localization:
     zh-TW:
       description: |
         繁體中文描述
     zh-CN:
       description: |
         简体中文描述
   ```

2. **variables** - Variable names and descriptions
   ```yaml
   spec:
     variables:
       - key: PUBLIC_DOMAIN
         type: DOMAIN
         name: Domain
         description: What domain do you want to bind to?
   localization:
     zh-TW:
       variables:
         - key: PUBLIC_DOMAIN
           name: 網域
           description: 你想綁定哪個網域？
     zh-CN:
       variables:
         - key: PUBLIC_DOMAIN
           name: 域名
           description: 你想绑定哪个域名？
   ```

3. **readme** - Documentation
   - Usage instructions
   - Configuration options
   - Documentation links

#### Translation Quality Requirements

- ✅ Use correct professional terminology
- ✅ Maintain consistent tone
- ✅ Pay attention to Traditional vs Simplified Chinese differences (伺服器 vs 服务器, 資料庫 vs 数据库)
- ✅ All language versions should have complete and consistent information

#### Supported Language Codes

- `en-US`: English (default, written directly in spec)
- `zh-TW`: Traditional Chinese (Taiwan, Hong Kong, Macau)
- `zh-CN`: Simplified Chinese (Mainland China)
- `ja-JP`: Japanese
- `es-ES`: Spanish

### 3. Image Resources

- **Icons**:
  - Prefer SVG format
  - If using raster images, at least 512x512px
  - Use official brand icons

- **Cover Images**:
  - Recommended size: 1200x630px
  - Format: WebP (smaller file size)
  - Storage location: `screenshot.webp` in GitHub repository

### 4. Environment Variable Design

```yaml
env:
    # Auto-generated variables (expose: true, readonly: true)
    SERVICE_HOST:
        default: ${CONTAINER_HOSTNAME}
        expose: true
        readonly: true

    # User-modifiable variables
    CUSTOM_CONFIG:
        default: "default-value"
        expose: true

    # Internal variables (not exposed)
    INTERNAL_VAR:
        default: "internal-value"
```

**⚠️ Important: Domain URL Configuration**

When a service needs to know its own public URL, don't use `${PUBLIC_DOMAIN}` directly:

```yaml
# ❌ Wrong approach
env:
    APP_URL:
        default: https://${PUBLIC_DOMAIN}  # If user inputs "myapp", becomes https://myapp

# ✅ Correct approach
env:
    APP_URL:
        default: ${ZEABUR_WEB_URL}  # Zeabur auto-provides full URL like https://myapp.zeabur.app
        readonly: true
```

### 5. Dependency Management

Use `dependencies` to ensure service startup order:

```yaml
services:
  - name: database
    # ... database configuration

  - name: cache
    # ... cache configuration

  - name: app
    dependencies:
      - database
      - cache
    # ... application configuration
```

### 6. Health Checks (for databases, etc.)

```yaml
# Note: Zeabur template schema doesn't directly support healthcheck
# But you can use wait scripts in the init phase
spec:
  init:
    - id: wait-for-db
      command:
      - /bin/bash
      - -c
      - |
        until pg_isready -h ${POSTGRES_HOST} -p ${POSTGRES_PORT}; do
          echo "Waiting for database..."
          sleep 2
        done
```

### 7. Initialization Scripts

```yaml
spec:
  init:
    - id: init-db
      command:
      - /bin/bash
      - -c
      - |
        if [ ! -f /var/lib/app/.initialized ]; then
          # Execute initialization logic
          touch /var/lib/app/.initialized
        fi
```

## Localization Support

### Supported Language Codes

- `en-US`: English (default, no need to define in localization)
- `zh-TW`: Traditional Chinese
- `zh-CN`: Simplified Chinese
- `ja-JP`: Japanese
- `es-ES`: Spanish

### Localizable Fields

1. **description**: Template description
2. **coverImage**: Cover image (different images for different languages)
3. **variables**: Variable names and descriptions
4. **readme**: README documentation

### Translation Guidelines

#### Traditional vs Simplified Chinese Terminology

| English | Traditional Chinese | Simplified Chinese |
|---------|--------------------|--------------------|
| Server | 伺服器 | 服务器 |
| Database | 資料庫 | 数据库 |
| Configuration | 配置/設定 | 配置 |
| Connection | 連線 | 连接 |
| Domain | 網域 | 域名 |
| Authentication | 身份驗證 | 身份验证 |
| Middleware | 中介層 | 中间层 |
| Documentation | 文件 | 文档 |

## Testing and Validation

### 1. Schema Validation

In VS Code, the first line schema comment enables automatic validation:

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
```

### 2. Essential Checklist

- [ ] All required fields are filled
- [ ] Icon and cover image URLs are accessible
- [ ] Environment variables are correctly configured
- [ ] Dependencies are properly set
- [ ] README includes usage instructions
- [ ] Localization translations are complete and correct
- [ ] Variable default values are reasonable

### 3. Local Testing

Test locally using Docker Compose:

```bash
# Manually convert Zeabur template to Docker Compose
# Confirm services can start normally
docker-compose up
```

### 4. Using Zeabur CLI

```bash
# Use npx to run Zeabur CLI (no global installation needed)
npx zeabur@latest auth login

# Deploy test
npx zeabur@latest template deploy zeabur-template-{service-name}.yaml
```

## Common Issues

### Q: How to handle sensitive information?

Use Zeabur's password generation feature:

```yaml
env:
    SECRET_KEY:
        default: ${PASSWORD}  # Auto-generate secure password
        expose: true
```

### Q: How to make services wait for database readiness?

Use wait scripts in the `init` phase or implement retry logic in the application.

### Q: PUBLIC_DOMAIN variable vs Application URL configuration?

This is a common point of confusion:

**Problem Scenario:**
- User inputs in `PUBLIC_DOMAIN` variable: `myapp`
- Zeabur auto-binds to: `myapp.zeabur.app`
- But `${PUBLIC_DOMAIN}` variable value is still: `myapp`
- If you set `APP_URL: https://${PUBLIC_DOMAIN}`, it becomes `https://myapp` ❌

**Solution:**

```yaml
variables:
  # This variable is for Zeabur to bind domain
  - key: PUBLIC_DOMAIN
    type: DOMAIN
    name: Domain
    description: What domain do you want to bind to?

services:
  - name: app
    domainKey: PUBLIC_DOMAIN  # Bind domain
    spec:
      env:
        # Application internally uses full URL
        APP_URL:
          default: ${ZEABUR_WEB_URL}  # ✅ Use Zeabur built-in variable
          readonly: true
        NEXT_PUBLIC_APP_URL:
          default: ${ZEABUR_WEB_URL}  # ✅ Full URL with protocol
          readonly: true
```

**Key Points:**
- `PUBLIC_DOMAIN`: User-fillable variable for domain binding
- `${ZEABUR_WEB_URL}`: Zeabur auto-provided full URL (includes https:// and full domain)
- Don't use `${PUBLIC_DOMAIN}` directly in application URL configuration

### Q: How to handle multiple domains?

Use array form of `domainKey`:

```yaml
domainKey:
  - port: web
    variable: FRONTEND_DOMAIN
  - port: api
    variable: API_DOMAIN
```

### Q: Where to find icons?

1. Service official website
2. GitHub repository
3. [zeabur/service-icons](https://github.com/zeabur/service-icons)
4. [Simple Icons](https://simpleicons.org/)

## Example References

Example templates in this repository:

- **Odoo**: Complete ERP system with PostgreSQL
  - File: `odoo/zeabur-template-odoo.yaml`
  - Features: Custom configuration, initialization scripts

- **FossFLOW**: PWA drawing application
  - File: `FossFLOW/zeabur-template-fossflow.yaml`
  - Features: Single service, persistent storage

- **MetaMCP**: MCP aggregator
  - File: `MetaMCP/zeabur-template-metamcp.yaml`
  - Features: Dual service dependency, complete localization

## Advanced Topics

### Custom Configuration Files

Use `configs` to inject configuration files:

```yaml
spec:
  configs:
    - path: /etc/app/config.yml
      template: |
        server:
          host: 0.0.0.0
          port: ${PORT}
        database:
          url: ${DATABASE_URL}
      envsubst: true  # Enable environment variable substitution
```

### Multi-Port Services

```yaml
spec:
  ports:
    - id: web
      port: 8080
      type: HTTP
    - id: api
      port: 3000
      type: HTTP
    - id: websocket
      port: 9000
      type: TCP
```

### Resource Usage Hints

```yaml
spec:
  resourceUsage:
    cpu: 0.5      # vCPU
    memory: 1024  # MiB
```

## Zeabur Built-in Variables Reference

You can use the following built-in variables provided by Zeabur when writing templates. For a complete list of variables, refer to the [official documentation](https://zeabur.com/docs/en-US/deploy/variables).

### Special Variables

These variables are automatically provided by Zeabur and have special meanings:

| Variable Name | Description | Example | Usage |
|---------------|-------------|---------|-------|
| `${ZEABUR_WEB_URL}` | Full public URL for web port | `https://myapp.zeabur.app` | Git-deployed services, port name fixed as `web` |
| `${ZEABUR_[PORTNAME]_URL}` | Full URL for specified port | `https://api.myapp.zeabur.app` | Multi-port services, replace `[PORTNAME]` with actual port name |
| `${ZEABUR_WEB_DOMAIN}` | Domain name for web port | `myapp.zeabur.app` | Domain without protocol |
| `${ZEABUR_[PORTNAME]_DOMAIN}` | Domain name for specified port | `api.myapp.zeabur.app` | Domain without protocol |
| `${CONTAINER_HOSTNAME}` | Hostname of current service in project | `postgresql-abc123` | For inter-service internal communication |

**Detailed Explanation:**
- `ZEABUR_WEB_URL` is the most commonly used variable, corresponding to the URL you bind in "Domain" settings
- For Git repository deployed services, port name is always `web`, so use `${ZEABUR_WEB_URL}`
- For Prebuilt services, port name is defined by `spec.ports[].id`

### Port Related

| Variable Name | Description | Example |
|---------------|-------------|---------|
| `${PORT}` | Default listening port for service | `8080` |
| `${[PORTNAME]_PORT}` | Port value for specified port | `${WEB_PORT}` → `3000` |

### Database Related (PostgreSQL Example)

Zeabur database services automatically expose the following variables:

| Variable Name | Description |
|---------------|-------------|
| `${POSTGRES_HOST}` | PostgreSQL hostname |
| `${POSTGRES_PORT}` | PostgreSQL port |
| `${POSTGRES_USERNAME}` | PostgreSQL username |
| `${POSTGRES_PASSWORD}` | PostgreSQL password |
| `${POSTGRES_DATABASE}` | PostgreSQL database name |
| `${POSTGRES_CONNECTION_STRING}` | PostgreSQL full connection string |
| `${POSTGRES_URI}` | PostgreSQL URI (same as CONNECTION_STRING) |

**Note:** Other databases (MySQL, MongoDB, Redis, etc.) have similar variable formats.

### Port Forwarding Related

Available when using port forwarding feature:

| Variable Name | Description |
|---------------|-------------|
| `${PORT_FORWARDED_HOSTNAME}` | Port forwarding hostname |
| `${[PORTNAME]_PORT_FORWARDED_PORT}` | Port forwarding port number |
| `${DATABASE_PORT_FORWARDED_PORT}` | Database port forwarding port number |

### Password Generation

| Variable Name | Description |
|---------------|-------------|
| `${PASSWORD}` | Zeabur auto-generated secure random password |

**Usage Recommendations:**
- ✅ Application needs to know its public URL → Use `${ZEABUR_WEB_URL}`
- ✅ Inter-service internal communication → Use `${CONTAINER_HOSTNAME}`
- ✅ Need secure password → Use `${PASSWORD}`
- ❌ Don't use `${PUBLIC_DOMAIN}` (user variable) directly in application URL

### Variable Reference Order

When referencing variables in templates, Zeabur resolves them in the following order:

1. User-defined variables in template (like `PUBLIC_DOMAIN`)
2. Service-exposed environment variables (`expose: true`)
3. Zeabur special variables (like `${ZEABUR_WEB_URL}`)
4. System built-in variables (like `${PASSWORD}`)

For more information, refer to:
- [Special Variables Documentation](https://zeabur.com/docs/en-US/deploy/special-variables)
- [Environment Variables Setup](https://zeabur.com/docs/en-US/deploy/variables)

## References

- [Zeabur Official Documentation](https://zeabur.com/docs)
- [Template Schema](https://schema.zeabur.app/template.json)
- [Prebuilt Service Schema](https://schema.zeabur.app/prebuilt.json)
- [Template Repository](https://github.com/zeabur/zeabur)
- [Creating Templates from YAML](https://zeabur.com/docs/en-US/template/template-in-code)

## Contributing Guidelines

1. Fork this repository
2. Create a new service directory
3. Write template file
4. Prepare screenshots
5. Submit Pull Request

### PR Checklist

- [ ] Template passes schema validation
- [ ] Includes English, Traditional Chinese, and Simplified Chinese translations
- [ ] Provides screenshot (screenshot.webp)
- [ ] README documentation is complete
- [ ] Tested deployment on Zeabur platform

## License

MIT License
