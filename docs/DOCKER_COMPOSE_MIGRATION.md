# Docker Compose 轉換 Zeabur 模板指南

本指南專門幫助已有 `docker-compose.yml` 的用戶快速轉換成 Zeabur 模板。

## 目錄

- [快速對比](#快速對比)
- [欄位映射](#欄位映射)
- [轉換步驟](#轉換步驟)
- [實際範例](#實際範例)
- [常見場景](#常見場景)
- [轉換檢查清單](#轉換檢查清單)

---

## 快速對比

### Docker Compose vs Zeabur 模板

| 功能 | Docker Compose | Zeabur 模板 |
|------|---------------|-------------|
| 格式 | YAML | YAML |
| 服務定義 | `services` | `spec.services` |
| 映像 | `image` | `spec.source.image` |
| 埠號 | `ports` | `spec.ports` |
| 環境變數 | `environment` | `spec.env` |
| 資料卷 | `volumes` | `spec.volumes` |
| 依賴 | `depends_on` | `dependencies` |
| 啟動指令 | `command` | `spec.command` |
| 健康檢查 | `healthcheck` | 不直接支援，使用 `init` |

### 主要差異

#### 1. 結構層級

```yaml
# Docker Compose
services:
  app:
    image: myapp:latest

# Zeabur
spec:
  services:
    - name: app
      spec:
        source:
          image: myapp:latest
```

#### 2. 環境變數

```yaml
# Docker Compose
environment:
  DATABASE_URL: ${DATABASE_URL}

# Zeabur
env:
  DATABASE_URL:
    default: ${DATABASE_URL}
    expose: true
```

#### 3. 埠號

```yaml
# Docker Compose
ports:
  - "3000:3000"

# Zeabur
ports:
  - id: web
    port: 3000
    type: HTTP
```

---

## 欄位映射

### 基本欄位

| Docker Compose | Zeabur 模板 | 說明 |
|----------------|-------------|------|
| `services.{name}` | `spec.services[].name` | 服務名稱 |
| `image` | `spec.source.image` | Docker 映像 |
| `ports` | `spec.ports[]` | 埠號定義 |
| `environment` | `spec.env` | 環境變數 |
| `volumes` | `spec.volumes[]` | 資料卷 |
| `depends_on` | `dependencies[]` | 依賴服務 |
| `command` | `spec.command[]` | 啟動指令 |
| `restart` | N/A | Zeabur 自動處理重啟 |

### 環境變數映射

| Docker Compose | Zeabur 模板 |
|----------------|-------------|
| `KEY: value` | `KEY:\n  default: value` |
| `KEY: ${VAR}` | `KEY:\n  default: ${VAR}` |
| N/A | `expose: true` (新增：暴露給其他服務) |
| N/A | `readonly: true` (新增：唯讀) |

### 埠號映射

| Docker Compose | Zeabur 模板 |
|----------------|-------------|
| `"8080:8080"` | `- id: web\n  port: 8080\n  type: HTTP` |
| `"5432:5432"` | `- id: database\n  port: 5432\n  type: TCP` |

### 資料卷映射

| Docker Compose | Zeabur 模板 |
|----------------|-------------|
| `db-data:/var/lib/postgresql/data` | `- id: data\n  dir: /var/lib/postgresql/data` |
| `./config:/app/config` | 使用 `configs` 注入 |

---

## 轉換步驟

### 步驟 1: 準備 Docker Compose 檔案

確保你的 `docker-compose.yml` 可以正常運行：

```bash
# 測試 Docker Compose
docker-compose up
```

### 步驟 2: 建立 Zeabur 模板檔案

```bash
# 建立服務目錄
mkdir my-service
cd my-service

# 建立模板檔案
touch zeabur-template-my-service.yaml
```

### 步驟 3: 加入基本結構

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
apiVersion: zeabur.com/v1
kind: Template
metadata:
    name: MyService
spec:
    description: |
      Description of your service
    icon: https://example.com/icon.svg
    tags:
      - Category
    variables: []
    services: []
```

### 步驟 4: 轉換服務定義

逐一轉換每個服務：

#### Docker Compose 範例
```yaml
services:
  db:
    image: postgres:16
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${DB_PASSWORD:-postgres}
      POSTGRES_DB: mydb
    volumes:
      - db-data:/var/lib/postgresql/data
```

#### 轉換後的 Zeabur 模板
```yaml
services:
  - name: db
    icon: https://example.com/postgres-icon.svg
    template: PREBUILT_V2
    spec:
      source:
        image: postgres:16

      ports:
        - id: database
          port: 5432
          type: TCP

      volumes:
        - id: data
          dir: /var/lib/postgresql/data

      env:
        POSTGRES_USER:
          default: postgres
          expose: true

        POSTGRES_PASSWORD:
          default: ${PASSWORD}  # Zeabur 自動生成
          expose: true

        POSTGRES_DB:
          default: mydb
          expose: true

        # 新增：暴露連接資訊
        POSTGRES_HOST:
          default: ${CONTAINER_HOSTNAME}
          expose: true
          readonly: true

        POSTGRES_PORT:
          default: ${DATABASE_PORT}
          expose: true
          readonly: true
```

### 步驟 5: 處理依賴關係

#### Docker Compose
```yaml
services:
  app:
    depends_on:
      - db
      - redis
```

#### Zeabur 模板
```yaml
services:
  - name: app
    dependencies:
      - db
      - redis
```

### 步驟 6: 處理環境變數引用

#### Docker Compose
```yaml
services:
  app:
    environment:
      DATABASE_URL: postgres://user:pass@db:5432/mydb
      REDIS_URL: redis://redis:6379
```

#### Zeabur 模板
```yaml
services:
  - name: app
    dependencies:
      - db
      - redis
    spec:
      env:
        DATABASE_URL:
          default: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
          readonly: true

        REDIS_URL:
          default: redis://${REDIS_HOST}:${REDIS_PORT}
          readonly: true
```

### 步驟 7: 測試部署

```bash
# 部署到 Zeabur
npx zeabur@latest template deploy zeabur-template-my-service.yaml

# 確認所有服務正常啟動
# 測試服務功能
```

---

## 實際範例

### 範例 1: PostgreSQL

#### Docker Compose
```yaml
services:
  db:
    image: postgres:16
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: mydb
    volumes:
      - db-data:/var/lib/postgresql/data
    restart: always

volumes:
  db-data:
```

#### Zeabur 模板
```yaml
services:
  - name: postgresql
    icon: https://raw.githubusercontent.com/zeabur/service-icons/main/marketplace/postgresql.svg
    template: PREBUILT_V2
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
        POSTGRES_USER:
          default: postgres
          expose: true

        POSTGRES_PASSWORD:
          default: ${PASSWORD}
          expose: true

        POSTGRES_DB:
          default: mydb
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

### 範例 2: Redis

#### Docker Compose
```yaml
services:
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      - redis-data:/data
    restart: always

volumes:
  redis-data:
```

#### Zeabur 模板
```yaml
services:
  - name: redis
    icon: https://raw.githubusercontent.com/zeabur/service-icons/main/marketplace/redis.svg
    template: PREBUILT_V2
    spec:
      source:
        image: redis:alpine

      ports:
        - id: database
          port: 6379
          type: TCP

      volumes:
        - id: data
          dir: /data

      command:
        - redis-server
        - --appendonly
        - "yes"

      env:
        REDIS_HOST:
          default: ${CONTAINER_HOSTNAME}
          expose: true
          readonly: true

        REDIS_PORT:
          default: ${DATABASE_PORT}
          expose: true
          readonly: true
```

### 範例 3: Twenty CRM（多服務）

基於實際的 Twenty CRM docker-compose.yml。

#### Docker Compose（簡化版）
```yaml
services:
  server:
    image: twentycrm/twenty:latest
    ports:
      - "3000:3000"
    environment:
      PG_DATABASE_URL: postgres://postgres:postgres@db:5432/default
      REDIS_URL: redis://redis:6379
      SERVER_URL: ${SERVER_URL}
      APP_SECRET: ${APP_SECRET}
    volumes:
      - server-data:/app/.local-storage
    depends_on:
      - db
      - redis

  worker:
    image: twentycrm/twenty:latest
    command: ["yarn", "worker:prod"]
    environment:
      PG_DATABASE_URL: postgres://postgres:postgres@db:5432/default
      REDIS_URL: redis://redis:6379
      DISABLE_DB_MIGRATIONS: "true"
    volumes:
      - server-data:/app/.local-storage
    depends_on:
      - db
      - server

  db:
    image: postgres:16
    environment:
      POSTGRES_DB: default
      POSTGRES_PASSWORD: postgres
      POSTGRES_USER: postgres
    volumes:
      - db-data:/var/lib/postgresql/data

  redis:
    image: redis
    command: ["--maxmemory-policy", "noeviction"]

volumes:
  db-data:
  server-data:
```

#### Zeabur 模板
```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
apiVersion: zeabur.com/v1
kind: Template
metadata:
    name: TwentyCRM
spec:
    description: |
      Twenty CRM - Modern CRM platform built with TypeScript
    icon: https://example.com/twenty-icon.svg
    tags:
      - CRM
    variables:
      - key: PUBLIC_DOMAIN
        type: DOMAIN
        name: Domain
        description: What domain do you want to bind to?
    services:
      # PostgreSQL 資料庫
      - name: db
        icon: https://raw.githubusercontent.com/zeabur/service-icons/main/marketplace/postgresql.svg
        template: PREBUILT_V2
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
            POSTGRES_USER:
              default: postgres
              expose: true
            POSTGRES_PASSWORD:
              default: ${PASSWORD}
              expose: true
            POSTGRES_DB:
              default: default
              expose: true
            POSTGRES_HOST:
              default: ${CONTAINER_HOSTNAME}
              expose: true
              readonly: true
            POSTGRES_PORT:
              default: ${DATABASE_PORT}
              expose: true
              readonly: true

      # Redis 快取
      - name: redis
        icon: https://raw.githubusercontent.com/zeabur/service-icons/main/marketplace/redis.svg
        template: PREBUILT_V2
        spec:
          source:
            image: redis:alpine
          ports:
            - id: database
              port: 6379
              type: TCP
          command:
            - redis-server
            - --maxmemory-policy
            - noeviction
          env:
            REDIS_HOST:
              default: ${CONTAINER_HOSTNAME}
              expose: true
              readonly: true
            REDIS_PORT:
              default: ${DATABASE_PORT}
              expose: true
              readonly: true

      # Server 服務
      - name: server
        icon: https://example.com/twenty-icon.svg
        template: PREBUILT_V2
        domainKey: PUBLIC_DOMAIN
        dependencies:
          - db
          - redis
        spec:
          source:
            image: twentycrm/twenty:latest
          ports:
            - id: web
              port: 3000
              type: HTTP
          volumes:
            - id: data
              dir: /app/packages/twenty-server/.local-storage
          env:
            NODE_PORT:
              default: "3000"

            PG_DATABASE_URL:
              default: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
              readonly: true

            REDIS_URL:
              default: redis://${REDIS_HOST}:${REDIS_PORT}
              readonly: true

            SERVER_URL:
              default: ${ZEABUR_WEB_URL}
              readonly: true

            APP_SECRET:
              default: ${PASSWORD}
              expose: true

      # Worker 服務
      - name: worker
        icon: https://example.com/twenty-icon.svg
        template: PREBUILT_V2
        dependencies:
          - db
          - server
        spec:
          source:
            image: twentycrm/twenty:latest
          command:
            - yarn
            - worker:prod
          volumes:
            - id: data
              dir: /app/packages/twenty-server/.local-storage
          env:
            PG_DATABASE_URL:
              default: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
              readonly: true

            REDIS_URL:
              default: redis://${REDIS_HOST}:${REDIS_PORT}
              readonly: true

            SERVER_URL:
              default: ${ZEABUR_WEB_URL}
              readonly: true

            DISABLE_DB_MIGRATIONS:
              default: "true"

            DISABLE_CRON_JOBS_REGISTRATION:
              default: "true"

            APP_SECRET:
              default: ${APP_SECRET}
              readonly: true
```

---

## 常見場景

### 場景 1: 共享 Volume

#### Docker Compose
```yaml
services:
  app1:
    volumes:
      - shared-data:/data
  app2:
    volumes:
      - shared-data:/data

volumes:
  shared-data:
```

#### Zeabur 處理方式

Zeabur 不直接支援共享 Volume。替代方案：

**方案 1：使用 Object Storage（推薦）**
```yaml
env:
  S3_BUCKET:
    default: my-bucket
  S3_REGION:
    default: us-east-1
```

**方案 2：將資料存在主服務，其他服務透過 API 存取**
```yaml
services:
  - name: primary-service
    volumes:
      - id: data
        dir: /data

  - name: secondary-service
    env:
      PRIMARY_API:
        default: http://${PRIMARY_SERVICE_HOST}:${PRIMARY_SERVICE_PORT}
```

### 場景 2: 健康檢查

#### Docker Compose
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

#### Zeabur 處理方式

使用 `init` 階段等待服務就緒：

```yaml
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

### 場景 3: 自訂網路

#### Docker Compose
```yaml
services:
  app:
    networks:
      - frontend
      - backend

networks:
  frontend:
  backend:
```

#### Zeabur 處理方式

Zeabur 自動處理網路，服務可以透過 `${CONTAINER_HOSTNAME}` 互相通訊。

無需手動配置網路。

### 場景 4: 建構映像

#### Docker Compose
```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
```

#### Zeabur 處理方式

**方案 1：使用預先建構的映像（推薦）**
```yaml
spec:
  source:
    image: myregistry/myapp:1.0.0
```

**方案 2：使用 Git 倉庫（Zeabur 自動建構）**
```yaml
spec:
  source:
    repository: https://github.com/username/repo
    branch: main
```

### 場景 5: 配置檔案

#### Docker Compose
```yaml
services:
  app:
    volumes:
      - ./config.yml:/app/config.yml
```

#### Zeabur 處理方式

使用 `configs` 注入檔案：

```yaml
spec:
  configs:
    - path: /app/config.yml
      template: |
        server:
          host: 0.0.0.0
          port: ${PORT}
        database:
          url: ${DATABASE_URL}
      envsubst: true
```

---

## 轉換檢查清單

### 準備階段
- [ ] Docker Compose 可以正常運行
- [ ] 已列出所有服務
- [ ] 已確認服務間的依賴關係
- [ ] 已確認所有環境變數

### 轉換階段
- [ ] 已建立 Zeabur 模板檔案
- [ ] 已加入 schema 註解
- [ ] 所有服務都已轉換
- [ ] 所有環境變數都已轉換
- [ ] 埠號都已正確定義
- [ ] Volume 都已正確定義
- [ ] 依賴關係都已設定

### 環境變數處理
- [ ] 密碼使用 `${PASSWORD}` 自動生成
- [ ] 連接資訊使用 `${CONTAINER_HOSTNAME}` 和 `${PORT}`
- [ ] URL 使用 `${ZEABUR_WEB_URL}`，不是 `${PUBLIC_DOMAIN}`
- [ ] 需要暴露的變數設為 `expose: true`
- [ ] 唯讀變數設為 `readonly: true`

### 測試階段
- [ ] 本地 Schema 驗證通過
- [ ] 已部署到 Zeabur 測試
- [ ] 所有服務正常啟動
- [ ] 服務間連接正常
- [ ] 環境變數正確
- [ ] 資料持久化正常

### 優化階段
- [ ] 已添加服務圖示
- [ ] 已添加模板封面
- [ ] 已撰寫 README
- [ ] 已添加多語系支援

---

## 轉換技巧

### 1. 分階段轉換

```bash
# 階段 1: 只轉換資料庫
# 測試資料庫服務

# 階段 2: 加入快取
# 測試資料庫 + 快取

# 階段 3: 加入應用
# 測試完整堆疊
```

### 2. 環境變數映射表

建立映射表記錄轉換：

| Docker Compose | Zeabur | 來源 |
|----------------|--------|------|
| `DATABASE_URL` | `${POSTGRES_CONNECTION_STRING}` | db 服務暴露 |
| `REDIS_URL` | `redis://${REDIS_HOST}:${REDIS_PORT}` | redis 服務暴露 |
| `APP_URL` | `${ZEABUR_WEB_URL}` | Zeabur 提供 |

### 3. 使用註解

在轉換時加入註解，說明轉換邏輯：

```yaml
env:
  # 從 docker-compose.yml 的 DATABASE_URL 轉換而來
  # 原始: postgres://user:pass@db:5432/mydb
  DATABASE_URL:
    default: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
    readonly: true
```

---

## 常見轉換錯誤

### 錯誤 1: 埠號格式錯誤

❌ **Docker Compose 格式直接複製**
```yaml
ports:
  - "3000:3000"  # 這是 Docker Compose 格式
```

✅ **正確的 Zeabur 格式**
```yaml
ports:
  - id: web
    port: 3000
    type: HTTP
```

### 錯誤 2: 環境變數格式錯誤

❌ **Docker Compose 格式**
```yaml
env:
  DATABASE_URL: ${DATABASE_URL}  # 缺少 default
```

✅ **Zeabur 格式**
```yaml
env:
  DATABASE_URL:
    default: ${DATABASE_URL}
```

### 錯誤 3: Volume 名稱衝突

❌ **多個服務使用相同 Volume ID**
```yaml
services:
  - name: app1
    spec:
      volumes:
        - id: data  # 相同 ID
  - name: app2
    spec:
      volumes:
        - id: data  # 相同 ID，會衝突
```

✅ **使用不同 ID**
```yaml
services:
  - name: app1
    spec:
      volumes:
        - id: app1-data
  - name: app2
    spec:
      volumes:
        - id: app2-data
```

### 錯誤 4: 忘記設定依賴

❌ **沒有 dependencies**
```yaml
services:
  - name: app
    spec:
      env:
        DATABASE_URL:
          default: ${POSTGRES_HOST}  # POSTGRES_HOST 未定義
```

✅ **加上 dependencies**
```yaml
services:
  - name: app
    dependencies:
      - postgresql  # 必須加上
    spec:
      env:
        DATABASE_URL:
          default: ${POSTGRES_HOST}
```

---

## 進階主題

### 使用 Docker Compose 中的 extends

Docker Compose 的 `extends` 不直接支援，改用 YAML 錨點：

```yaml
# 定義共用配置
x-common-env: &common-env
  env:
    APP_SECRET:
      default: ${PASSWORD}
      expose: true

# 使用共用配置
services:
  - name: server
    spec:
      <<: *common-env
      # ... 其他配置

  - name: worker
    spec:
      <<: *common-env
      # ... 其他配置
```

### 處理敏感資訊

Docker Compose 的 `secrets` 在 Zeabur 中：

```yaml
# Docker Compose
secrets:
  db_password:
    file: ./secrets/db_password.txt

# Zeabur - 使用自動生成密碼
env:
  DB_PASSWORD:
    default: ${PASSWORD}  # Zeabur 自動生成
    expose: true
```

---

## 參考資源

- [完整製作指南](GUIDE.md) - 從零開始的詳細步驟
- [疑難排解](TROUBLESHOOTING.md) - 常見問題和解決方案
- [最佳實踐](BEST_PRACTICES.md) - 設計模式和規範
- [技術參考](REFERENCE.md) - Zeabur 內建變數和 Schema

---

**轉換完成後，別忘了測試部署！** 🚀
