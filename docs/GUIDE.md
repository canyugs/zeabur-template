# Zeabur 模板製作完整指南

本指南將帶你從零開始，一步步完成一個 Zeabur 模板的製作和發布。每個步驟都包含詳細說明、檢查清單和常見錯誤提醒。

## 目錄

- [步驟 0: 準備工作](#步驟-0-準備工作)
- [步驟 1: 研究目標服務](#步驟-1-研究目標服務)
- [步驟 2: 建立模板檔案](#步驟-2-建立模板檔案)
- [步驟 3: 定義基本資訊](#步驟-3-定義基本資訊)
- [步驟 4: 定義服務](#步驟-4-定義服務)
- [步驟 5: 配置環境變數](#步驟-5-配置環境變數)
- [步驟 6: 添加使用者變數](#步驟-6-添加使用者變數)
- [步驟 7: 撰寫使用說明](#步驟-7-撰寫使用說明)
- [步驟 8: 測試部署](#步驟-8-測試部署)
- [步驟 9: 添加多語系支援](#步驟-9-添加多語系支援)
- [步驟 10: 提交模板](#步驟-10-提交模板)

---

## 步驟 0: 準備工作

### 環境設置

在開始之前，確保你的開發環境已經準備好：

```bash
# 1. 安裝 Node.js（建議 v18 或更高版本）
node --version

# 2. 安裝 Zeabur CLI（使用 npx 不需全域安裝）
npx zeabur@latest --version

# 3. 登入 Zeabur
npx zeabur@latest auth login
```

### 必備工具

- **VS Code**（或其他支援 YAML 的編輯器）
  - 安裝 YAML 擴展（Red Hat）
  - 會自動驗證 schema

- **Git**（用於版本控制和提交）

- **圖片編輯工具**（如需準備圖示和封面）

### 基礎知識

建議先了解以下概念：

- YAML 基本語法
- Docker 和容器化概念
- 環境變數的作用
- HTTP/TCP 埠號

### ✅ 準備工作檢查清單

- [ ] Node.js 已安裝
- [ ] Zeabur CLI 可正常使用
- [ ] 已登入 Zeabur 帳號
- [ ] VS Code 已安裝 YAML 擴展
- [ ] Git 已安裝並配置

---

## 步驟 1: 研究目標服務

在撰寫模板之前，需要充分了解目標服務的架構和需求。

### 1.1 了解服務架構

訪問服務的官方網站和文件，了解：

- **服務用途**：這個服務是做什麼的？
- **技術堆疊**：使用什麼語言/框架？
- **依賴服務**：需要資料庫嗎？需要 Redis 嗎？
- **部署方式**：官方推薦的部署方式是什麼？

### 1.2 收集 Docker 資訊

查找服務的 Docker Hub 頁面或 GitHub 倉庫：

**必須收集的資訊：**

```yaml
# Docker 映像資訊
image: postgres:16-alpine  # 映像名稱和標籤
ports: 5432                # 預設埠號
volumes: /var/lib/postgresql/data  # 資料目錄

# 環境變數
POSTGRES_USER: 使用者名稱
POSTGRES_PASSWORD: 密碼
POSTGRES_DB: 資料庫名稱
```

**查找資訊的地方：**

1. Docker Hub 官方頁面
2. GitHub 倉庫的 README
3. 官方文件的 Docker 部署章節
4. docker-compose.yml 範例檔案

### 1.3 準備圖片素材

**圖示（Icon）**

- 格式：SVG（首選）或 PNG
- 尺寸：512x512px 或更大
- 來源：
  - 官方網站
  - [Simple Icons](https://simpleicons.org/)
  - [zeabur/service-icons](https://github.com/zeabur/service-icons)

**封面圖片（Cover Image）**

- 格式：WebP（檔案較小）
- 建議尺寸：1200x630px
- 內容：服務的截圖或 Logo

**⚠️ 重要：確保圖片 URL 可公開存取**

**方法 1: 使用瀏覽器測試（推薦，最直觀）**
```
1. 複製圖片 URL
2. 在瀏覽器新分頁貼上並開啟
3. 確認圖片正常顯示，沒有出現 404 或其他錯誤
```

**方法 2: 使用命令列測試**
```bash
# 測試圖片 URL 是否可存取
curl -I https://example.com/icon.svg
# 預期回應: HTTP/2 200
```

### 1.4 查看類似模板

參考已有的類似服務模板：

- 資料庫類：PostgreSQL, MySQL, MongoDB
- 應用類：Odoo, Twenty CRM
- 工具類：Redis, Elasticsearch

### ✅ 研究階段檢查清單

- [ ] 已閱讀官方文件
- [ ] 已找到 Docker 映像名稱和標籤
- [ ] 已確認預設埠號
- [ ] 已列出所有必要的環境變數
- [ ] 已確認資料持久化目錄
- [ ] 已準備圖示（SVG/PNG）
- [ ] 已準備封面圖片（WebP）
- [ ] 已測試所有圖片 URL 可存取

### 💡 最佳實踐

- 使用穩定版本標籤（如 `16-alpine`）而非 `latest`
- 優先使用官方 Docker 映像
- 選擇較小的映像變體（如 alpine）

### ⚠️ 常見錯誤

❌ **使用 `latest` 標籤**
```yaml
image: postgres:latest  # 版本不固定，可能導致不一致
```

✅ **使用特定版本**
```yaml
image: postgres:16-alpine  # 版本固定，可預測
```

---

## 步驟 2: 建立模板檔案

### 2.1 建立目錄結構

```bash
# 在專案根目錄下建立服務目錄
mkdir my-service
cd my-service

# 建立模板檔案
touch zeabur-template-my-service.yaml
```

**命名規範：**

- 目錄名稱：小寫，可用連字號，如 `postgresql-ha`
- 檔案名稱：`zeabur-template-{service-name}.yaml`

### 2.2 設定 Schema 驗證

在 YAML 檔案的第一行加入 schema 註解，讓 VS Code 自動驗證：

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
```

這會啟用：
- ✅ 即時語法檢查
- ✅ 自動完成提示
- ✅ 欄位驗證
- ✅ 型別檢查

### 2.3 建立基本結構

複製以下基本結構到你的 YAML 檔案：

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
apiVersion: zeabur.com/v1
kind: Template
metadata:
    name: MyService
spec:
    description: |
      A brief description of your service
    icon: https://example.com/icon.svg
    coverImage: https://example.com/cover.webp
    tags:
      - Database
    variables: []
    services: []
```

### ✅ 建立檔案檢查清單

- [ ] 已建立服務目錄
- [ ] 檔案命名符合規範
- [ ] 已加入 schema 註解
- [ ] VS Code 顯示自動完成（輸入時測試）
- [ ] 基本結構已建立

### ⚠️ 常見錯誤

❌ **忘記加 schema 註解**
```yaml
apiVersion: zeabur.com/v1  # VS Code 不會驗證
```

✅ **正確加入 schema**
```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
apiVersion: zeabur.com/v1
```

---

## 步驟 3: 定義基本資訊

### 3.1 填寫 Metadata

`metadata` 區塊包含模板的基本識別資訊：

```yaml
metadata:
    name: PostgreSQL  # 模板名稱，會顯示在 Zeabur 平台上
```

**命名建議：**
- 使用官方服務名稱
- 首字母大寫
- 避免過長的名稱

### 3.2 填寫 Spec 基本欄位

```yaml
spec:
    description: |
      PostgreSQL is a powerful, open source object-relational database system
      with over 35 years of active development.

    icon: https://raw.githubusercontent.com/zeabur/service-icons/main/marketplace/postgresql.svg

    coverImage: https://raw.githubusercontent.com/username/repo/main/screenshot.webp

    tags:
      - Database
      - SQL
```

**欄位說明：**

| 欄位 | 必填 | 說明 | 範例 |
|------|------|------|------|
| `description` | 建議 | 服務簡介（1-3 句話）| 使用 `\|` 可多行 |
| `icon` | 建議 | 圖示 URL | SVG 或 PNG |
| `coverImage` | 選填 | 封面圖片 URL | WebP 格式 |
| `tags` | 建議 | 分類標籤 | 陣列格式 |

### 3.3 選擇合適的標籤

常用標籤分類：

**資料庫類：**
- `Database`
- `SQL` / `NoSQL`
- `Cache`

**應用類：**
- `CRM`
- `CMS`
- `Analytics`
- `Monitoring`

**開發工具：**
- `DevTools`
- `CI/CD`
- `Testing`

### 3.4 圖片最佳實踐

**圖示（icon）：**

```yaml
# ✅ 推薦：使用 zeabur/service-icons 倉庫
icon: https://raw.githubusercontent.com/zeabur/service-icons/main/marketplace/postgresql.svg

# ✅ 可行：使用官方倉庫
icon: https://raw.githubusercontent.com/postgres/postgres/master/logo.svg

# ❌ 避免：使用不穩定的 CDN
icon: https://random-cdn.com/icon.svg
```

**封面圖片（coverImage）：**

```yaml
# ✅ 正確：使用完整的 HTTPS URL
coverImage: https://raw.githubusercontent.com/username/zeabur-template/main/my-service/screenshot.webp

# ❌ 錯誤：本地相對路徑無法使用
# coverImage: ./screenshot.webp
```

**重要提醒：**
- 必須使用完整的 HTTPS URL
- 不支援相對路徑（如 `./screenshot.webp`）
- 圖片必須上傳到可公開存取的位置（如 GitHub）

### ✅ 基本資訊檢查清單

- [ ] `metadata.name` 已填寫
- [ ] `description` 清楚描述服務用途
- [ ] `icon` URL 可正常存取（在瀏覽器測試）
- [ ] `coverImage` URL 可正常存取
- [ ] `tags` 已選擇適當分類
- [ ] 所有圖片在瀏覽器中正常顯示

### ⚠️ 常見錯誤

❌ **description 太長或太短**
```yaml
description: PostgreSQL  # 太簡短
description: |
  PostgreSQL is a powerful, open source object-relational database system
  with over 35 years of active development that has earned it a strong
  reputation for reliability, feature robustness, and performance...
  # 太冗長，50+ 行
```

✅ **適當長度**
```yaml
description: |
  PostgreSQL is a powerful, open source object-relational database system
  with over 35 years of active development.
```

---

## 步驟 4: 定義服務

### 4.1 服務結構概覽

每個模板可包含一個或多個服務：

```yaml
spec:
    services:
      - name: database      # 第一個服務（資料庫）
        template: PREBUILT_V2
        spec:
          source:
            image: postgres:16-alpine
          # ... 其他配置

      - name: app           # 第二個服務（應用）
        template: PREBUILT_V2
        dependencies:
          - database        # 依賴資料庫
        spec:
          # ... 應用配置
```

### 4.2 定義資料庫服務

以 PostgreSQL 為例：

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
          default: postgres
          expose: true

        # 暴露連接資訊給其他服務使用
        POSTGRES_HOST:
          default: ${CONTAINER_HOSTNAME}
          expose: true
          readonly: true

        POSTGRES_PORT:
          default: ${DATABASE_PORT}
          expose: true
          readonly: true
```

**欄位詳解：**

| 欄位 | 說明 | 範例 |
|------|------|------|
| `name` | 服務名稱（小寫） | `postgresql` |
| `icon` | 服務圖示 | URL |
| `template` | 固定為 `PREBUILT_V2` | - |
| `spec.source.image` | Docker 映像 | `postgres:16-alpine` |
| `spec.ports` | 埠號定義 | 見下方說明 |
| `spec.volumes` | 資料卷 | 見下方說明 |
| `spec.env` | 環境變數 | 見步驟 5 |

### 4.3 定義埠號（Ports）

```yaml
ports:
  - id: database          # 埠號識別碼
    port: 5432            # 埠號數字
    type: TCP             # TCP 或 HTTP
```

**埠號類型：**

- `HTTP`：Web 服務、API（如 8080, 3000）
- `TCP`：資料庫、快取、其他服務（如 5432, 6379）

**多埠號範例：**

```yaml
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

### 4.4 定義資料卷（Volumes）

**⚠️ 重要：Zeabur Volume 預設為空目錄**

```yaml
volumes:
  - id: data                        # Volume 識別碼
    dir: /var/lib/postgresql/data   # 容器內的路徑
```

**常見資料目錄：**

| 服務 | 資料目錄 |
|------|---------|
| PostgreSQL | `/var/lib/postgresql/data` |
| MySQL | `/var/lib/mysql` |
| MongoDB | `/data/db` |
| Redis | `/data` |

**Volume 使用建議：**

- ✅ 用於儲存執行時產生的資料
- ❌ 不要期望 Volume 裡有預設檔案
- ✅ 如需配置檔，使用 `configs` 注入

### 4.5 添加連線說明（Instructions）

`instructions` 可以在 Zeabur 介面上顯示連線資訊，讓使用者方便複製使用，特別適合資料庫服務。

#### 基本結構

```yaml
spec:
  instructions:
    - title: Connection String
      content: postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@${PORT_FORWARDED_HOSTNAME}:${DATABASE_PORT_FORWARDED_PORT}/${DATABASE_NAME}

    - title: PostgreSQL host
      content: ${PORT_FORWARDED_HOSTNAME}

    - title: PostgreSQL port
      content: ${DATABASE_PORT_FORWARDED_PORT}
```

#### 欄位說明

| 欄位 | 說明 | 範例 |
|------|------|------|
| `title` | 說明標題 | `Connection String` |
| `content` | 內容（支援變數） | `${PORT_FORWARDED_HOSTNAME}` |

#### Port Forwarding 內建變數

Zeabur 提供特殊的內建變數用於外部連線：

**`${PORT_FORWARDED_HOSTNAME}`**
- 外部可訪問的主機名稱
- 用於從本地或外部環境連接到 Zeabur 上的服務

**`${[PORTNAME]_PORT_FORWARDED_PORT}`**
- 對應 port id 的轉發埠號
- 命名規則：將 port id 轉為大寫，加上 `_PORT_FORWARDED_PORT`

**Port ID 對應範例：**

```yaml
ports:
  - id: database          # port id
    port: 5432
    type: TCP

# 在 instructions 中使用：
instructions:
  - title: Port
    content: ${DATABASE_PORT_FORWARDED_PORT}  # id: database → DATABASE_PORT_FORWARDED_PORT
```

```yaml
ports:
  - id: redis             # port id
    port: 6379
    type: TCP

# 對應變數：
# ${REDIS_PORT_FORWARDED_PORT}
```

#### 完整範例（PostgreSQL）

```yaml
services:
  - name: postgresql
    template: PREBUILT_V2
    spec:
      source:
        image: postgres:16-alpine

      ports:
        - id: database    # ← 定義 port id
          port: 5432
          type: TCP

      env:
        POSTGRES_USER:
          default: postgres
          expose: true

        POSTGRES_PASSWORD:
          default: ${PASSWORD}
          expose: true

        POSTGRES_DB:
          default: postgres
          expose: true

      instructions:
        # 完整連線字串
        - title: Connection String
          content: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${PORT_FORWARDED_HOSTNAME}:${DATABASE_PORT_FORWARDED_PORT}/${POSTGRES_DB}

        # psql 命令
        - title: PostgreSQL Connect Command
          content: psql "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${PORT_FORWARDED_HOSTNAME}:${DATABASE_PORT_FORWARDED_PORT}/${POSTGRES_DB}"

        # 分開的連線資訊
        - title: Host
          content: ${PORT_FORWARDED_HOSTNAME}

        - title: Port
          content: ${DATABASE_PORT_FORWARDED_PORT}

        - title: Username
          content: ${POSTGRES_USER}

        - title: Password
          content: ${POSTGRES_PASSWORD}

        - title: Database
          content: ${POSTGRES_DB}
```

#### 使用場景

**✅ 適合使用 instructions 的情況：**

- 資料庫服務（PostgreSQL, MySQL, MongoDB, Redis）
- 需要從外部連接的服務
- 需要提供連線字串或憑證的服務
- 有管理後台需要顯示登入資訊

**範例應用：**

```yaml
# Redis
instructions:
  - title: Redis Connection
    content: redis://:${REDIS_PASSWORD}@${PORT_FORWARDED_HOSTNAME}:${REDIS_PORT_FORWARDED_PORT}

# MongoDB
instructions:
  - title: MongoDB URI
    content: mongodb://${MONGO_USER}:${MONGO_PASSWORD}@${PORT_FORWARDED_HOSTNAME}:${MONGO_PORT_FORWARDED_PORT}/${MONGO_DB}

# MySQL
instructions:
  - title: MySQL Connection
    content: mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${PORT_FORWARDED_HOSTNAME}:${MYSQL_PORT_FORWARDED_PORT}/${MYSQL_DATABASE}
```

#### 與內部連線的區別

**內部連線（服務間）：**
```yaml
env:
  DATABASE_HOST:
    default: ${CONTAINER_HOSTNAME}  # 內部主機名稱
  DATABASE_PORT:
    default: ${DATABASE_PORT}       # 內部埠號（如 5432）
```

**外部連線（instructions）：**
```yaml
instructions:
  - title: Host
    content: ${PORT_FORWARDED_HOSTNAME}        # 外部主機名稱
  - title: Port
    content: ${DATABASE_PORT_FORWARDED_PORT}   # 轉發後的埠號
```

**⚠️ 重要：不要混用**
- `CONTAINER_HOSTNAME` 和 `DATABASE_PORT` 用於服務間內部連線
- `PORT_FORWARDED_HOSTNAME` 和 `DATABASE_PORT_FORWARDED_PORT` 用於外部連線

#### ✅ Instructions 檢查清單

- [ ] port 有定義唯一的 `id`
- [ ] port id 正確轉換為大寫變數名（如 `database` → `DATABASE_PORT_FORWARDED_PORT`）
- [ ] 所有使用的環境變數都有 `expose: true`
- [ ] title 清楚說明用途
- [ ] 連線字串格式正確
- [ ] 測試複製後可以正常連線

#### 💡 最佳實踐

**提供多種格式：**
```yaml
instructions:
  # 1. 完整連線字串（方便複製）
  - title: Connection String
    content: postgresql://...

  # 2. 命令列格式（方便執行）
  - title: Connect Command
    content: psql "postgresql://..."

  # 3. 分開的參數（方便填入其他工具）
  - title: Host
    content: ${PORT_FORWARDED_HOSTNAME}
  - title: Port
    content: ${DATABASE_PORT_FORWARDED_PORT}
```

**清楚的標題：**
```yaml
# ✅ 推薦：具體說明
- title: PostgreSQL Connection String
- title: Redis Connection URL
- title: MongoDB URI

# ❌ 避免：太簡短
- title: Connection
- title: URL
```

#### ⚠️ 常見錯誤

❌ **錯誤 1: Port ID 對應錯誤**
```yaml
ports:
  - id: database
    port: 5432

instructions:
  - title: Port
    content: ${DB_PORT_FORWARDED_PORT}  # 錯誤！應該是 DATABASE_PORT_FORWARDED_PORT
```

✅ **正確做法**
```yaml
ports:
  - id: database
    port: 5432

instructions:
  - title: Port
    content: ${DATABASE_PORT_FORWARDED_PORT}  # port id "database" → "DATABASE"
```

❌ **錯誤 2: 使用內部連線變數**
```yaml
instructions:
  - title: Connection
    content: postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/db  # 這是內部連線！
```

✅ **正確做法**
```yaml
instructions:
  - title: Connection
    content: postgresql://${PORT_FORWARDED_HOSTNAME}:${DATABASE_PORT_FORWARDED_PORT}/db
```

❌ **錯誤 3: 引用未 expose 的變數**
```yaml
env:
  POSTGRES_PASSWORD:
    default: ${PASSWORD}
    # 忘記 expose: true

instructions:
  - title: Password
    content: ${POSTGRES_PASSWORD}  # 無法取得值！
```

✅ **正確做法**
```yaml
env:
  POSTGRES_PASSWORD:
    default: ${PASSWORD}
    expose: true  # ← 必須加上

instructions:
  - title: Password
    content: ${POSTGRES_PASSWORD}
```

### 4.6 定義應用服務

```yaml
services:
  - name: app
    icon: https://example.com/app-icon.svg
    template: PREBUILT_V2

    # 綁定網域到這個服務
    domainKey: PUBLIC_DOMAIN

    # 定義依賴關係
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
        # 使用資料庫連接資訊
        DATABASE_URL:
          default: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
          readonly: true

        # 使用 Zeabur 提供的完整 URL
        APP_URL:
          default: ${ZEABUR_WEB_URL}
          readonly: true
```

### 4.6 服務依賴關係

**依賴的作用：**

1. **啟動順序**：依賴的服務會先啟動
2. **環境變數**：可以使用依賴服務暴露的變數

```yaml
services:
  - name: database
    # ... 資料庫配置

  - name: cache
    # ... Redis 配置

  - name: app
    dependencies:
      - database  # 先啟動
      - cache     # 再啟動
    # ... 應用配置
```

### ✅ 定義服務檢查清單

- [ ] 每個服務都有唯一的 `name`
- [ ] 每個服務都有 `icon`
- [ ] `template` 設為 `PREBUILT_V2`
- [ ] Docker `image` 名稱和標籤正確
- [ ] `ports` 定義正確（id、port、type）
- [ ] `volumes` 路徑正確
- [ ] 依賴關係（`dependencies`）正確設定
- [ ] 應用服務的 `domainKey` 已設定

### 💡 最佳實踐

**服務命名：**
```yaml
# ✅ 推薦：簡短、清楚
name: postgresql
name: redis
name: app

# ❌ 避免：過長或不清楚
name: postgresql-database-service-16
name: my_app_service
```

**圖示選擇：**
```yaml
# ✅ 推薦：使用 zeabur/service-icons
icon: https://raw.githubusercontent.com/zeabur/service-icons/main/marketplace/postgresql.svg

# ✅ 可行：使用官方圖示
icon: https://www.postgresql.org/media/img/about/press/elephant.png

# ⚠️ 注意：確保 URL 穩定且可公開存取
```

### ⚠️ 常見錯誤

❌ **忘記設定依賴關係**
```yaml
services:
  - name: app
    # 忘記加 dependencies，可能導致啟動失敗
    env:
      DATABASE_URL: ${POSTGRES_HOST}  # POSTGRES_HOST 可能未定義
```

✅ **正確設定依賴**
```yaml
services:
  - name: app
    dependencies:
      - postgresql  # 確保 postgresql 先啟動
    env:
      DATABASE_URL: ${POSTGRES_HOST}
```

---

## 步驟 5: 配置環境變數

環境變數是模板中最重要的部分之一，決定了服務的行為和服務間的連接。

### 5.1 環境變數結構

```yaml
env:
  VARIABLE_NAME:
    default: value      # 預設值
    expose: true        # 是否暴露給其他服務（選填）
    readonly: true      # 是否唯讀（選填）
```

### 5.2 環境變數類型

#### 類型 1: 使用者可修改的變數

```yaml
env:
  POSTGRES_USER:
    default: postgres
    expose: true      # 暴露給其他服務使用
```

**特性：**
- ✅ 使用者可在部署後修改
- ✅ 可以被其他服務引用（如果 `expose: true`）

#### 類型 2: 自動生成的密碼

```yaml
env:
  POSTGRES_PASSWORD:
    default: ${PASSWORD}  # Zeabur 自動生成安全密碼
    expose: true
```

**Zeabur 內建變數：**
- `${PASSWORD}`：自動生成的隨機密碼
- `${CONTAINER_HOSTNAME}`：服務的內部主機名稱
- `${PORT}`：服務的預設埠號

#### 類型 3: 唯讀變數（readonly）

```yaml
env:
  POSTGRES_HOST:
    default: ${CONTAINER_HOSTNAME}
    expose: true
    readonly: true    # 使用者無法修改
```

**用途：**
- 服務間連接資訊
- 自動生成的 URL
- 系統提供的值

#### 類型 4: 內部變數（不暴露）

```yaml
env:
  INTERNAL_CONFIG:
    default: some-value
    # 沒有 expose: true，其他服務無法使用
```

### 5.3 常見環境變數模式

#### 模式 1: 資料庫連接資訊

```yaml
services:
  - name: postgresql
    spec:
      env:
        # 基本配置
        POSTGRES_USER:
          default: postgres
          expose: true

        POSTGRES_PASSWORD:
          default: ${PASSWORD}
          expose: true

        POSTGRES_DB:
          default: postgres
          expose: true

        # 連接資訊（供其他服務使用）
        POSTGRES_HOST:
          default: ${CONTAINER_HOSTNAME}
          expose: true
          readonly: true

        POSTGRES_PORT:
          default: ${DATABASE_PORT}
          expose: true
          readonly: true
```

#### 模式 2: 應用服務 URL

**⚠️ 重要：不要直接使用 `${PUBLIC_DOMAIN}`**

```yaml
# ❌ 錯誤做法
env:
  APP_URL:
    default: https://${PUBLIC_DOMAIN}
    # 如果使用者輸入 "myapp"，會變成 https://myapp（不完整）

# ✅ 正確做法
env:
  APP_URL:
    default: ${ZEABUR_WEB_URL}
    # Zeabur 自動提供完整 URL，如 https://myapp.zeabur.app
    readonly: true
```

**Zeabur URL 變數：**

| 變數 | 說明 | 範例 |
|------|------|------|
| `${ZEABUR_WEB_URL}` | web 埠的完整 URL | `https://myapp.zeabur.app` |
| `${ZEABUR_WEB_DOMAIN}` | web 埠的網域 | `myapp.zeabur.app` |
| `${ZEABUR_API_URL}` | api 埠的完整 URL | `https://api.myapp.zeabur.app` |

詳細說明請參考 [技術參考 - Zeabur 內建變數](REFERENCE.md#zeabur-內建變數)

#### 模式 3: 組合連接字串

```yaml
env:
  # 方法 1: 直接組合
  DATABASE_URL:
    default: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
    readonly: true

  # 方法 2: 使用 Zeabur 提供的連接字串（如果有）
  DATABASE_URL:
    default: ${POSTGRES_CONNECTION_STRING}
    readonly: true
```

### 5.4 引用其他服務的環境變數

**前提：目標服務必須設定 `expose: true`**

```yaml
services:
  - name: postgresql
    spec:
      env:
        POSTGRES_USER:
          default: postgres
          expose: true  # ← 必須設定

  - name: app
    dependencies:
      - postgresql  # ← 必須設定依賴
    spec:
      env:
        DB_USER:
          default: ${POSTGRES_USER}  # ← 可以引用
```

### ✅ 環境變數檢查清單

- [ ] 所有必要的環境變數都已定義
- [ ] 密碼使用 `${PASSWORD}` 自動生成
- [ ] 連接資訊變數設為 `readonly: true`
- [ ] URL 使用 `${ZEABUR_WEB_URL}`，不是 `${PUBLIC_DOMAIN}`
- [ ] 需要被其他服務使用的變數設為 `expose: true`
- [ ] 依賴服務已在 `dependencies` 中聲明
- [ ] 所有引用的變數都有定義

### 💡 最佳實踐

**變數命名：**
```yaml
# ✅ 推薦：使用大寫和底線
POSTGRES_USER
POSTGRES_PASSWORD
DATABASE_URL
APP_URL

# ❌ 避免：小寫或駝峰式
postgres_user
postgresUser
```

**暴露原則：**
```yaml
# ✅ 暴露：需要被其他服務使用
POSTGRES_HOST:
  expose: true

# ✅ 不暴露：僅內部使用
INTERNAL_DEBUG_MODE:
  # 沒有 expose: true
```

### ⚠️ 常見錯誤

❌ **錯誤 1: URL 配置錯誤**
```yaml
env:
  APP_URL:
    default: https://${PUBLIC_DOMAIN}  # PUBLIC_DOMAIN 只是 "myapp"
```

✅ **正確做法**
```yaml
env:
  APP_URL:
    default: ${ZEABUR_WEB_URL}  # 完整 URL: https://myapp.zeabur.app
    readonly: true
```

❌ **錯誤 2: 忘記設定 expose**
```yaml
# 在 postgresql 服務中
env:
  POSTGRES_HOST:
    default: ${CONTAINER_HOSTNAME}
    # 忘記 expose: true

# 在 app 服務中
env:
  DB_HOST:
    default: ${POSTGRES_HOST}  # 會是空的！
```

✅ **正確做法**
```yaml
# 在 postgresql 服務中
env:
  POSTGRES_HOST:
    default: ${CONTAINER_HOSTNAME}
    expose: true  # ← 加上這個
```

❌ **錯誤 3: 忘記設定依賴**
```yaml
services:
  - name: app
    # 忘記 dependencies
    spec:
      env:
        DB_HOST:
          default: ${POSTGRES_HOST}  # 可能未定義
```

✅ **正確做法**
```yaml
services:
  - name: app
    dependencies:
      - postgresql  # ← 加上依賴
    spec:
      env:
        DB_HOST:
          default: ${POSTGRES_HOST}
```

---

## 步驟 6: 添加使用者變數

使用者變數是在部署時讓使用者填寫的欄位，如網域名稱、密碼等。

### 6.1 變數結構

```yaml
spec:
    variables:
      - key: PUBLIC_DOMAIN
        type: DOMAIN
        name: Domain
        description: What domain do you want to bind to?
```

### 6.2 變數類型

#### DOMAIN 類型

用於讓使用者指定網域名稱：

```yaml
variables:
  - key: PUBLIC_DOMAIN
    type: DOMAIN
    name: Domain
    description: What domain do you want to bind to?
```

**使用場景：**
- Web 應用需要綁定網域
- 使用者可輸入自訂網域或使用 Zeabur 提供的 `.zeabur.app`

**在服務中使用：**
```yaml
services:
  - name: app
    domainKey: PUBLIC_DOMAIN  # 綁定這個變數
```

#### STRING 類型

用於一般文字輸入：

```yaml
variables:
  - key: ADMIN_EMAIL
    type: STRING
    name: Admin Email
    description: Email address for the admin user
```

**使用場景：**
- 管理員 email
- 應用名稱
- 其他自訂設定

### 6.3 使用者變數範例

```yaml
spec:
    variables:
      # 網域變數
      - key: PUBLIC_DOMAIN
        type: DOMAIN
        name: Domain
        description: What domain do you want to bind to?

      # 管理員密碼
      - key: ADMIN_PASSWORD
        type: STRING
        name: Admin Password
        description: Password for the admin user (min 8 characters)

      # 應用名稱
      - key: APP_NAME
        type: STRING
        name: Application Name
        description: Display name for your application
```

### 6.4 在服務中使用變數

```yaml
services:
  - name: app
    domainKey: PUBLIC_DOMAIN  # 使用網域變數

    spec:
      env:
        # 使用字串變數
        ADMIN_PASSWORD:
          default: ${ADMIN_PASSWORD}
          readonly: true

        APP_NAME:
          default: ${APP_NAME}
          readonly: true

        # 使用完整 URL（不是 PUBLIC_DOMAIN！）
        APP_URL:
          default: ${ZEABUR_WEB_URL}
          readonly: true
```

### ✅ 使用者變數檢查清單

- [ ] `key` 使用大寫和底線（如 `PUBLIC_DOMAIN`）
- [ ] `type` 正確（`DOMAIN` 或 `STRING`）
- [ ] `name` 清楚易懂（顯示給使用者的標題）
- [ ] `description` 說明清楚（包含格式要求）
- [ ] DOMAIN 變數有對應的 `domainKey` 設定
- [ ] 變數在服務的 `env` 中有使用

### 💡 最佳實踐

**描述要清楚：**
```yaml
# ✅ 推薦：說明清楚，包含要求
description: Password for the admin user (min 8 characters)
description: What domain do you want to bind to?

# ❌ 避免：太簡短
description: Password
description: Domain
```

**合理的變數數量：**
```yaml
# ✅ 推薦：只要求必要的資訊
variables:
  - key: PUBLIC_DOMAIN
    type: DOMAIN
  - key: ADMIN_PASSWORD
    type: STRING

# ❌ 避免：太多變數讓使用者困惑
variables:
  - key: VAR1
  - key: VAR2
  - key: VAR3
  # ... 10+ 個變數
```

### ⚠️ 常見錯誤

❌ **在環境變數中直接使用 PUBLIC_DOMAIN 作為 URL**
```yaml
env:
  APP_URL:
    default: https://${PUBLIC_DOMAIN}  # 如果使用者輸入 "myapp"，會是 https://myapp
```

✅ **使用 ZEABUR_WEB_URL**
```yaml
env:
  APP_URL:
    default: ${ZEABUR_WEB_URL}  # 完整 URL: https://myapp.zeabur.app
```

---

## 步驟 7: 撰寫使用說明

README 是使用者部署後看到的第一份文件，應該包含清楚的使用指引。

### 7.1 README 結構

```yaml
spec:
    readme: |
      # ServiceName

      Brief introduction to the service.

      ## Getting Started

      1. Open `https://${PUBLIC_DOMAIN}`
      2. Login with default credentials
      3. Complete the setup wizard

      ## Default Credentials

      - Username: `admin`
      - Password: See environment variable `ADMIN_PASSWORD`

      ## Configuration

      ### Environment Variables

      - `DATABASE_URL`: PostgreSQL connection string
      - `APP_URL`: Public URL of the application

      ## Documentation

      - [Official Documentation](https://example.com/docs)
      - [GitHub Repository](https://github.com/example/repo)
      - [Community Forum](https://forum.example.com)

      ## Support

      - Report issues: [GitHub Issues](https://github.com/example/repo/issues)
      - Discord: [Join our server](https://discord.gg/example)
```

### 7.2 必須包含的內容

#### 1. 服務簡介

```markdown
# PostgreSQL

PostgreSQL is a powerful, open source object-relational database system
with over 35 years of active development.
```

#### 2. 快速開始

```markdown
## Getting Started

1. Wait for the service to start (usually 30-60 seconds)
2. Connect using the following credentials:
   - Host: `${POSTGRES_HOST}`
   - Port: `${POSTGRES_PORT}`
   - User: `${POSTGRES_USER}`
   - Password: `${POSTGRES_PASSWORD}`
```

#### 3. 預設憑證（如適用）

```markdown
## Default Credentials

- Admin Email: `admin@example.com`
- Admin Password: Check the `ADMIN_PASSWORD` environment variable
```

#### 4. 重要配置

```markdown
## Configuration

### Database Connection

The database connection string is available in the `DATABASE_URL` environment variable:

\```
postgresql://user:password@host:port/database
\```

### Custom Domain

To use a custom domain:
1. Go to service settings
2. Navigate to "Domains"
3. Add your custom domain
```

#### 5. 文件連結

```markdown
## Documentation

- [Official Documentation](https://www.postgresql.org/docs/)
- [GitHub Repository](https://github.com/postgres/postgres)
```

### 7.3 使用變數插值

在 README 中可以使用變數，會自動替換：

```markdown
## Access Your Service

Open your service at: `https://${PUBLIC_DOMAIN}`

## Database Connection

- Host: `${POSTGRES_HOST}`
- Port: `${POSTGRES_PORT}`
- Database: `${POSTGRES_DB}`
```

**注意：** 實際顯示時這些會被替換成真實值

### ✅ README 檢查清單

- [ ] 包含服務簡介
- [ ] 包含快速開始步驟
- [ ] 列出預設憑證（如有）
- [ ] 說明重要的環境變數
- [ ] 包含官方文件連結
- [ ] 使用 Markdown 格式
- [ ] 變數使用 `${}` 格式
- [ ] 內容清楚易懂

### 💡 最佳實踐

**使用清單和步驟：**
```markdown
## Getting Started

1. Step one
2. Step two
3. Step three
```

**使用程式碼區塊：**
````markdown
## Connection String

```bash
postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
```
````

**使用表格（如適用）：**
```markdown
## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_USER` | Database user | `postgres` |
| `POSTGRES_DB` | Database name | `postgres` |
```

### ⚠️ 常見錯誤

❌ **README 太簡短**
```yaml
readme: |
  PostgreSQL database
```

✅ **包含完整資訊**
```yaml
readme: |
  # PostgreSQL

  PostgreSQL is a powerful, open source object-relational database system.

  ## Getting Started

  Connect using:
  - Host: ${POSTGRES_HOST}
  - Port: ${POSTGRES_PORT}

  ## Documentation

  https://www.postgresql.org/docs/
```

---

## 步驟 8: 測試部署

在添加多語系之前，**必須先測試部署確保功能正常**。

### 8.1 本地驗證

#### 1. VS Code Schema 驗證

確保沒有紅色波浪線錯誤：

- ✅ 所有必填欄位已填寫
- ✅ 型別正確
- ✅ 格式符合規範

#### 2. 手動檢查

**基本結構：**
- [ ] `apiVersion: zeabur.com/v1`
- [ ] `kind: Template`
- [ ] `metadata.name` 存在
- [ ] `spec.services` 至少有一個服務

**圖片資源：**

**方法 1: 使用瀏覽器測試**
```
1. 在瀏覽器中分別開啟每個圖片 URL
2. 確認圖片正常顯示
```

**方法 2: 使用命令列測試**
```bash
# 測試所有圖片 URL
curl -I https://example.com/icon.svg
curl -I https://example.com/cover.webp
curl -I https://example.com/service-icon.svg
# 預期回應: HTTP/2 200
```

### 8.2 使用 Zeabur CLI 部署

#### 1. 登入 Zeabur

```bash
npx zeabur@latest auth login
```

#### 2. 部署模板

```bash
# 在模板檔案所在目錄執行
npx zeabur@latest template deploy zeabur-template-my-service.yaml
```

**預期輸出：**
```
✓ Template validated
✓ Uploading template
✓ Template deployed successfully
✓ URL: https://dash.zeabur.com/templates/ABC123
```

### 8.3 功能測試

部署成功後，進行以下測試：

#### 測試 1: 服務啟動

- [ ] 所有服務都成功啟動
- [ ] 沒有服務處於 "Error" 狀態
- [ ] 日誌沒有明顯錯誤

#### 測試 2: 環境變數

檢查服務的環境變數頁面：

- [ ] 所有環境變數都正確顯示
- [ ] `${PASSWORD}` 已被替換成實際密碼
- [ ] `${ZEABUR_WEB_URL}` 顯示完整 URL
- [ ] 引用的變數（如 `${POSTGRES_HOST}`）有正確的值

#### 測試 3: 網域綁定

- [ ] 網域自動綁定成功
- [ ] 可以透過網域存取服務
- [ ] HTTPS 正常運作

#### 測試 4: 服務功能

- [ ] 服務的基本功能正常
- [ ] 資料庫連接成功（如適用）
- [ ] 登入功能正常（如適用）

#### 測試 5: 資料持久化

```bash
# 重啟服務
# 確認資料沒有遺失
```

### 8.4 常見部署問題

#### 問題 1: 服務啟動失敗

**檢查：**
```bash
# 在 Zeabur 服務頁面查看日誌
# 常見原因：
# - 環境變數缺失
# - 埠號配置錯誤
# - Volume 路徑錯誤
```

**解決：**
- 檢查日誌中的錯誤訊息
- 確認環境變數都有定義
- 確認 Docker 映像可以正常執行

#### 問題 2: 無法連接資料庫

**檢查：**
- [ ] 資料庫服務是否啟動
- [ ] 應用服務的 `dependencies` 是否包含資料庫
- [ ] `DATABASE_URL` 是否正確組合
- [ ] 資料庫環境變數是否 `expose: true`

#### 問題 3: 網域無法存取

**檢查：**
- [ ] `domainKey` 是否正確設定
- [ ] 埠號類型是否為 `HTTP`
- [ ] 服務是否在正確的埠號監聽

#### 問題 4: 圖片無法顯示

**檢查：**

**方法 1: 瀏覽器測試**
```
1. 複製圖片 URL 到瀏覽器
2. 確認圖片可以正常顯示
3. 檢查是否有 404、403 等錯誤
```

**方法 2: 命令列測試**
```bash
# 測試圖片 URL
curl -I https://example.com/icon.svg
# 預期: HTTP/2 200
```

**常見問題：**
- URL 錯誤或失效
- CORS 限制
- 檔案不存在

### ✅ 測試部署檢查清單

- [ ] 本地 Schema 驗證通過
- [ ] 所有圖片 URL 可存取
- [ ] Zeabur CLI 部署成功
- [ ] 所有服務正常啟動
- [ ] 環境變數正確顯示
- [ ] 網域綁定成功
- [ ] 服務基本功能正常
- [ ] 資料持久化正常（如適用）

### 💡 最佳實踐

**分階段測試：**
```
1. 先測試資料庫服務單獨部署
2. 再加入應用服務測試
3. 最後測試完整堆疊
```

**保留測試部署：**
- 第一次成功的部署不要刪除
- 可用於之後的對照和除錯

**記錄問題：**
- 建立問題清單記錄遇到的錯誤
- 記錄解決方法供之後參考

---

## 步驟 9: 添加多語系支援

**⚠️ 重要：只有在確認部署成功後，才添加多語系**

### 9.1 支援的語言

- `en-US`：英文（預設，寫在 `spec` 中）
- `zh-TW`：繁體中文（台灣、香港、澳門）
- `zh-CN`：簡體中文（中國大陸）
- `ja-JP`：日文
- `es-ES`：西班牙文
- `id-ID`：印尼文

### 9.2 可本地化的內容

```yaml
localization:
    zh-TW:
      description: |
        繁體中文描述

      # coverImage: https://example.com/screenshot-zh-TW.webp  # 可選：語言專屬圖片（必須是完整 URL）

      variables:
        - key: PUBLIC_DOMAIN
          name: 網域
          description: 你想綁定哪個網域？

      readme: |
        # 繁體中文 README
```

### 9.3 翻譯流程

#### 步驟 1: 複製英文內容

```yaml
# 原始英文（在 spec 中）
spec:
    description: |
      PostgreSQL is a powerful, open source object-relational database system.

    variables:
      - key: PUBLIC_DOMAIN
        type: DOMAIN
        name: Domain
        description: What domain do you want to bind to?

    readme: |
      # PostgreSQL

      Getting started...

# 複製到 localization
localization:
    zh-TW:
      description: |
        PostgreSQL 是一個功能強大的開源物件關聯式資料庫系統。

      variables:
        - key: PUBLIC_DOMAIN
          type: DOMAIN
          name: 網域
          description: 你想綁定哪個網域？

      readme: |
        # PostgreSQL

        開始使用...
```

#### 步驟 2: 翻譯各語言

**繁體中文（zh-TW）範例：**

```yaml
localization:
    zh-TW:
      description: |
        PostgreSQL 是一個功能強大的開源物件關聯式資料庫系統，
        擁有超過 35 年的活躍開發歷史。

      variables:
        - key: PUBLIC_DOMAIN
          type: DOMAIN
          name: 網域
          description: 你想綁定哪個網域？

        - key: ADMIN_PASSWORD
          type: STRING
          name: 管理員密碼
          description: 管理員使用者的密碼（至少 8 個字元）

      readme: |
        # PostgreSQL

        PostgreSQL 是一個功能強大的開源物件關聯式資料庫系統。

        ## 開始使用

        1. 等待服務啟動（通常需要 30-60 秒）
        2. 使用以下憑證連接：
           - 主機：`${POSTGRES_HOST}`
           - 埠號：`${POSTGRES_PORT}`
           - 使用者：`${POSTGRES_USER}`
           - 密碼：`${POSTGRES_PASSWORD}`

        ## 文件

        - [官方文件](https://www.postgresql.org/docs/)
        - [GitHub 倉庫](https://github.com/postgres/postgres)
```

**簡體中文（zh-CN）範例：**

```yaml
    zh-CN:
      description: |
        PostgreSQL 是一个功能强大的开源对象关系型数据库系统，
        拥有超过 35 年的活跃开发历史。

      variables:
        - key: PUBLIC_DOMAIN
          type: DOMAIN
          name: 域名
          description: 你想绑定哪个域名？

        - key: ADMIN_PASSWORD
          type: STRING
          name: 管理员密码
          description: 管理员用户的密码（至少 8 个字符）

      readme: |
        # PostgreSQL

        PostgreSQL 是一个功能强大的开源对象关系型数据库系统。

        ## 开始使用

        1. 等待服务启动（通常需要 30-60 秒）
        2. 使用以下凭证连接：
           - 主机：`${POSTGRES_HOST}`
           - 端口：`${POSTGRES_PORT}`
           - 用户：`${POSTGRES_USER}`
           - 密码：`${POSTGRES_PASSWORD}`

        ## 文档

        - [官方文档](https://www.postgresql.org/docs/)
        - [GitHub 仓库](https://github.com/postgres/postgres)
```

### 9.4 術語對照表

#### 常用技術術語

| 英文 | 繁體中文 | 簡體中文 |
|------|---------|---------|
| Server | 伺服器 | 服务器 |
| Database | 資料庫 | 数据库 |
| Configuration | 配置/設定 | 配置 |
| Connection | 連線 | 连接 |
| Domain | 網域 | 域名 |
| Port | 埠號 | 端口 |
| Authentication | 身份驗證 | 身份验证 |
| Authorization | 授權 | 授权 |
| Middleware | 中介層 | 中间件 |
| Documentation | 文件 | 文档 |
| Repository | 倉庫 | 仓库 |
| Deployment | 部署 | 部署 |
| Container | 容器 | 容器 |
| Volume | 資料卷 | 数据卷 |
| Environment Variable | 環境變數 | 环境变量 |

### 9.5 翻譯品質要求

#### ✅ 好的翻譯

- 使用正確的專業術語
- 保持語氣一致
- 注意繁簡體差異
- 所有語言版本資訊一致

#### ❌ 避免的翻譯

- 機器翻譯未經校對
- 術語不統一
- 遺漏重要資訊
- 格式錯誤

### 9.6 使用 AI 輔助翻譯

可以使用 AI 工具輔助翻譯，但務必：

1. **校對專業術語**
   - 確認資料庫相關術語正確
   - 確認技術名詞使用一致

2. **檢查格式**
   - Markdown 格式正確
   - 變數 `${}` 沒有被翻譯
   - 連結 URL 保持不變

3. **測試變數**
   - `${POSTGRES_HOST}` ✅
   - `${POSTGRES_主機}` ❌（不要翻譯變數名）

### ✅ 多語系檢查清單

- [ ] 至少包含 3 種語言（en-US, zh-TW, zh-CN）
- [ ] 每種語言都包含 `description`
- [ ] 每種語言都包含 `variables`（如有）
- [ ] 每種語言都包含 `readme`
- [ ] 所有變數的 `key` 和 `type` 保持一致
- [ ] 術語翻譯正確且一致
- [ ] 變數名稱（`${}`）未被翻譯
- [ ] URL 連結保持不變
- [ ] Markdown 格式正確

### 💡 最佳實踐

**翻譯順序：**
```
1. 英文（en-US）- 在 spec 中
2. 繁體中文（zh-TW）
3. 簡體中文（zh-CN）
4. 其他語言（選填）
```

**保持一致性：**
```yaml
# 所有語言的 variables 都要包含相同的 key
spec:
    variables:
      - key: PUBLIC_DOMAIN  # 必須在所有語言版本中出現

localization:
    zh-TW:
      variables:
        - key: PUBLIC_DOMAIN  # 同樣的 key
    zh-CN:
      variables:
        - key: PUBLIC_DOMAIN  # 同樣的 key
```

### ⚠️ 常見錯誤

❌ **翻譯了變數名稱**
```yaml
readme: |
  主機：${POSTGRES_主機}  # 錯誤！
```

✅ **保持變數原樣**
```yaml
readme: |
  主機：`${POSTGRES_HOST}`  # 正確
```

❌ **遺漏某些語言的變數**
```yaml
localization:
    zh-TW:
      variables:
        - key: PUBLIC_DOMAIN
        - key: ADMIN_PASSWORD

    zh-CN:
      variables:
        - key: PUBLIC_DOMAIN  # 遺漏 ADMIN_PASSWORD
```

✅ **所有語言包含相同變數**
```yaml
localization:
    zh-TW:
      variables:
        - key: PUBLIC_DOMAIN
        - key: ADMIN_PASSWORD

    zh-CN:
      variables:
        - key: PUBLIC_DOMAIN
        - key: ADMIN_PASSWORD
```

---

## 步驟 10: 提交模板

完成所有步驟後，就可以提交你的模板了。

### 10.1 最終檢查

使用 [檢查清單](CHECKLIST.md) 進行完整檢查：

```bash
# 1. Schema 驗證
# VS Code 應該沒有錯誤提示

# 2. 測試所有圖片
# 方法 A: 在瀏覽器中開啟每個 URL，確認圖片顯示
# 方法 B: 使用命令列
curl -I https://example.com/icon.svg
curl -I https://example.com/cover.webp

# 3. 部署測試
npx zeabur@latest template deploy zeabur-template-my-service.yaml

# 4. 功能測試
# 確認所有服務正常運作
```

### 10.2 準備 Pull Request

```bash
# 1. Fork zeabur/zeabur 倉庫
# 2. Clone 你的 fork
git clone https://github.com/your-username/zeabur-template.git

# 3. 建立新分支
git checkout -b add-myservice-template

# 4. 加入你的模板
git add my-service/
git commit -m "feat: add MyService template"

# 5. Push 到你的 fork
git push origin add-myservice-template

# 6. 建立 Pull Request
# 在 GitHub 上建立 PR
```

### 10.3 PR 描述範本

```markdown
## 新增模板：MyService

### 模板資訊

- **服務名稱**：MyService
- **類別**：Database / Application / Tool
- **Docker 映像**：myservice/myservice:1.0.0
- **測試部署**：✅ 已成功部署

### 功能特色

- 支援 PostgreSQL 資料庫
- 自動配置環境變數
- 包含完整的多語系支援（en-US, zh-TW, zh-CN）

### 檢查清單

- [x] 模板通過 schema 驗證
- [x] 包含完整的多語系翻譯
- [x] 提供截圖（screenshot.webp）
- [x] 所有圖片資源可正常存取
- [x] 已在 Zeabur 平台測試部署成功
- [x] README 說明完整

### 相關連結

- 服務官網：https://myservice.com
- Docker Hub：https://hub.docker.com/r/myservice/myservice
- 測試部署：https://dash.zeabur.com/templates/ABC123

### 截圖

![MyService Screenshot](./screenshot.webp)
```

### ✅ 提交檢查清單

- [ ] 所有檔案都已加入 Git
- [ ] Commit 訊息清楚明確
- [ ] PR 描述完整
- [ ] 包含測試部署連結
- [ ] 包含截圖
- [ ] 通過所有檢查

### 💡 最佳實踐

**Commit 訊息格式：**
```bash
# ✅ 推薦：使用 Conventional Commits
feat: add PostgreSQL template
fix: correct environment variable configuration
docs: update README for PostgreSQL template

# ❌ 避免：模糊的訊息
git commit -m "update"
git commit -m "fix bug"
```

**PR 標題：**
```
✅ feat: add PostgreSQL High Availability template
✅ fix: correct icon URL in Redis template
❌ Add template
❌ Update
```

---

## 完成！🎉

恭喜你完成了 Zeabur 模板的製作！

### 下一步

1. **等待審核**
   - Zeabur 團隊會審核你的 PR
   - 可能會有修改建議

2. **回應反饋**
   - 根據建議修改模板
   - 推送更新到 PR

3. **合併後**
   - 模板會出現在 Zeabur 平台
   - 所有使用者都可以使用

### 參考資源

- [Docker Compose 轉換指南](DOCKER_COMPOSE_MIGRATION.md)
- [疑難排解](TROUBLESHOOTING.md)
- [最佳實踐](BEST_PRACTICES.md)
- [技術參考](REFERENCE.md)
- [檢查清單](CHECKLIST.md)

### 需要協助？

- 📖 查看 [疑難排解](TROUBLESHOOTING.md)
- 💬 加入 [Zeabur Discord](https://discord.gg/zeabur)
- 🐛 回報問題到 [GitHub Issues](https://github.com/zeabur/zeabur/issues)

---

**感謝你為 Zeabur 社群做出貢獻！** 🙌
