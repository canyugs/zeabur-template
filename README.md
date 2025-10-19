# Zeabur 模板撰寫指南

> **Language**: [English](./README.en-US.md) | 繁體中文 | [简体中文](./README.zh-CN.md)

本文件說明如何為 Zeabur 平台撰寫和維護服務模板。

## 目錄

- [概述](#概述)
- [模板結構](#模板結構)
- [撰寫流程](#撰寫流程)
- [最佳實踐](#最佳實踐)
- [多語系支援](#多語系支援)
- [測試與驗證](#測試與驗證)
- [範例](#範例)

## 概述

Zeabur 模板使用 YAML 格式定義，類似 Kubernetes 資源定義。每個模板描述一個或多個服務的部署配置，讓使用者可以一鍵部署完整的應用程式堆疊。

### 核心概念

- **Template Resource**: 使用 YAML 格式的模板資源定義
- **Services**: 模板中包含的服務列表（可以是 Docker 映像或 Git 倉庫）
- **Variables**: 使用者需要填寫的變數（如網域名稱、密碼等）
- **Localization**: 多語系支援，讓不同地區使用者看到本地化內容

## 模板結構

### 基本結構

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
apiVersion: zeabur.com/v1
kind: Template
metadata:
    name: 模板名稱
spec:
    description: 模板描述
    icon: 圖示 URL
    coverImage: 封面圖片 URL
    variables: []
    tags: []
    readme: |
      README 內容
    services: []
localization:
    zh-TW: {}
    zh-CN: {}
```

### 必要欄位

| 欄位 | 說明 | 範例 |
|------|------|------|
| `apiVersion` | API 版本，固定為 `zeabur.com/v1` | `zeabur.com/v1` |
| `kind` | 資源類型，固定為 `Template` | `Template` |
| `metadata.name` | 模板名稱 | `PostgreSQL` |
| `spec.services` | 服務列表 | 見下方說明 |

### 選用欄位

| 欄位 | 說明 | 類型 |
|------|------|------|
| `spec.description` | 模板描述 | string/null |
| `spec.icon` | 模板圖示 URL | string/null |
| `spec.coverImage` | 封面圖片 URL | string/null |
| `spec.variables` | 使用者變數 | array |
| `spec.tags` | 標籤 | array |
| `spec.readme` | README 內容（Markdown） | string/null |
| `spec.resourceUsage` | 預期資源使用量 | object |

## 撰寫流程

### 步驟 1: 研究目標服務

1. **了解服務架構**
   - 閱讀官方文件
   - 查看 Docker Compose 配置
   - 確認依賴服務（資料庫、快取等）

2. **收集必要資訊**
   - Docker 映像名稱和標籤
   - 預設埠號
   - 環境變數
   - 持久化儲存需求
   - 健康檢查方式

3. **準備素材**
   - 服務圖示（SVG/PNG，建議使用官方圖示）
   - 截圖或封面圖片（WebP 格式，建議 1200x630）
   - 文件連結

### 步驟 2: 建立模板檔案

創建 `zeabur-template-{service-name}.yaml` 檔案：

```bash
mkdir {service-name}
cd {service-name}
touch zeabur-template-{service-name}.yaml
```

### 步驟 3: 定義基本資訊

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
apiVersion: zeabur.com/v1
kind: Template
metadata:
    name: ServiceName
spec:
    description: |
      服務的簡短描述（1-2 句話）
    icon: https://example.com/icon.svg
    coverImage: https://example.com/cover.webp
    tags:
      - Category1
      - Category2
```

### 步驟 4: 定義使用者變數

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

**變數類型：**
- `DOMAIN`: 網域名稱（Zeabur 可自動生成 .zeabur.app 網域）
- `STRING`: 一般文字輸入

### 步驟 5: 定義服務

#### 5.1 資料庫服務範例（PostgreSQL）

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

#### 5.2 應用服務範例

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
              default: https://${PUBLIC_DOMAIN}
              readonly: true
          volumes:
            - id: data
              dir: /app/data
```

### 步驟 6: 添加說明文件

```yaml
spec:
    readme: |
      # ServiceName

      服務簡介

      ## 使用方式
      - 開啟 `https://${PUBLIC_DOMAIN}`
      - 使用預設憑證登入

      ## 配置選項
      - `ENV_VAR_1`: 說明
      - `ENV_VAR_2`: 說明

      ## 文件
      - 官方文件: https://example.com/docs
      - GitHub: https://github.com/example/repo
```

### 步驟 7: 測試部署

**重要：先完成英文版並測試部署**

在添加多語系支援之前，請先：

1. **完成英文版模板**
   - 確保所有必要欄位已填寫
   - 確認環境變數配置正確
   - 檢查服務依賴關係

2. **本地驗證**
   ```bash
   # 使用 VS Code 檢查 YAML 語法
   # schema 註解會自動驗證格式
   ```

3. **部署測試**
   ```bash
   # 使用 Zeabur CLI 部署測試
   npx zeabur@latest template deploy zeabur-template-{service-name}.yaml
   ```

4. **確認功能正常**
   - 服務能成功啟動
   - 環境變數正確傳遞
   - 網域綁定正常運作
   - 依賴服務正確連接

### 步驟 8: 添加多語系支援

**只有在確認部署成功後，才添加多語系**

```yaml
localization:
    zh-TW:
        description: |
          服務的繁體中文描述
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
          # 服務名稱

          繁體中文說明...

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

**多語系撰寫流程：**

1. 先完成英文版（寫在 `spec` 中）
2. 部署測試，確認功能正常
3. 複製英文版內容到 `localization` 區塊
4. 逐一翻譯成其他語言（zh-TW, zh-CN）
5. 注意保持所有語言版本的資訊一致
6. 再次測試部署，確認多語系顯示正常

## 最佳實踐

### 1. 命名規範

- **檔案命名**: `zeabur-template-{service-name}.yaml`
- **服務名稱**: 使用小寫字母，可包含連字號
- **變數命名**: 使用大寫字母和底線，如 `PUBLIC_DOMAIN`

### 2. 多國語言支援

**強烈建議為所有模板提供多國語言支援**，至少包含英文、繁體中文、簡體中文三種語言。

#### 必須本地化的內容

1. **description** - 模板描述
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

2. **variables** - 變數名稱和描述
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

3. **readme** - 使用說明文件
   - 包含使用方式
   - 配置選項
   - 文件連結

#### 翻譯品質要求

- ✅ 使用正確的專業術語
- ✅ 保持語氣一致
- ✅ 注意繁簡體差異（伺服器 vs 服务器、資料庫 vs 数据库）
- ✅ 所有語言版本的資訊應該完整且一致

#### 支援的語言代碼

- `en-US`: 英文（預設，直接寫在 spec 中）
- `zh-TW`: 繁體中文（台灣、香港、澳門）
- `zh-CN`: 簡體中文（中國大陸）
- `ja-JP`: 日文
- `es-ES`: 西班牙文

### 3. 圖片資源

- **圖示**:
  - 優先使用 SVG 格式
  - 如使用點陣圖，至少 512x512px
  - 使用官方品牌圖示
  - 確保 URL 可公開存取（建議使用 GitHub raw 連結）

- **封面圖片**:
  - 建議尺寸: 1200x630px
  - 格式: WebP（較小檔案大小）
  - 存放位置: GitHub 倉庫的 `screenshot.webp`

- **圖片驗證**:
  - ✅ 在提交前測試所有圖片 URL 是否可正常存取
  - ✅ 使用瀏覽器開啟圖片 URL 確認無破圖
  - ✅ 檢查圖片格式是否正確（SVG/PNG/WebP）
  - ✅ 確認圖片大小合理（避免過大影響載入速度）

### 4. 環境變數設計

```yaml
env:
    # 自動生成的變數（expose: true, readonly: true）
    SERVICE_HOST:
        default: ${CONTAINER_HOSTNAME}
        expose: true
        readonly: true

    # 使用者可修改的變數
    CUSTOM_CONFIG:
        default: "default-value"
        expose: true

    # 內部使用的變數（不暴露）
    INTERNAL_VAR:
        default: "internal-value"
```

**⚠️ 重要：網域 URL 設定**

當服務需要知道自己的公開 URL 時，不要直接使用 `${PUBLIC_DOMAIN}`：

```yaml
# ❌ 錯誤做法
env:
    APP_URL:
        default: https://${PUBLIC_DOMAIN}  # 如果使用者輸入 "myapp"，會變成 https://myapp

# ✅ 正確做法
env:
    APP_URL:
        default: ${ZEABUR_WEB_URL}  # Zeabur 自動提供完整 URL，如 https://myapp.zeabur.app
        readonly: true
```

### 5. 依賴管理

使用 `dependencies` 確保服務啟動順序：

```yaml
services:
  - name: database
    # ... 資料庫配置

  - name: cache
    # ... 快取配置

  - name: app
    dependencies:
      - database
      - cache
    # ... 應用配置
```

### 6. 健康檢查（適用於資料庫等）

```yaml
# 注意: Zeabur 模板 schema 不直接支援 healthcheck
# 但可以在 init 階段使用等待腳本
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

### 7. 初始化腳本

```yaml
spec:
  init:
    - id: init-db
      command:
      - /bin/bash
      - -c
      - |
        if [ ! -f /var/lib/app/.initialized ]; then
          # 執行初始化邏輯
          touch /var/lib/app/.initialized
        fi
```

## 多語系支援

### 支援的語言代碼

- `en-US`: 英文（預設，不需要在 localization 中定義）
- `zh-TW`: 繁體中文
- `zh-CN`: 簡體中文
- `ja-JP`: 日文
- `es-ES`: 西班牙文
- `id-ID`: 印尼文

### 可本地化的欄位

1. **description**: 模板描述
2. **coverImage**: 封面圖片（可為不同語言使用不同圖片）
3. **variables**: 變數的名稱和描述
4. **readme**: README 文件

### 翻譯要點

#### 繁體中文 vs 簡體中文術語對照

| 英文 | 繁體中文 | 簡體中文 |
|------|---------|---------|
| Server | 伺服器 | 服务器 |
| Database | 資料庫 | 数据库 |
| Configuration | 配置/設定 | 配置 |
| Connection | 連線 | 连接 |
| Domain | 網域 | 域名 |
| Authentication | 身份驗證 | 身份验证 |
| Middleware | 中介層 | 中间层 |
| Documentation | 文件 | 文档 |

## 測試與驗證

### 1. Schema 驗證

在 VS Code 中，第一行的 schema 註解會自動啟用驗證：

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
```

### 2. 必要檢查清單

- [ ] 所有必要欄位已填寫
- [ ] 圖示和封面圖片 URL 可存取且無破圖
  - [ ] 模板圖示 (`spec.icon`) 正常顯示
  - [ ] 封面圖片 (`spec.coverImage`) 正常顯示
  - [ ] 各服務圖示 (`services[].icon`) 正常顯示
- [ ] 環境變數正確配置
- [ ] 依賴關係正確設定
- [ ] README 包含使用說明
- [ ] 多語系翻譯完整且正確
  - [ ] 英文 (en-US) - 預設
  - [ ] 繁體中文 (zh-TW)
  - [ ] 簡體中文 (zh-CN)
  - [ ] 日文 (ja-JP)
  - [ ] 西班牙文 (es-ES)
  - [ ] 印尼文 (id-ID)
- [ ] 變數的預設值合理

### 3. 本地測試

使用 Docker Compose 進行本地測試：

```bash
# 轉換 Zeabur 模板為 Docker Compose（手動）
# 確認服務可以正常啟動
docker-compose up
```

### 4. 使用 Zeabur CLI

```bash
# 使用 npx 執行 Zeabur CLI（不需要全域安裝）
npx zeabur@latest auth login

# 部署測試
npx zeabur@latest template deploy zeabur-template-{service-name}.yaml
```

## 常見問題

### Q: 如何處理敏感資訊？

使用 Zeabur 的密碼生成功能：

```yaml
env:
    SECRET_KEY:
        default: ${PASSWORD}  # 自動生成安全密碼
        expose: true
```

### Q: 如何讓服務等待資料庫就緒？

使用 `init` 階段的等待腳本或在應用程式中實作重試邏輯。

### Q: PUBLIC_DOMAIN 變數與應用程式 URL 設定的差異？

這是一個常見的混淆點：

**問題場景：**
- 使用者在 `PUBLIC_DOMAIN` 變數輸入：`myapp`
- Zeabur 自動綁定為：`myapp.zeabur.app`
- 但 `${PUBLIC_DOMAIN}` 變數值仍是：`myapp`
- 如果設定 `APP_URL: https://${PUBLIC_DOMAIN}`，會變成 `https://myapp` ❌

**解決方案：**

```yaml
variables:
  # 這個變數用於讓 Zeabur 綁定網域
  - key: PUBLIC_DOMAIN
    type: DOMAIN
    name: Domain
    description: What domain do you want to bind to?

services:
  - name: app
    domainKey: PUBLIC_DOMAIN  # 綁定網域
    spec:
      env:
        # 應用程式內部使用完整 URL
        APP_URL:
          default: ${ZEABUR_WEB_URL}  # ✅ 使用 Zeabur 內建變數
          readonly: true
        NEXT_PUBLIC_APP_URL:
          default: ${ZEABUR_WEB_URL}  # ✅ 完整 URL，包含協定
          readonly: true
```

**重點說明：**
- `PUBLIC_DOMAIN`：給使用者填寫的變數，用於網域綁定
- `${ZEABUR_WEB_URL}`：Zeabur 自動提供的完整 URL（包含 https:// 和完整網域）
- 不要在應用程式 URL 設定中直接使用 `${PUBLIC_DOMAIN}`

### Q: 如何處理多個網域？

使用陣列形式的 `domainKey`：

```yaml
domainKey:
  - port: web
    variable: FRONTEND_DOMAIN
  - port: api
    variable: API_DOMAIN
```

### Q: 圖示去哪裡找？

1. 服務官方網站
2. GitHub 倉庫
3. [zeabur/service-icons](https://github.com/zeabur/service-icons)
4. [Simple Icons](https://simpleicons.org/)

## 範例參考

本倉庫中的範例模板：

- **Odoo**: 完整的 ERP 系統，包含 PostgreSQL
  - 檔案: `odoo/zeabur-template-odoo.yaml`
  - 特點: 自定義配置、初始化腳本

- **MetaMCP**: MCP 聚合器
  - 檔案: `MetaMCP/zeabur-template-metamcp.yaml`
  - 特點: 雙服務依賴、完整多語系

## 進階主題

### 自定義配置檔案

使用 `configs` 注入配置檔案：

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
      envsubst: true  # 啟用環境變數替換
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

### 資源使用量提示

```yaml
spec:
  resourceUsage:
    cpu: 0.5      # vCPU
    memory: 1024  # MiB
```

## Zeabur 內建變數參考

撰寫模板時可以使用以下 Zeabur 提供的內建變數。完整的變數列表請參考[官方文件](https://zeabur.com/docs/zh-TW/deploy/variables)。

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

### 埠號相關

| 變數名稱 | 說明 | 範例 |
|---------|------|------|
| `${PORT}` | 服務預設監聽的埠號 | `8080` |
| `${[PORTNAME]_PORT}` | 指定埠號的埠號值 | `${WEB_PORT}` → `3000` |

### 資料庫相關（PostgreSQL 範例）

Zeabur 的資料庫服務會自動暴露以下變數：

| 變數名稱 | 說明 |
|---------|------|
| `${POSTGRES_HOST}` | PostgreSQL 主機名稱 |
| `${POSTGRES_PORT}` | PostgreSQL 埠號 |
| `${POSTGRES_USERNAME}` | PostgreSQL 使用者名稱 |
| `${POSTGRES_PASSWORD}` | PostgreSQL 密碼 |
| `${POSTGRES_DATABASE}` | PostgreSQL 資料庫名稱 |
| `${POSTGRES_CONNECTION_STRING}` | PostgreSQL 完整連線字串 |
| `${POSTGRES_URI}` | PostgreSQL URI（同 CONNECTION_STRING） |

**注意：** 其他資料庫（MySQL、MongoDB、Redis 等）也有類似的變數格式。

### 埠號轉發相關

當使用埠號轉發功能時可用：

| 變數名稱 | 說明 |
|---------|------|
| `${PORT_FORWARDED_HOSTNAME}` | 埠號轉發的主機名稱 |
| `${[PORTNAME]_PORT_FORWARDED_PORT}` | 埠號轉發的埠號 |
| `${DATABASE_PORT_FORWARDED_PORT}` | 資料庫埠號轉發的埠號 |

### 密碼生成

| 變數名稱 | 說明 |
|---------|------|
| `${PASSWORD}` | Zeabur 自動生成的安全隨機密碼 |

**使用建議：**
- ✅ 應用程式需要知道自己的公開 URL → 使用 `${ZEABUR_WEB_URL}`
- ✅ 服務間內部通訊 → 使用 `${CONTAINER_HOSTNAME}`
- ✅ 需要安全密碼 → 使用 `${PASSWORD}`
- ❌ 不要在應用程式 URL 中直接使用 `${PUBLIC_DOMAIN}`（使用者變數）

### 變數參考順序

在模板中引用變數時，Zeabur 會按以下順序解析：

1. 使用者在模板中定義的變數（如 `PUBLIC_DOMAIN`）
2. 服務暴露的環境變數（`expose: true`）
3. Zeabur 特殊變數（如 `${ZEABUR_WEB_URL}`）
4. 系統內建變數（如 `${PASSWORD}`）

更多資訊請參考：
- [特殊變數文件](https://zeabur.com/docs/zh-TW/deploy/special-variables)
- [環境變數設定](https://zeabur.com/docs/zh-TW/deploy/variables)

## 參考資源

- [Zeabur 官方文件](https://zeabur.com/docs)
- [Template Schema](https://schema.zeabur.app/template.json)
- [Prebuilt Service Schema](https://schema.zeabur.app/prebuilt.json)
- [範本倉庫](https://github.com/zeabur/zeabur)

## 貢獻指南

1. Fork 本倉庫
2. 建立新的服務目錄
3. 撰寫模板檔案
4. 準備截圖
5. 提交 Pull Request

### PR 檢查清單

- [ ] 模板通過 schema 驗證
- [ ] 包含完整的多語系翻譯（建議全部 6 種語言）
  - [ ] 英文 (en-US)
  - [ ] 繁體中文 (zh-TW)
  - [ ] 簡體中文 (zh-CN)
  - [ ] 日文 (ja-JP)
  - [ ] 西班牙文 (es-ES)
  - [ ] 印尼文 (id-ID)
- [ ] 提供截圖（screenshot.webp）
- [ ] 所有圖片資源可正常存取且無破圖
- [ ] README 說明完整
- [ ] 已在 Zeabur 平台測試部署

## 授權

MIT License
