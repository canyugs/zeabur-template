# Zeabur 模板技術參考

本文件提供 Zeabur 模板的完整技術參考，包含所有可用欄位、內建變數和進階功能。

## 目錄

- [模板結構](#模板結構)
- [Zeabur 內建變數](#zeabur-內建變數)
- [欄位參考](#欄位參考)
- [進階功能](#進階功能)

---

## 模板結構

### 完整結構範例

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
apiVersion: zeabur.com/v1
kind: Template
metadata:
  name: ServiceName
spec:
  description: |
    Service description
  icon: https://example.com/icon.svg
  coverImage: https://example.com/cover.webp
  tags:
    - Category
  variables:
    - key: VARIABLE_NAME
      type: STRING|DOMAIN
      name: Display Name
      description: Description
  readme: |
    # README content
  resourceUsage:
    cpu: 0.5
    memory: 512
  services:
    - name: service-name
      icon: https://example.com/icon.svg
      template: PREBUILT_V2
      domainKey: VARIABLE_NAME
      dependencies:
        - other-service
      spec:
        source:
          image: image:tag
        ports:
          - id: port-id
            port: 8080
            type: HTTP|TCP
        volumes:
          - id: volume-id
            dir: /path/in/container
        configs:
          - path: /path/to/config
            template: |
              config content
            envsubst: true
        init:
          - id: init-id
            command:
              - /bin/bash
              - -c
              - script
        command:
          - command
          - args
        env:
          ENV_VAR:
            default: value
            expose: true
            readonly: true
localization:
  zh-TW:
    description: |
      繁體中文描述
    # coverImage: https://example.com/cover-zh-TW.webp  # 可選，必須是完整 URL
    variables:
      - key: VARIABLE_NAME
        name: 顯示名稱
        description: 描述
    readme: |
      # 繁體中文 README
  zh-CN:
    # 簡體中文內容
```

---

## Zeabur 內建變數

Zeabur 提供了一系列內建變數，可在模板中使用。

### 特殊變數（Special Variables）

這些變數由 Zeabur 自動提供，具有特殊意義：

| 變數名稱 | 說明 | 範例 | 用途 |
|---------|------|------|------|
| `${ZEABUR_WEB_URL}` | 服務 web 埠的完整公開 URL | `https://myapp.zeabur.app` | Git 部署的服務，埠名稱固定為 `web` |
| `${ZEABUR_[PORTNAME]_URL}` | 指定埠號的完整 URL | `https://api.myapp.zeabur.app` | 多埠號服務，替換 `[PORTNAME]` 為實際埠號名稱 |
| `${ZEABUR_WEB_DOMAIN}` | 服務 web 埠的網域名稱 | `myapp.zeabur.app` | 不含協定的網域名稱 |
| `${ZEABUR_[PORTNAME]_DOMAIN}` | 指定埠號的網域名稱 | `api.myapp.zeabur.app` | 不含協定的網域名稱 |
| `${CONTAINER_HOSTNAME}` | 當前服務在專案中的主機名稱 | `postgresql-abc123` | 用於服務間內部通訊 |

**詳細說明：**
- `ZEABUR_WEB_URL` 是最常用的變數，對應到你在「網域」設定中綁定的 URL
- 對於 Git 倉庫部署的服務，埠名稱永遠是 `web`，所以使用 `${ZEABUR_WEB_URL}`
- 對於 Prebuilt 服務，埠名稱由 `spec.ports[].id` 定義

**使用範例：**

```yaml
services:
  - name: app
    spec:
      ports:
        - id: web
          port: 8080
          type: HTTP
        - id: api
          port: 3000
          type: HTTP
      env:
        # web 埠的完整 URL
        APP_URL:
          default: ${ZEABUR_WEB_URL}
          readonly: true

        # api 埠的完整 URL
        API_URL:
          default: ${ZEABUR_API_URL}
          readonly: true

        # 只需要網域（不含 https://）
        DOMAIN:
          default: ${ZEABUR_WEB_DOMAIN}
          readonly: true
```

### 埠號相關變數

| 變數名稱 | 說明 | 範例 |
|---------|------|------|
| `${PORT}` | 服務預設監聽的埠號 | `8080` |
| `${[PORTNAME]_PORT}` | 指定埠號的埠號值 | `${WEB_PORT}` → `3000` |

**使用範例：**

```yaml
spec:
  ports:
    - id: web
      port: 8080
      type: HTTP

  env:
    # 告訴應用程式監聽這個埠號
    PORT:
      default: "8080"

    # 或使用 Zeabur 提供的變數
    APP_PORT:
      default: ${PORT}
```

### 資料庫相關變數

Zeabur 的資料庫服務會自動暴露以下變數（以 PostgreSQL 為例）：

| 變數名稱 | 說明 |
|---------|------|
| `${POSTGRES_HOST}` | PostgreSQL 主機名稱 |
| `${POSTGRES_PORT}` | PostgreSQL 埠號 |
| `${POSTGRES_USERNAME}` | PostgreSQL 使用者名稱 |
| `${POSTGRES_PASSWORD}` | PostgreSQL 密碼 |
| `${POSTGRES_DATABASE}` | PostgreSQL 資料庫名稱 |
| `${POSTGRES_CONNECTION_STRING}` | PostgreSQL 完整連線字串 |
| `${POSTGRES_URI}` | PostgreSQL URI（同 CONNECTION_STRING） |

**注意：** 其他資料庫（MySQL、MongoDB、Redis 等）也有類似的變數格式：

- MySQL: `MYSQL_HOST`, `MYSQL_PORT`, etc.
- MongoDB: `MONGODB_HOST`, `MONGODB_PORT`, etc.
- Redis: `REDIS_HOST`, `REDIS_PORT`, etc.

**使用範例：**

```yaml
services:
  - name: postgresql
    spec:
      env:
        # 暴露這些變數供其他服務使用
        POSTGRES_HOST:
          default: ${CONTAINER_HOSTNAME}
          expose: true
          readonly: true

        POSTGRES_PORT:
          default: ${DATABASE_PORT}
          expose: true
          readonly: true

  - name: app
    dependencies:
      - postgresql
    spec:
      env:
        # 使用資料庫變數
        DATABASE_URL:
          default: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
          readonly: true
```

### 密碼生成

| 變數名稱 | 說明 |
|---------|------|
| `${PASSWORD}` | Zeabur 自動生成的安全隨機密碼 |

**使用範例：**

```yaml
env:
  ADMIN_PASSWORD:
    default: ${PASSWORD}  # 自動生成安全密碼
    expose: true

  DATABASE_PASSWORD:
    default: ${PASSWORD}  # 每個 ${PASSWORD} 都會生成不同的密碼
    expose: true
```

### 埠號轉發相關

當使用埠號轉發功能時可用：

| 變數名稱 | 說明 |
|---------|------|
| `${PORT_FORWARDED_HOSTNAME}` | 埠號轉發的主機名稱 |
| `${[PORTNAME]_PORT_FORWARDED_PORT}` | 埠號轉發的埠號 |
| `${DATABASE_PORT_FORWARDED_PORT}` | 資料庫埠號轉發的埠號 |

### 變數參考順序

在模板中引用變數時，Zeabur 會按以下順序解析：

1. 使用者在模板中定義的變數（如 `PUBLIC_DOMAIN`）
2. 服務暴露的環境變數（`expose: true`）
3. Zeabur 特殊變數（如 `${ZEABUR_WEB_URL}`）
4. 系統內建變數（如 `${PASSWORD}`）

### 常見用法

#### URL 設定

```yaml
# ✅ 正確：使用 Zeabur 提供的完整 URL
env:
  APP_URL:
    default: ${ZEABUR_WEB_URL}
    readonly: true

# ❌ 錯誤：使用使用者變數
env:
  APP_URL:
    default: https://${PUBLIC_DOMAIN}  # 會是 https://myapp
```

#### 服務間通訊

```yaml
# 服務 A 暴露資訊
services:
  - name: redis
    spec:
      env:
        REDIS_HOST:
          default: ${CONTAINER_HOSTNAME}
          expose: true
        REDIS_PORT:
          default: ${DATABASE_PORT}
          expose: true

# 服務 B 使用
  - name: app
    dependencies:
      - redis
    spec:
      env:
        REDIS_URL:
          default: redis://${REDIS_HOST}:${REDIS_PORT}
```

---

## 欄位參考

### metadata 區塊

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `name` | string | ✅ | 模板名稱 |

**範例：**
```yaml
metadata:
  name: PostgreSQL
```

### spec 區塊

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `description` | string | 建議 | 模板描述（支援多行） |
| `icon` | string | 建議 | 圖示 URL |
| `coverImage` | string | 選填 | 封面圖片 URL |
| `tags` | array | 建議 | 分類標籤 |
| `variables` | array | 選填 | 使用者變數 |
| `readme` | string | 建議 | README 內容（Markdown） |
| `resourceUsage` | object | 選填 | 預期資源使用量 |
| `services` | array | ✅ | 服務列表 |

### variables 欄位

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `key` | string | ✅ | 變數鍵名（大寫底線） |
| `type` | enum | ✅ | `DOMAIN` 或 `STRING` |
| `name` | string | ✅ | 顯示名稱 |
| `description` | string | ✅ | 變數描述 |

**範例：**
```yaml
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

### services 欄位

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `name` | string | ✅ | 服務名稱（小寫） |
| `icon` | string | 建議 | 服務圖示 URL |
| `template` | enum | ✅ | 固定為 `PREBUILT_V2` |
| `domainKey` | string/object | 選填 | 網域變數綁定 |
| `dependencies` | array | 選填 | 依賴的服務列表 |
| `spec` | object | ✅ | 服務規格 |

### spec.source 欄位

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `image` | string | ✅ | Docker 映像名稱和標籤 |

**範例：**
```yaml
spec:
  source:
    image: postgres:16-alpine
```

### spec.ports 欄位

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `id` | string | ✅ | 埠號識別碼 |
| `port` | number | ✅ | 埠號數字 |
| `type` | enum | ✅ | `HTTP` 或 `TCP` |

**範例：**
```yaml
ports:
  - id: web
    port: 8080
    type: HTTP
  - id: database
    port: 5432
    type: TCP
```

### spec.volumes 欄位

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `id` | string | ✅ | Volume 識別碼 |
| `dir` | string | ✅ | 容器內的掛載路徑 |

**範例：**
```yaml
volumes:
  - id: data
    dir: /var/lib/postgresql/data
```

### spec.env 欄位

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `default` | string | ✅ | 預設值（可使用變數） |
| `expose` | boolean | 選填 | 是否暴露給其他服務 |
| `readonly` | boolean | 選填 | 是否唯讀 |

**範例：**
```yaml
env:
  DATABASE_URL:
    default: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
    readonly: true

  ADMIN_PASSWORD:
    default: ${PASSWORD}
    expose: true
```

### spec.configs 欄位

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `path` | string | ✅ | 檔案路徑 |
| `template` | string | ✅ | 檔案內容 |
| `envsubst` | boolean | 選填 | 是否替換環境變數 |

**範例：**
```yaml
configs:
  - path: /app/config.yml
    template: |
      server:
        port: ${PORT}
    envsubst: true
```

### spec.init 欄位

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `id` | string | ✅ | 初始化步驟識別碼 |
| `command` | array | ✅ | 執行的指令 |

**範例：**
```yaml
init:
  - id: setup
    command:
      - /bin/bash
      - -c
      - |
        echo "Initializing..."
```

### spec.command 欄位

| 類型 | 說明 |
|------|------|
| array | 容器啟動指令 |

**⚠️ 重要：**
- `command` 必須寫在 `spec` 層級，不是 `spec.source` 內

**範例：**
```yaml
spec:
  source:
    image: myapp:latest
  command:  # ← 正確位置
    - node
    - server.js
```

### resourceUsage 欄位

| 欄位 | 類型 | 說明 | 預設 |
|------|------|------|------|
| `cpu` | number | vCPU 數量 | 0.5 |
| `memory` | number | 記憶體（MiB） | 512 |

**範例：**
```yaml
spec:
  resourceUsage:
    cpu: 1
    memory: 1024
```

---

## 進階功能

### 自訂配置檔案

使用 `configs` 注入配置檔案：

```yaml
spec:
  configs:
    - path: /etc/nginx/nginx.conf
      template: |
        server {
          listen ${PORT};
          server_name ${ZEABUR_WEB_DOMAIN};

          location / {
            proxy_pass http://localhost:3000;
          }
        }
      envsubst: true
```

### 初始化腳本

使用 `init` 執行初始化：

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

    - id: run-migrations
      command:
        - /bin/bash
        - -c
        - |
          npm run migrate
```

### 多埠號服務

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

**綁定不同網域到不同埠號：**

```yaml
variables:
  - key: FRONTEND_DOMAIN
    type: DOMAIN
  - key: API_DOMAIN
    type: DOMAIN

services:
  - name: app
    domainKey:
      - port: web
        variable: FRONTEND_DOMAIN
      - port: api
        variable: API_DOMAIN
```

### YAML 錨點（避免重複）

```yaml
# 定義共用配置
x-common-env: &common-env
  APP_SECRET:
    default: ${PASSWORD}
    expose: true
  LOG_LEVEL:
    default: info

# 重複使用
services:
  - name: server
    spec:
      env:
        <<: *common-env
        SERVER_PORT:
          default: "8080"

  - name: worker
    spec:
      env:
        <<: *common-env
        WORKER_THREADS:
          default: "4"
```

### 條件配置

雖然 Zeabur 模板不支援條件語句，但可以在 `init` 腳本中實現：

```yaml
spec:
  init:
    - id: conditional-setup
      command:
        - /bin/bash
        - -c
        - |
          if [ "${ENABLE_FEATURE}" = "true" ]; then
            echo "Feature enabled"
            # 執行特定配置
          else
            echo "Feature disabled"
          fi
```

---

## 參考連結

- [Zeabur 官方文件](https://zeabur.com/docs)
- [Template Schema](https://schema.zeabur.app/template.json)
- [Prebuilt Service Schema](https://schema.zeabur.app/prebuilt.json)
- [特殊變數文件](https://zeabur.com/docs/zh-TW/deploy/special-variables)
- [環境變數設定](https://zeabur.com/docs/zh-TW/deploy/variables)

---

**本文件持續更新，歡迎提供回饋和建議！** 📚
