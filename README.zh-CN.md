# Zeabur 模板编写指南

> **Language**: [English](./README.en-US.md) | [繁體中文](./README.md) | 简体中文

本文档说明如何为 Zeabur 平台编写和维护服务模板。

## 目录

- [概述](#概述)
- [模板结构](#模板结构)
- [编写流程](#编写流程)
- [最佳实践](#最佳实践)
- [多语言支持](#多语言支持)
- [测试与验证](#测试与验证)
- [范例](#范例)

## 概述

Zeabur 模板使用 YAML 格式定义，类似 Kubernetes 资源定义。每个模板描述一个或多个服务的部署配置，让用户可以一键部署完整的应用程序堆栈。

### 核心概念

- **Template Resource**: 使用 YAML 格式的模板资源定义
- **Services**: 模板中包含的服务列表（可以是 Docker 镜像或 Git 仓库）
- **Variables**: 用户需要填写的变量（如域名、密码等）
- **Localization**: 多语言支持，让不同地区用户看到本地化内容

## 模板结构

### 基本结构

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
apiVersion: zeabur.com/v1
kind: Template
metadata:
    name: 模板名称
spec:
    description: 模板描述
    icon: 图标 URL
    coverImage: 封面图片 URL
    variables: []
    tags: []
    readme: |
      README 内容
    services: []
localization:
    zh-TW: {}
    zh-CN: {}
```

### 必要字段

| 字段 | 说明 | 范例 |
|------|------|------|
| `apiVersion` | API 版本，固定为 `zeabur.com/v1` | `zeabur.com/v1` |
| `kind` | 资源类型，固定为 `Template` | `Template` |
| `metadata.name` | 模板名称 | `PostgreSQL` |
| `spec.services` | 服务列表 | 见下方说明 |

### 可选字段

| 字段 | 说明 | 类型 |
|------|------|------|
| `spec.description` | 模板描述 | string/null |
| `spec.icon` | 模板图标 URL | string/null |
| `spec.coverImage` | 封面图片 URL | string/null |
| `spec.variables` | 用户变量 | array |
| `spec.tags` | 标签 | array |
| `spec.readme` | README 内容（Markdown） | string/null |
| `spec.resourceUsage` | 预期资源使用量 | object |

## 编写流程

### 步骤 1: 研究目标服务

1. **了解服务架构**
   - 阅读官方文档
   - 查看 Docker Compose 配置
   - 确认依赖服务（数据库、缓存等）

2. **收集必要信息**
   - Docker 镜像名称和标签
   - 默认端口号
   - 环境变量
   - 持久化存储需求
   - 健康检查方式

3. **准备素材**
   - 服务图标（SVG/PNG，建议使用官方图标）
   - 截图或封面图片（WebP 格式，建议 1200x630）
   - 文档链接

### 步骤 2: 创建模板文件

创建 `zeabur-template-{service-name}.yaml` 文件：

```bash
mkdir {service-name}
cd {service-name}
touch zeabur-template-{service-name}.yaml
```

### 步骤 3: 定义基本信息

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
apiVersion: zeabur.com/v1
kind: Template
metadata:
    name: ServiceName
spec:
    description: |
      服务的简短描述（1-2 句话）
    icon: https://example.com/icon.svg
    coverImage: https://example.com/cover.webp
    tags:
      - Category1
      - Category2
```

### 步骤 4: 定义用户变量

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

**变量类型：**
- `DOMAIN`: 域名（Zeabur 可自动生成 .zeabur.app 域名）
- `STRING`: 一般文本输入

### 步骤 5: 定义服务

#### 5.1 数据库服务范例（PostgreSQL）

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

#### 5.2 应用服务范例

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

### 步骤 6: 添加说明文档

```yaml
spec:
    readme: |
      # ServiceName

      服务简介

      ## 使用方式
      - 打开 `https://${PUBLIC_DOMAIN}`
      - 使用默认凭证登录

      ## 配置选项
      - `ENV_VAR_1`: 说明
      - `ENV_VAR_2`: 说明

      ## 文档
      - 官方文档: https://example.com/docs
      - GitHub: https://github.com/example/repo
```

### 步骤 7: 添加多语言支持

```yaml
localization:
    zh-TW:
        description: |
          服务的繁体中文描述
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
          # 服务名称

          繁体中文说明...

    zh-CN:
        description: |
          服务的简体中文描述
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
          # 服务名称

          简体中文说明...
```

## 最佳实践

### 1. 命名规范

- **文件命名**: `zeabur-template-{service-name}.yaml`
- **服务名称**: 使用小写字母，可包含连字符
- **变量命名**: 使用大写字母和下划线，如 `PUBLIC_DOMAIN`

### 2. 图片资源

- **图标**:
  - 优先使用 SVG 格式
  - 如使用位图，至少 512x512px
  - 使用官方品牌图标

- **封面图片**:
  - 建议尺寸: 1200x630px
  - 格式: WebP（较小文件大小）
  - 存放位置: GitHub 仓库的 `screenshot.webp`

### 3. 环境变量设计

```yaml
env:
    # 自动生成的变量（expose: true, readonly: true）
    SERVICE_HOST:
        default: ${CONTAINER_HOSTNAME}
        expose: true
        readonly: true

    # 用户可修改的变量
    CUSTOM_CONFIG:
        default: "default-value"
        expose: true

    # 内部使用的变量（不暴露）
    INTERNAL_VAR:
        default: "internal-value"
```

**⚠️ 重要：域名 URL 设置**

当服务需要知道自己的公开 URL 时，不要直接使用 `${PUBLIC_DOMAIN}`：

```yaml
# ❌ 错误做法
env:
    APP_URL:
        default: https://${PUBLIC_DOMAIN}  # 如果用户输入 "myapp"，会变成 https://myapp

# ✅ 正确做法
env:
    APP_URL:
        default: ${ZEABUR_WEB_URL}  # Zeabur 自动提供完整 URL，如 https://myapp.zeabur.app
        readonly: true
```

### 4. 依赖管理

使用 `dependencies` 确保服务启动顺序：

```yaml
services:
  - name: database
    # ... 数据库配置

  - name: cache
    # ... 缓存配置

  - name: app
    dependencies:
      - database
      - cache
    # ... 应用配置
```

### 5. 健康检查（适用于数据库等）

```yaml
# 注意: Zeabur 模板 schema 不直接支持 healthcheck
# 但可以在 init 阶段使用等待脚本
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

### 6. 初始化脚本

```yaml
spec:
  init:
    - id: init-db
      command:
      - /bin/bash
      - -c
      - |
        if [ ! -f /var/lib/app/.initialized ]; then
          # 执行初始化逻辑
          touch /var/lib/app/.initialized
        fi
```

## 多语言支持

### 支持的语言代码

- `en-US`: 英文（默认，不需要在 localization 中定义）
- `zh-TW`: 繁体中文
- `zh-CN`: 简体中文
- `ja-JP`: 日文
- `es-ES`: 西班牙文

### 可本地化的字段

1. **description**: 模板描述
2. **coverImage**: 封面图片（可为不同语言使用不同图片）
3. **variables**: 变量的名称和描述
4. **readme**: README 文档

### 翻译要点

#### 繁体中文 vs 简体中文术语对照

| 英文 | 繁体中文 | 简体中文 |
|------|---------|---------|
| Server | 伺服器 | 服务器 |
| Database | 資料庫 | 数据库 |
| Configuration | 配置/設定 | 配置 |
| Connection | 連線 | 连接 |
| Domain | 網域 | 域名 |
| Authentication | 身份驗證 | 身份验证 |
| Middleware | 中介層 | 中间层 |
| Documentation | 文件 | 文档 |

## 测试与验证

### 1. Schema 验证

在 VS Code 中，第一行的 schema 注释会自动启用验证：

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
```

### 2. 必要检查清单

- [ ] 所有必要字段已填写
- [ ] 图标和封面图片 URL 可访问
- [ ] 环境变量正确配置
- [ ] 依赖关系正确设置
- [ ] README 包含使用说明
- [ ] 多语言翻译完整且正确
- [ ] 变量的默认值合理

### 3. 本地测试

使用 Docker Compose 进行本地测试：

```bash
# 转换 Zeabur 模板为 Docker Compose（手动）
# 确认服务可以正常启动
docker-compose up
```

### 4. 使用 Zeabur CLI

```bash
# 使用 npx 执行 Zeabur CLI（不需要全局安装）
npx zeabur@latest auth login

# 部署测试
npx zeabur@latest template deploy zeabur-template-{service-name}.yaml
```

## 常见问题

### Q: 如何处理敏感信息？

使用 Zeabur 的密码生成功能：

```yaml
env:
    SECRET_KEY:
        default: ${PASSWORD}  # 自动生成安全密码
        expose: true
```

### Q: 如何让服务等待数据库就绪？

使用 `init` 阶段的等待脚本或在应用程序中实现重试逻辑。

### Q: PUBLIC_DOMAIN 变量与应用程序 URL 设置的差异？

这是一个常见的混淆点：

**问题场景：**
- 用户在 `PUBLIC_DOMAIN` 变量输入：`myapp`
- Zeabur 自动绑定为：`myapp.zeabur.app`
- 但 `${PUBLIC_DOMAIN}` 变量值仍是：`myapp`
- 如果设置 `APP_URL: https://${PUBLIC_DOMAIN}`，会变成 `https://myapp` ❌

**解决方案：**

```yaml
variables:
  # 这个变量用于让 Zeabur 绑定域名
  - key: PUBLIC_DOMAIN
    type: DOMAIN
    name: Domain
    description: What domain do you want to bind to?

services:
  - name: app
    domainKey: PUBLIC_DOMAIN  # 绑定域名
    spec:
      env:
        # 应用程序内部使用完整 URL
        APP_URL:
          default: ${ZEABUR_WEB_URL}  # ✅ 使用 Zeabur 内建变量
          readonly: true
        NEXT_PUBLIC_APP_URL:
          default: ${ZEABUR_WEB_URL}  # ✅ 完整 URL，包含协议
          readonly: true
```

**重点说明：**
- `PUBLIC_DOMAIN`：给用户填写的变量，用于域名绑定
- `${ZEABUR_WEB_URL}`：Zeabur 自动提供的完整 URL（包含 https:// 和完整域名）
- 不要在应用程序 URL 设置中直接使用 `${PUBLIC_DOMAIN}`

### Q: 如何处理多个域名？

使用数组形式的 `domainKey`：

```yaml
domainKey:
  - port: web
    variable: FRONTEND_DOMAIN
  - port: api
    variable: API_DOMAIN
```

### Q: 图标去哪里找？

1. 服务官方网站
2. GitHub 仓库
3. [zeabur/service-icons](https://github.com/zeabur/service-icons)
4. [Simple Icons](https://simpleicons.org/)

## 范例参考

本仓库中的范例模板：

- **Odoo**: 完整的 ERP 系统，包含 PostgreSQL
  - 文件: `odoo/zeabur-template-odoo.yaml`
  - 特点: 自定义配置、初始化脚本

- **FossFLOW**: PWA 绘图应用
  - 文件: `FossFLOW/zeabur-template-fossflow.yaml`
  - 特点: 单一服务、持久化存储

- **MetaMCP**: MCP 聚合器
  - 文件: `MetaMCP/zeabur-template-metamcp.yaml`
  - 特点: 双服务依赖、完整多语言

## 进阶主题

### 自定义配置文件

使用 `configs` 注入配置文件：

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
      envsubst: true  # 启用环境变量替换
```

### 多端口服务

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

### 资源使用量提示

```yaml
spec:
  resourceUsage:
    cpu: 0.5      # vCPU
    memory: 1024  # MiB
```

## Zeabur 内建变量参考

编写模板时可以使用以下 Zeabur 提供的内建变量。完整的变量列表请参考[官方文档](https://zeabur.com/docs/zh-CN/deploy/variables)。

### 特殊变量（Special Variables）

这些变量由 Zeabur 自动提供，具有特殊意义：

| 变量名称 | 说明 | 范例 | 用途 |
|---------|------|------|------|
| `${ZEABUR_WEB_URL}` | 服务 web 端口的完整公开 URL | `https://myapp.zeabur.app` | Git 部署的服务，端口名称固定为 `web` |
| `${ZEABUR_[PORTNAME]_URL}` | 指定端口的完整 URL | `https://api.myapp.zeabur.app` | 多端口服务，替换 `[PORTNAME]` 为实际端口名称 |
| `${ZEABUR_WEB_DOMAIN}` | 服务 web 端口的域名 | `myapp.zeabur.app` | 不含协议的域名 |
| `${ZEABUR_[PORTNAME]_DOMAIN}` | 指定端口的域名 | `api.myapp.zeabur.app` | 不含协议的域名 |
| `${CONTAINER_HOSTNAME}` | 当前服务在项目中的主机名称 | `postgresql-abc123` | 用于服务间内部通信 |

**详细说明：**
- `ZEABUR_WEB_URL` 是最常用的变量，对应到你在「域名」设置中绑定的 URL
- 对于 Git 仓库部署的服务，端口名称永远是 `web`，所以使用 `${ZEABUR_WEB_URL}`
- 对于 Prebuilt 服务，端口名称由 `spec.ports[].id` 定义

### 端口相关

| 变量名称 | 说明 | 范例 |
|---------|------|------|
| `${PORT}` | 服务默认监听的端口号 | `8080` |
| `${[PORTNAME]_PORT}` | 指定端口的端口值 | `${WEB_PORT}` → `3000` |

### 数据库相关（PostgreSQL 范例）

Zeabur 的数据库服务会自动暴露以下变量：

| 变量名称 | 说明 |
|---------|------|
| `${POSTGRES_HOST}` | PostgreSQL 主机名称 |
| `${POSTGRES_PORT}` | PostgreSQL 端口号 |
| `${POSTGRES_USERNAME}` | PostgreSQL 用户名 |
| `${POSTGRES_PASSWORD}` | PostgreSQL 密码 |
| `${POSTGRES_DATABASE}` | PostgreSQL 数据库名称 |
| `${POSTGRES_CONNECTION_STRING}` | PostgreSQL 完整连接字符串 |
| `${POSTGRES_URI}` | PostgreSQL URI（同 CONNECTION_STRING） |

**注意：** 其他数据库（MySQL、MongoDB、Redis 等）也有类似的变量格式。

### 端口转发相关

当使用端口转发功能时可用：

| 变量名称 | 说明 |
|---------|------|
| `${PORT_FORWARDED_HOSTNAME}` | 端口转发的主机名称 |
| `${[PORTNAME]_PORT_FORWARDED_PORT}` | 端口转发的端口号 |
| `${DATABASE_PORT_FORWARDED_PORT}` | 数据库端口转发的端口号 |

### 密码生成

| 变量名称 | 说明 |
|---------|------|
| `${PASSWORD}` | Zeabur 自动生成的安全随机密码 |

**使用建议：**
- ✅ 应用程序需要知道自己的公开 URL → 使用 `${ZEABUR_WEB_URL}`
- ✅ 服务间内部通信 → 使用 `${CONTAINER_HOSTNAME}`
- ✅ 需要安全密码 → 使用 `${PASSWORD}`
- ❌ 不要在应用程序 URL 中直接使用 `${PUBLIC_DOMAIN}`（用户变量）

### 变量参考顺序

在模板中引用变量时，Zeabur 会按以下顺序解析：

1. 用户在模板中定义的变量（如 `PUBLIC_DOMAIN`）
2. 服务暴露的环境变量（`expose: true`）
3. Zeabur 特殊变量（如 `${ZEABUR_WEB_URL}`）
4. 系统内建变量（如 `${PASSWORD}`）

更多信息请参考：
- [特殊变量文档](https://zeabur.com/docs/zh-CN/deploy/special-variables)
- [环境变量设置](https://zeabur.com/docs/zh-CN/deploy/variables)

## 参考资源

- [Zeabur 官方文档](https://zeabur.com/docs)
- [Template Schema](https://schema.zeabur.app/template.json)
- [Prebuilt Service Schema](https://schema.zeabur.app/prebuilt.json)
- [模板仓库](https://github.com/zeabur/zeabur)
- [从 YAML 创建模板](https://zeabur.com/docs/zh-CN/template/template-in-code)

## 贡献指南

1. Fork 本仓库
2. 创建新的服务目录
3. 编写模板文件
4. 准备截图
5. 提交 Pull Request

### PR 检查清单

- [ ] 模板通过 schema 验证
- [ ] 包含英文、繁体中文、简体中文翻译
- [ ] 提供截图（screenshot.webp）
- [ ] README 说明完整
- [ ] 已在 Zeabur 平台测试部署

## 授权

MIT License
