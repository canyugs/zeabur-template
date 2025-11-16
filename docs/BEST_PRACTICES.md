# Zeabur 模板最佳實踐

本文件整理了 Zeabur 模板製作的最佳實踐和設計模式，幫助你建立高品質、易維護的模板。

## 目錄

- [命名規範](#命名規範)
- [環境變數設計](#環境變數設計)
- [Volume 管理](#volume-管理)
- [服務依賴管理](#服務依賴管理)
- [圖片資源管理](#圖片資源管理)
- [多語系支援](#多語系支援)
- [安全性](#安全性)
- [效能優化](#效能優化)
- [可維護性](#可維護性)
- [文件撰寫](#文件撰寫)

---

## 命名規範

### 檔案命名

✅ **推薦**
```bash
# 目錄名稱：小寫，連字號分隔
postgresql-ha/
twenty-crm/
meta-mcp/

# 檔案名稱：固定格式
zeabur-template-postgresql-ha.yaml
zeabur-template-twenty-crm.yaml
```

❌ **避免**
```bash
# 大寫或空格
PostgreSQL/
Twenty CRM/

# 不規範的檔案名稱
template.yaml
pg-template.yaml
```

### 服務命名

✅ **推薦**
```yaml
services:
  - name: postgresql  # 簡短、清楚、小寫
  - name: redis
  - name: app
  - name: worker
```

❌ **避免**
```yaml
services:
  - name: PostgreSQL-Database-Service-16  # 太長
  - name: my_app_service  # 使用底線
  - name: App  # 大寫開頭
```

**命名建議：**
- 使用服務的官方名稱（小寫）
- 保持簡短（5-15 個字元）
- 避免版本號（版本放在 Docker 映像標籤）
- 多個相同類型服務時加上後綴（如 `db-primary`, `db-replica`）

### 變數命名

✅ **推薦**
```yaml
variables:
  - key: PUBLIC_DOMAIN
  - key: ADMIN_PASSWORD
  - key: API_KEY

env:
  POSTGRES_USER:
  POSTGRES_PASSWORD:
  DATABASE_URL:
```

❌ **避免**
```yaml
variables:
  - key: publicDomain  # 駝峰式
  - key: admin-password  # 連字號

env:
  postgres_user:  # 小寫
  Postgres_Password:  # 混合大小寫
```

**命名規則：**
- **使用者變數**（`variables`）：大寫 + 底線，如 `PUBLIC_DOMAIN`
- **環境變數**（`env`）：大寫 + 底線，如 `DATABASE_URL`
- **埠號 ID**（`ports[].id`）：小寫，如 `web`, `api`, `database`
- **Volume ID**（`volumes[].id`）：小寫，如 `data`, `config`

---

## 環境變數設計

### 設計原則

1. **最小暴露原則**
   - 只暴露必要的變數
   - 內部使用的變數不需要 `expose: true`

2. **唯讀保護**
   - 自動生成的值設為 `readonly: true`
   - 防止使用者誤改導致服務異常

3. **明確的預設值**
   - 提供合理的預設值
   - 避免空值或不明確的預設值

### 模式 1: 資料庫連接資訊

這是最常用的模式，用於暴露資料庫連接資訊：

```yaml
services:
  - name: postgresql
    spec:
      env:
        # 基本配置（使用者可修改）
        POSTGRES_USER:
          default: postgres
          expose: true

        POSTGRES_PASSWORD:
          default: ${PASSWORD}  # 自動生成
          expose: true

        POSTGRES_DB:
          default: postgres
          expose: true

        # 連接資訊（唯讀，供其他服務使用）
        POSTGRES_HOST:
          default: ${CONTAINER_HOSTNAME}
          expose: true
          readonly: true

        POSTGRES_PORT:
          default: ${DATABASE_PORT}
          expose: true
          readonly: true

        # 連接字串（唯讀，方便使用）
        POSTGRES_CONNECTION_STRING:
          default: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
          expose: true
          readonly: true
```

**優點：**
- ✅ 清楚區分可修改和唯讀變數
- ✅ 提供多種連接方式（分開的變數 + 連接字串）
- ✅ 使用 Zeabur 內建變數確保正確性

### 模式 2: 應用程式 URL

```yaml
variables:
  - key: PUBLIC_DOMAIN
    type: DOMAIN
    name: Domain
    description: Domain to bind to your service

services:
  - name: app
    domainKey: PUBLIC_DOMAIN
    spec:
      env:
        # 完整 URL（含 https://）
        APP_URL:
          default: ${ZEABUR_WEB_URL}
          readonly: true

        # 前端環境變數
        NEXT_PUBLIC_URL:
          default: ${ZEABUR_WEB_URL}
          readonly: true

        # API endpoint
        API_ENDPOINT:
          default: ${ZEABUR_WEB_URL}/api
          readonly: true

        # OAuth callback
        OAUTH_CALLBACK_URL:
          default: ${ZEABUR_WEB_URL}/auth/callback
          readonly: true
```

**重點：**
- ✅ 使用 `${ZEABUR_WEB_URL}` 而非 `${PUBLIC_DOMAIN}`
- ✅ 所有 URL 相關變數都設為 `readonly`
- ✅ 為不同用途提供專門的變數

### 模式 3: 多服務環境變數共享

使用 YAML 錨點避免重複：

```yaml
# 定義共用環境變數
x-common-env: &common-env
  APP_SECRET:
    default: ${PASSWORD}
    expose: true
  S3_BUCKET:
    default: my-bucket
    expose: true
  S3_REGION:
    default: us-east-1
    expose: true

services:
  - name: server
    spec:
      env:
        <<: *common-env  # 引用共用變數
        SERVER_SPECIFIC_VAR:
          default: value

  - name: worker
    spec:
      env:
        <<: *common-env  # 引用共用變數
        WORKER_SPECIFIC_VAR:
          default: value
```

### 環境變數檢查清單

每個環境變數都應該考慮：

- [ ] 是否需要暴露給其他服務？（`expose: true`）
- [ ] 是否應該唯讀？（`readonly: true`）
- [ ] 預設值是否合理？
- [ ] 是否使用了正確的 Zeabur 內建變數？
- [ ] 變數名稱是否清楚易懂？

---

## Volume 管理

### 核心概念

**⚠️ 重要：Zeabur Volume 預設為空目錄**

不要期望 Volume 裡有任何預設檔案。

### 使用場景

#### 場景 1: 資料持久化（✅ 使用 Volume）

用於儲存執行時產生的資料：

```yaml
services:
  - name: postgresql
    spec:
      volumes:
        - id: data
          dir: /var/lib/postgresql/data  # 資料庫檔案

  - name: app
    spec:
      volumes:
        - id: uploads
          dir: /app/uploads  # 使用者上傳的檔案
        - id: logs
          dir: /app/logs  # 應用日誌
```

**適合：**
- 資料庫資料檔案
- 使用者上傳的檔案
- 應用程式產生的日誌
- 快取檔案

#### 場景 2: 配置檔案（✅ 使用 configs）

用於注入靜態配置檔案：

```yaml
services:
  - name: app
    spec:
      configs:
        - path: /app/config/app.yml
          template: |
            server:
              host: 0.0.0.0
              port: ${PORT}
            database:
              url: ${DATABASE_URL}
          envsubst: true  # 啟用環境變數替換
```

**適合：**
- 應用程式配置檔案
- Nginx 配置
- 證書檔案
- 腳本檔案

#### 場景 3: 動態生成檔案（✅ 使用 init）

用於在啟動時動態生成檔案：

```yaml
services:
  - name: app
    spec:
      init:
        - id: setup-config
          command:
            - /bin/bash
            - -c
            - |
              # 建立配置目錄
              mkdir -p /app/config

              # 生成配置檔案
              cat > /app/config/app.yml <<EOF
              server:
                host: 0.0.0.0
                port: ${PORT}
              database:
                url: ${DATABASE_URL}
              EOF

              # 設定權限
              chmod 600 /app/config/app.yml
```

**適合：**
- 需要條件判斷的配置
- 需要複雜處理的設定
- 需要設定權限的檔案

### Volume 最佳實踐

#### 1. 使用標準路徑

```yaml
# PostgreSQL
volumes:
  - id: data
    dir: /var/lib/postgresql/data

# MySQL
volumes:
  - id: data
    dir: /var/lib/mysql

# MongoDB
volumes:
  - id: data
    dir: /data/db

# Redis
volumes:
  - id: data
    dir: /data
```

#### 2. 清楚的 Volume ID

```yaml
# ✅ 推薦：清楚說明用途
volumes:
  - id: data
  - id: config
  - id: uploads
  - id: logs

# ❌ 避免：模糊不清
volumes:
  - id: vol1
  - id: storage
  - id: files
```

#### 3. 避免共享 Volume

Zeabur 不支援多個服務共享同一個 Volume。

**替代方案：**

- **使用 Object Storage**（如 S3）
- **主從架構**：一個服務管理檔案，其他服務透過 API 存取
- **資料庫儲存**：將檔案資訊存在資料庫

---

## 服務依賴管理

### 依賴關係原則

1. **明確聲明**：所有依賴都必須在 `dependencies` 中聲明
2. **避免循環**：A 依賴 B，B 不能依賴 A
3. **最小依賴**：只聲明直接依賴，不需要傳遞依賴

### 常見依賴模式

#### 模式 1: 應用 + 資料庫

```yaml
services:
  - name: postgresql
    # 無依賴，最先啟動

  - name: app
    dependencies:
      - postgresql  # 等待資料庫啟動
```

#### 模式 2: 應用 + 資料庫 + 快取

```yaml
services:
  - name: postgresql
    # 無依賴

  - name: redis
    # 無依賴

  - name: app
    dependencies:
      - postgresql
      - redis  # 等待兩者都啟動
```

#### 模式 3: 應用 + Worker

```yaml
services:
  - name: postgresql
    # 無依賴

  - name: redis
    # 無依賴

  - name: app
    dependencies:
      - postgresql
      - redis

  - name: worker
    dependencies:
      - postgresql
      - redis
      - app  # 等待應用啟動（如果需要）
```

### 依賴檢查清單

- [ ] 所有使用其他服務環境變數的服務都有設定依賴
- [ ] 沒有循環依賴
- [ ] 依賴的服務名稱正確
- [ ] 依賴的順序合理

---

## 圖片資源管理

### 圖片類型

#### 1. 模板圖示（spec.icon）

```yaml
spec:
  icon: https://raw.githubusercontent.com/zeabur/service-icons/main/marketplace/postgresql.svg
```

**要求：**
- 格式：SVG（首選）或 PNG
- 尺寸：512x512px 或更大
- 來源：穩定且可公開存取的 URL

#### 2. 封面圖片（spec.coverImage）

```yaml
spec:
  coverImage: https://raw.githubusercontent.com/username/repo/main/screenshot.webp
```

**要求：**
- 格式：WebP（首選）或 PNG
- 建議尺寸：1200x630px
- 內容：服務的截圖或 Logo

#### 3. 服務圖示（services[].icon）

```yaml
services:
  - name: postgresql
    icon: https://raw.githubusercontent.com/zeabur/service-icons/main/marketplace/postgresql.svg
```

### 圖片來源優先級

1. **zeabur/service-icons 倉庫**（最推薦）
   ```yaml
   icon: https://raw.githubusercontent.com/zeabur/service-icons/main/marketplace/postgresql.svg
   ```
   - ✅ 穩定可靠
   - ✅ 統一風格
   - ✅ 長期維護

2. **服務官方 GitHub**
   ```yaml
   icon: https://raw.githubusercontent.com/postgres/postgres/master/doc/src/sgml/logo.svg
   ```
   - ✅ 官方權威
   - ⚠️ 可能變更路徑

3. **Simple Icons CDN**
   ```yaml
   icon: https://cdn.simpleicons.org/postgresql
   ```
   - ✅ 方便快速
   - ⚠️ 依賴第三方服務

4. **自行託管**
   ```yaml
   icon: https://raw.githubusercontent.com/your-username/your-repo/main/icon.svg
   ```
   - ✅ 完全控制
   - ⚠️ 需要維護

### 圖片驗證檢查清單

- [ ] 所有圖片 URL 在瀏覽器中可以開啟
- [ ] 圖片正常顯示（沒有 404 或其他錯誤）
- [ ] 圖片格式正確（SVG/PNG/WebP）
- [ ] 圖片大小合理（< 1MB）
- [ ] URL 使用 HTTPS
- [ ] URL 不含認證資訊

### 圖片驗證方法

**方法 1: 瀏覽器測試（推薦）**
```
1. 複製每個圖片 URL
2. 在瀏覽器新分頁中開啟
3. 確認圖片正常顯示
```

**方法 2: 命令列測試**
```bash
# 測試所有圖片 URL
curl -I https://example.com/icon.svg
curl -I https://example.com/cover.webp

# 預期輸出
HTTP/2 200
content-type: image/svg+xml
```

---

## 多語系支援

### 支援的語言

建議至少支援以下三種語言：

1. **英文（en-US）** - 預設，寫在 `spec` 中
2. **繁體中文（zh-TW）** - 必須
3. **簡體中文（zh-CN）** - 必須

選填語言：
- 日文（ja-JP）
- 西班牙文（es-ES）
- 印尼文（id-ID）

### 翻譯流程

#### 階段 1: 完成英文版

```yaml
spec:
  description: |
    PostgreSQL is a powerful, open source database system.

  variables:
    - key: PUBLIC_DOMAIN
      type: DOMAIN
      name: Domain
      description: What domain do you want to bind to?

  readme: |
    # PostgreSQL
    Getting started...
```

#### 階段 2: 部署測試

```bash
npx zeabur@latest template deploy zeabur-template-postgresql.yaml
```

確認功能正常後再進行翻譯。

#### 階段 3: 添加翻譯

```yaml
localization:
  zh-TW:
    description: |
      PostgreSQL 是一個功能強大的開源資料庫系統。

    variables:
      - key: PUBLIC_DOMAIN
        type: DOMAIN
        name: 網域
        description: 你想綁定哪個網域？

    readme: |
      # PostgreSQL
      開始使用...

  zh-CN:
    description: |
      PostgreSQL 是一个功能强大的开源数据库系统。

    variables:
      - key: PUBLIC_DOMAIN
        type: DOMAIN
        name: 域名
        description: 你想绑定哪个域名？

    readme: |
      # PostgreSQL
      开始使用...
```

### 翻譯品質要求

#### ✅ 好的翻譯

- 使用正確的專業術語
- 保持語氣一致
- 注意繁簡體差異
- 所有語言版本資訊完整

#### ❌ 避免的翻譯

- 直接機器翻譯未校對
- 術語不統一
- 變數名稱被翻譯
- URL 被翻譯

### 術語一致性

建立術語對照表：

| 英文 | 繁體中文 | 簡體中文 |
|------|---------|---------|
| Database | 資料庫 | 数据库 |
| Server | 伺服器 | 服务器 |
| Domain | 網域 | 域名 |
| Port | 埠號 | 端口 |
| Configuration | 配置/設定 | 配置 |

### 多語系檢查清單

- [ ] 至少包含 3 種語言（en-US, zh-TW, zh-CN）
- [ ] 每種語言都有 `description`
- [ ] 每種語言都有 `variables`（所有變數）
- [ ] 每種語言都有 `readme`
- [ ] 變數的 `key` 和 `type` 在所有語言中一致
- [ ] 變數名稱（`${}`）未被翻譯
- [ ] URL 未被翻譯
- [ ] 術語使用一致

---

## 安全性

### 1. 密碼管理

❌ **不要使用固定密碼**
```yaml
env:
  ADMIN_PASSWORD:
    default: admin123  # 危險！
```

✅ **使用自動生成密碼**
```yaml
env:
  ADMIN_PASSWORD:
    default: ${PASSWORD}  # Zeabur 自動生成
    expose: true
```

### 2. 敏感資訊

❌ **不要在模板中硬編碼**
```yaml
env:
  API_KEY:
    default: sk-1234567890abcdef  # 不要這樣做
  AWS_SECRET_KEY:
    default: your-secret-key  # 不要這樣做
```

✅ **讓使用者填寫**
```yaml
variables:
  - key: API_KEY
    type: STRING
    name: API Key
    description: Your API key (get it from dashboard)
```

### 3. 環境變數暴露

只暴露必要的變數：

```yaml
# ✅ 好的做法
env:
  # 需要被其他服務使用 → expose: true
  POSTGRES_HOST:
    default: ${CONTAINER_HOSTNAME}
    expose: true
    readonly: true

  # 僅內部使用 → 不 expose
  INTERNAL_DEBUG_MODE:
    default: "false"
```

### 4. 檔案權限

使用 `init` 設定正確權限：

```yaml
spec:
  init:
    - id: setup-permissions
      command:
        - /bin/bash
        - -c
        - |
          chmod 600 /app/config/secrets.yml
          chown app:app /app/data
```

---

## 效能優化

### 1. 選擇輕量映像

```yaml
# ✅ 推薦：Alpine 變體
source:
  image: postgres:16-alpine  # ~80MB
  image: node:20-alpine      # ~120MB
  image: python:3.11-alpine  # ~50MB

# ⚠️ 可用但較大
source:
  image: postgres:16         # ~350MB
  image: node:20             # ~900MB
  image: python:3.11         # ~900MB
```

### 2. 簡化 init 腳本

```yaml
# ✅ 推薦：簡單快速
init:
  - id: setup
    command:
      - /bin/sh
      - -c
      - echo "Setup complete"

# ❌ 避免：過於複雜
init:
  - id: setup
    command:
      - /bin/bash
      - -c
      - |
        # 100+ 行的複雜腳本
        # 會拖慢啟動時間
```

### 3. 合理的資源限制

```yaml
spec:
  resourceUsage:
    cpu: 0.5      # vCPU
    memory: 512   # MiB
```

**建議：**
- 小型服務：0.5 CPU, 512MB
- 中型服務：1 CPU, 1024MB
- 大型服務：2 CPU, 2048MB+

---

## 可維護性

### 1. 添加註解

```yaml
services:
  - name: app
    spec:
      env:
        # OAuth redirect URL for authentication
        # Must match the URL configured in OAuth provider
        OAUTH_CALLBACK_URL:
          default: ${ZEABUR_WEB_URL}/auth/callback
          readonly: true
```

### 2. 使用 YAML 錨點避免重複

```yaml
# 定義共用配置
x-database-env: &database-env
  POSTGRES_HOST:
    default: ${CONTAINER_HOSTNAME}
    expose: true
    readonly: true
  POSTGRES_PORT:
    default: ${DATABASE_PORT}
    expose: true
    readonly: true

# 重複使用
services:
  - name: postgresql
    spec:
      env:
        <<: *database-env
```

### 3. 模組化設計

將複雜模板拆分成多個邏輯區塊：

```yaml
# 基礎資料庫服務
x-postgresql: &postgresql
  name: postgresql
  icon: https://...
  template: PREBUILT_V2
  spec:
    # ...

# 在 services 中引用
services:
  - <<: *postgresql
```

---

## 文件撰寫

### README 結構

```yaml
spec:
  readme: |
    # ServiceName

    Brief introduction (1-2 sentences).

    ## Getting Started

    1. Step one
    2. Step two
    3. Step three

    ## Configuration

    ### Environment Variables

    - `VAR1`: Description
    - `VAR2`: Description

    ## Documentation

    - [Official Docs](https://example.com/docs)
    - [GitHub](https://github.com/example/repo)
```

### README 最佳實踐

#### ✅ 推薦

- 使用清單和步驟
- 使用程式碼區塊
- 包含連結
- 使用變數插值（`${VARIABLE_NAME}`）

#### ❌ 避免

- 過長的段落
- 缺少範例
- 沒有格式化
- 資訊不完整

---

## 總結檢查清單

在提交模板前，檢查以下項目：

### 結構和格式
- [ ] 第一行有 schema 註解
- [ ] YAML 格式正確
- [ ] VS Code 無錯誤提示

### 命名
- [ ] 檔案名稱符合規範
- [ ] 服務名稱簡短清楚
- [ ] 變數使用大寫底線

### 環境變數
- [ ] 密碼使用 `${PASSWORD}`
- [ ] URL 使用 `${ZEABUR_WEB_URL}`
- [ ] 連接資訊正確暴露
- [ ] 唯讀變數設為 `readonly`

### 資源
- [ ] 所有圖片 URL 可存取
- [ ] 使用輕量映像變體
- [ ] Volume 路徑正確

### 依賴
- [ ] 依賴關係正確聲明
- [ ] 無循環依賴

### 多語系
- [ ] 至少 3 種語言
- [ ] 所有語言內容一致
- [ ] 變數名稱未翻譯

### 文件
- [ ] README 清楚完整
- [ ] 包含使用說明
- [ ] 包含文件連結

### 測試
- [ ] 本地部署成功
- [ ] 所有服務正常啟動
- [ ] 功能測試通過

---

**遵循這些最佳實踐，可以大幅提高模板的品質和成功率！** ⭐
