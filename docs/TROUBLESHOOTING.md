# Zeabur 模板疑難排解

本文件整理了 Zeabur 模板製作過程中的常見錯誤和解決方案，協助快速定位和解決問題。

## 目錄

- [環境變數錯誤](#環境變數錯誤)
- [Volume 配置錯誤](#volume-配置錯誤)
- [網域和 URL 設定錯誤](#網域和-url-設定錯誤)
- [圖片資源問題](#圖片資源問題)
- [部署失敗問題](#部署失敗問題)
- [服務連接問題](#服務連接問題)
- [多語系錯誤](#多語系錯誤)
- [Schema 驗證錯誤](#schema-驗證錯誤)
- [效能問題](#效能問題)

---

## 環境變數錯誤

### 錯誤 1: 環境變數未定義或為空

#### 症狀
```
服務啟動失敗，日誌顯示：
Error: DATABASE_URL is not defined
或
Connection failed: undefined
```

#### 原因
1. 引用的環境變數沒有在依賴服務中暴露
2. 忘記設定 `expose: true`
3. 依賴關係未正確設定

#### 解決方案

❌ **錯誤做法**
```yaml
# 在 postgresql 服務中
env:
  POSTGRES_HOST:
    default: ${CONTAINER_HOSTNAME}
    # 忘記 expose: true

# 在 app 服務中
services:
  - name: app
    # 忘記 dependencies
    spec:
      env:
        DB_HOST:
          default: ${POSTGRES_HOST}  # 會是空的
```

✅ **正確做法**
```yaml
# 在 postgresql 服務中
env:
  POSTGRES_HOST:
    default: ${CONTAINER_HOSTNAME}
    expose: true  # ← 必須加上

# 在 app 服務中
services:
  - name: app
    dependencies:
      - postgresql  # ← 必須加上
    spec:
      env:
        DB_HOST:
          default: ${POSTGRES_HOST}
```

#### 檢查步驟
1. 確認變數有設定 `expose: true`
2. 確認服務有加入 `dependencies`
3. 檢查依賴服務的名稱是否正確
4. 在 Zeabur 平台查看環境變數頁面，確認值是否正確

---

### 錯誤 2: URL 配置錯誤

#### 症狀
```
應用顯示錯誤的 URL：
Expected: https://myapp.zeabur.app
Got: https://myapp
或
Redirect failed: invalid URL
```

#### 原因
直接使用 `${PUBLIC_DOMAIN}` 變數作為完整 URL，但這個變數只包含使用者輸入的部分（如 `myapp`），不包含完整網域。

#### 解決方案

❌ **錯誤做法**
```yaml
variables:
  - key: PUBLIC_DOMAIN
    type: DOMAIN

services:
  - name: app
    spec:
      env:
        APP_URL:
          default: https://${PUBLIC_DOMAIN}  # 會是 https://myapp
```

✅ **正確做法**
```yaml
variables:
  - key: PUBLIC_DOMAIN
    type: DOMAIN

services:
  - name: app
    domainKey: PUBLIC_DOMAIN  # 綁定網域
    spec:
      env:
        APP_URL:
          default: ${ZEABUR_WEB_URL}  # 完整 URL: https://myapp.zeabur.app
          readonly: true
```

#### 說明
- `PUBLIC_DOMAIN` 變數：用於讓使用者指定網域，Zeabur 會自動綁定
- `${ZEABUR_WEB_URL}` 變數：Zeabur 自動提供的完整 URL，包含協定和完整網域
- 在環境變數中需要 URL 時，永遠使用 `${ZEABUR_WEB_URL}`

詳見：[網域和 URL 設定錯誤](#網域和-url-設定錯誤)

---

### 錯誤 3: 密碼未自動生成

#### 症狀
```
服務使用預設密碼或空密碼
安全性警告
```

#### 原因
沒有使用 Zeabur 的 `${PASSWORD}` 變數自動生成密碼。

#### 解決方案

❌ **錯誤做法**
```yaml
env:
  ADMIN_PASSWORD:
    default: admin123  # 固定密碼，不安全
```

✅ **正確做法**
```yaml
env:
  ADMIN_PASSWORD:
    default: ${PASSWORD}  # Zeabur 自動生成安全密碼
    expose: true
```

---

### 錯誤 4: 環境變數循環引用

#### 症狀
```
部署失敗
或
變數值顯示為空
```

#### 原因
環境變數之間形成循環引用。

#### 範例

❌ **錯誤做法**
```yaml
env:
  VAR_A:
    default: ${VAR_B}
  VAR_B:
    default: ${VAR_A}  # 循環引用
```

✅ **正確做法**
```yaml
env:
  VAR_A:
    default: base_value
  VAR_B:
    default: ${VAR_A}  # 單向引用
```

---

## Volume 配置錯誤

### 錯誤 5: 期望 Volume 有預設檔案

#### 症狀
```
服務啟動失敗：
Error: config file not found at /app/config/app.yml
或
No such file or directory: /app/data/init.sql
```

#### 原因
**Zeabur 的 Volume 預設是空目錄**，不會包含任何檔案。

#### 解決方案

如果需要配置檔案，有兩種方法：

**方法 1: 使用 `configs` 注入檔案**

✅ **推薦**
```yaml
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

  volumes:
    - id: data
      dir: /app/data  # 用於執行時產生的資料
```

**方法 2: 使用 `init` 腳本建立檔案**

```yaml
spec:
  init:
    - id: setup-config
      command:
        - /bin/bash
        - -c
        - |
          cat > /app/config/app.yml <<EOF
          server:
            host: 0.0.0.0
            port: ${PORT}
          database:
            url: ${DATABASE_URL}
          EOF

  volumes:
    - id: config
      dir: /app/config
```

#### 使用場景
- **configs**：適合靜態配置檔案
- **volumes**：用於存放執行時產生的資料（資料庫、日誌、上傳檔案等）
- **init**：適合需要動態生成的配置

---

### 錯誤 6: Volume 路徑錯誤

#### 症狀
```
資料未持久化
重啟後資料消失
```

#### 原因
Volume 掛載路徑不正確，資料寫入到容器而非 Volume。

#### 解決方案

確認使用正確的資料目錄：

| 服務 | 正確路徑 |
|------|---------|
| PostgreSQL | `/var/lib/postgresql/data` |
| MySQL | `/var/lib/mysql` |
| MongoDB | `/data/db` |
| Redis | `/data` |

❌ **錯誤**
```yaml
volumes:
  - id: data
    dir: /var/lib/postgres  # 錯誤路徑
```

✅ **正確**
```yaml
volumes:
  - id: data
    dir: /var/lib/postgresql/data  # 正確路徑
```

---

## 網域和 URL 設定錯誤

### 錯誤 7: 應用 URL 不完整

這是最常見的錯誤之一！

#### 症狀
```
- 應用無法正確 redirect
- OAuth callback URL 錯誤
- Webhook URL 不正確
- 應用內部連結失效
```

#### 原因
在環境變數中直接使用 `${PUBLIC_DOMAIN}` 作為完整 URL。

#### 詳細說明

**使用者體驗流程：**
1. 使用者在部署時填寫 `PUBLIC_DOMAIN` 為：`myapp`
2. Zeabur 自動綁定網域為：`myapp.zeabur.app`
3. **但** `${PUBLIC_DOMAIN}` 變數的值仍然是：`myapp`（不是完整網域）
4. 如果設定 `APP_URL: https://${PUBLIC_DOMAIN}`，實際值會是：`https://myapp` ❌

#### 解決方案

```yaml
variables:
  # 這個變數給使用者填寫，用於網域綁定
  - key: PUBLIC_DOMAIN
    type: DOMAIN
    name: Domain
    description: What domain do you want to bind to?

services:
  - name: app
    domainKey: PUBLIC_DOMAIN  # ← 綁定網域（Zeabur 自動處理）

    spec:
      env:
        # 應用程式需要知道自己的完整 URL
        APP_URL:
          default: ${ZEABUR_WEB_URL}  # ✅ 完整 URL
          readonly: true

        NEXT_PUBLIC_URL:
          default: ${ZEABUR_WEB_URL}  # ✅ 完整 URL
          readonly: true

        # OAuth callback 範例
        OAUTH_CALLBACK_URL:
          default: ${ZEABUR_WEB_URL}/auth/callback  # ✅ 完整 URL
          readonly: true
```

#### 變數對照表

| 變數 | 用途 | 值範例 |
|------|------|--------|
| `PUBLIC_DOMAIN` | 使用者變數，用於網域綁定 | `myapp` |
| `${ZEABUR_WEB_URL}` | 完整 URL（含 https://） | `https://myapp.zeabur.app` |
| `${ZEABUR_WEB_DOMAIN}` | 完整網域（不含協定） | `myapp.zeabur.app` |

---

### 錯誤 8: 多埠號網域配置錯誤

#### 症狀
```
前端可以存取，但 API 無法存取
或
所有埠號都綁定到同一個網域
```

#### 原因
多埠號服務的 `domainKey` 配置不正確。

#### 解決方案

**單一網域（簡單方式）**
```yaml
services:
  - name: app
    domainKey: PUBLIC_DOMAIN  # 綁定到 web 埠
```

**多個網域（進階方式）**
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

    spec:
      ports:
        - id: web
          port: 3000
          type: HTTP
        - id: api
          port: 8080
          type: HTTP
```

---

## 圖片資源問題

### 錯誤 9: 圖片無法顯示

#### 症狀
```
在 Zeabur 模板頁面看到：
- 圖示顯示為破圖
- 封面圖片無法載入
- 顯示替代文字
```

#### 原因
1. 圖片 URL 無法公開存取
2. URL 錯誤或失效
3. CORS 限制
4. 圖片格式不支援

#### 檢查步驟

**方法 1: 使用瀏覽器（推薦，最簡單）**
```
1. 複製圖片 URL
2. 在瀏覽器新分頁貼上並開啟
3. 確認圖片正常顯示（不是 404 頁面或錯誤訊息）
```

**方法 2: 使用命令列**
```bash
# 測試圖片 URL
curl -I https://example.com/icon.svg

# 預期輸出：
HTTP/2 200
content-type: image/svg+xml
```

**檢查 URL 格式：**
```
# ✅ 正確: GitHub raw URL
https://raw.githubusercontent.com/user/repo/main/icon.svg

# ❌ 錯誤: GitHub blob URL（會顯示網頁而非圖片）
https://github.com/user/repo/blob/main/icon.svg
```

#### 解決方案

**使用 GitHub 圖片的正確方式：**

❌ **錯誤：GitHub 頁面 URL**
```yaml
icon: https://github.com/zeabur/service-icons/blob/main/marketplace/postgresql.svg
```

✅ **正確：GitHub raw URL**
```yaml
icon: https://raw.githubusercontent.com/zeabur/service-icons/main/marketplace/postgresql.svg
```

**推薦的圖片來源：**

1. **zeabur/service-icons 倉庫**（最推薦）
   ```yaml
   icon: https://raw.githubusercontent.com/zeabur/service-icons/main/marketplace/postgresql.svg
   ```

2. **服務官方 CDN**
   ```yaml
   icon: https://www.postgresql.org/media/img/about/press/elephant.png
   ```

3. **Simple Icons**
   ```yaml
   icon: https://cdn.simpleicons.org/postgresql
   ```

---

### 錯誤 10: 圖片格式不正確

#### 症狀
```
圖片檔案過大
載入速度慢
```

#### 建議格式

| 用途 | 推薦格式 | 建議尺寸 |
|------|---------|---------|
| 圖示（icon） | SVG（首選）或 PNG | 512x512px+ |
| 封面（coverImage） | WebP | 1200x630px |

#### 轉換工具

```bash
# PNG 轉 WebP
# 使用線上工具：https://cloudconvert.com/png-to-webp

# 或使用 cwebp 命令
cwebp -q 80 screenshot.png -o screenshot.webp
```

---

## 部署失敗問題

### 錯誤 11: 服務無法啟動

#### 症狀
```
在 Zeabur 平台看到：
- 服務狀態: Error
- 日誌顯示錯誤訊息
- 持續重啟
```

#### 常見原因和解決方案

**原因 1: 環境變數缺失**

檢查服務日誌中的錯誤訊息：
```
Error: DATABASE_URL is required
```

解決：確認所有必要的環境變數都已定義

**原因 2: 埠號配置錯誤**

```
Error: Port 3000 is already in use
或
Error: EADDRINUSE: address already in use
```

解決：
```yaml
# 確認埠號與應用程式監聽的埠號一致
ports:
  - id: web
    port: 3000  # 必須與應用程式內部監聽的埠號相同
    type: HTTP

env:
  PORT:
    default: "3000"  # 告訴應用程式監聽這個埠號
```

**原因 3: 健康檢查失敗**

應用啟動時間過長，Zeabur 認為服務失敗。

解決：確保應用程式：
- 在合理時間內啟動（<2 分鐘）
- 正確監聽指定埠號
- 沒有初始化錯誤

**原因 4: 記憶體不足**

```
Error: JavaScript heap out of memory
```

解決：
```yaml
spec:
  resourceUsage:
    memory: 2048  # 增加記憶體限制 (MiB)
```

---

### 錯誤 12: 資料庫連接失敗

#### 症狀
```
Error: connect ECONNREFUSED
或
Error: Connection timeout
或
FATAL: database "xxx" does not exist
```

#### 檢查步驟

1. **確認依賴關係**
   ```yaml
   services:
     - name: app
       dependencies:
         - postgresql  # ← 必須有
   ```

2. **確認連接字串正確**
   ```yaml
   env:
     DATABASE_URL:
       # 格式: postgresql://USER:PASSWORD@HOST:PORT/DATABASE
       default: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
       readonly: true
   ```

3. **確認資料庫服務已啟動**
   - 在 Zeabur 平台檢查資料庫服務狀態
   - 查看資料庫服務日誌

4. **確認環境變數已暴露**
   ```yaml
   # 在資料庫服務中
   env:
     POSTGRES_HOST:
       expose: true  # ← 必須有
     POSTGRES_PORT:
       expose: true  # ← 必須有
   ```

---

## 服務連接問題

### 錯誤 13: 服務間無法通訊

#### 症狀
```
服務 A 無法連接服務 B
Connection refused
或
Host not found
```

#### 原因
1. 依賴關係未設定
2. 連接資訊變數未暴露
3. 使用錯誤的主機名稱

#### 解決方案

```yaml
services:
  # 服務 B（被連接的服務）
  - name: redis
    spec:
      env:
        REDIS_HOST:
          default: ${CONTAINER_HOSTNAME}  # ← 使用 CONTAINER_HOSTNAME
          expose: true  # ← 必須暴露
        REDIS_PORT:
          default: ${DATABASE_PORT}
          expose: true

  # 服務 A（連接其他服務）
  - name: app
    dependencies:
      - redis  # ← 必須設定依賴
    spec:
      env:
        REDIS_URL:
          default: redis://${REDIS_HOST}:${REDIS_PORT}  # ← 使用暴露的變數
          readonly: true
```

#### 常見錯誤

❌ **使用固定主機名稱**
```yaml
env:
  REDIS_URL:
    default: redis://redis:6379  # 在 Zeabur 中不會運作
```

✅ **使用 Zeabur 變數**
```yaml
env:
  REDIS_URL:
    default: redis://${REDIS_HOST}:${REDIS_PORT}
```

---

## 多語系錯誤

### 錯誤 14: 變數在某些語言缺失

#### 症狀
```
切換語言時，某些欄位消失
或
部署時顯示錯誤：Missing variables in localization
```

#### 原因
不同語言的 `variables` 數量或 `key` 不一致。

#### 解決方案

所有語言版本必須包含相同的變數（`key` 和 `type` 相同）：

❌ **錯誤：變數不一致**
```yaml
spec:
  variables:
    - key: PUBLIC_DOMAIN
      type: DOMAIN
    - key: ADMIN_PASSWORD
      type: STRING

localization:
  zh-TW:
    variables:
      - key: PUBLIC_DOMAIN
        type: DOMAIN
      # 缺少 ADMIN_PASSWORD
```

✅ **正確：所有語言包含相同變數**
```yaml
spec:
  variables:
    - key: PUBLIC_DOMAIN
      type: DOMAIN
      name: Domain
    - key: ADMIN_PASSWORD
      type: STRING
      name: Admin Password

localization:
  zh-TW:
    variables:
      - key: PUBLIC_DOMAIN
        type: DOMAIN
        name: 網域
      - key: ADMIN_PASSWORD
        type: STRING
        name: 管理員密碼

  zh-CN:
    variables:
      - key: PUBLIC_DOMAIN
        type: DOMAIN
        name: 域名
      - key: ADMIN_PASSWORD
        type: STRING
        name: 管理员密码
```

---

### 錯誤 15: 翻譯了變數名稱

#### 症狀
```
環境變數無法正確替換
README 顯示 ${變數名} 而不是值
```

#### 原因
翻譯時把變數名稱（`${VARIABLE_NAME}`）也翻譯了。

#### 解決方案

❌ **錯誤：翻譯變數名稱**
```yaml
localization:
  zh-TW:
    readme: |
      連接到資料庫：
      主機: ${POSTGRES_主機}  # ← 錯誤！
      埠號: ${POSTGRES_埠號}  # ← 錯誤！
```

✅ **正確：保持變數名稱不變**
```yaml
localization:
  zh-TW:
    readme: |
      連接到資料庫：
      主機: ${POSTGRES_HOST}  # ← 正確
      埠號: ${POSTGRES_PORT}  # ← 正確
```

**規則：**
- ✅ 翻譯說明文字
- ❌ 不要翻譯 `${VARIABLE_NAME}`
- ❌ 不要翻譯 URL
- ❌ 不要翻譯程式碼

---

## Schema 驗證錯誤

### 錯誤 16: VS Code 顯示紅色波浪線

#### 症狀
```
VS Code 在某些欄位下顯示紅色波浪線
或
提示: Property 'xxx' is not allowed
```

#### 原因
1. 欄位名稱錯誤
2. 必填欄位缺失
3. 型別不正確
4. 結構層級錯誤

#### 解決方案

**常見欄位名稱錯誤：**

❌ **錯誤**
```yaml
spec:
  service:  # 應該是 services
    - name: app
```

✅ **正確**
```yaml
spec:
  services:  # 複數形式
    - name: app
```

**常見結構錯誤：**

❌ **錯誤：command 放錯位置**
```yaml
spec:
  source:
    image: myapp:latest
    command:  # ← 錯誤位置
      - node
      - server.js
```

✅ **正確：command 在 spec 層級**
```yaml
spec:
  source:
    image: myapp:latest
  command:  # ← 正確位置
    - node
    - server.js
```

#### 檢查步驟
1. 確認第一行有 schema 註解：
   ```yaml
   # yaml-language-server: $schema=https://schema.zeabur.app/template.json
   ```

2. 重新載入 VS Code 視窗：`Cmd/Ctrl + Shift + P` → `Reload Window`

3. 查看官方 Schema：https://schema.zeabur.app/template.json

---

## 效能問題

### 錯誤 17: 服務啟動緩慢

#### 症狀
```
部署完成但服務需要很長時間才能回應
或
第一次存取很慢
```

#### 可能原因

1. **映像太大**
   ```yaml
   # 使用輕量版映像
   image: node:20-alpine  # 好
   image: node:20  # 較大
   ```

2. **初始化腳本太複雜**
   ```yaml
   # 簡化 init 腳本
   init:
     - id: setup
       command:
         - /bin/sh
         - -c
         - |
           # 保持簡單快速
           echo "Setup complete"
   ```

3. **資料庫遷移**
   - 考慮使用獨立的遷移步驟
   - 避免在每次啟動時執行完整遷移

---

## 快速診斷指南

遇到問題時，按照這個順序檢查：

### 1. 檢查日誌
```
Zeabur 平台 → 服務 → Logs
查看錯誤訊息
```

### 2. 檢查環境變數
```
Zeabur 平台 → 服務 → Variables
確認所有變數都有值
```

### 3. 檢查服務狀態
```
所有依賴服務都在運行嗎？
```

### 4. 檢查模板配置
```
對照本文件的常見錯誤
使用檢查清單逐項確認
```

### 5. 本地測試
```bash
# 如果可能，先在本地測試
docker run -e ENV_VAR=value image:tag
```

---

## 取得協助

如果以上方案都無法解決問題：

1. **查看完整文件**
   - [製作指南](GUIDE.md)
   - [最佳實踐](BEST_PRACTICES.md)
   - [技術參考](REFERENCE.md)

2. **社群支援**
   - [Zeabur Discord](https://discord.gg/zeabur)
   - [GitHub Discussions](https://github.com/zeabur/zeabur/discussions)

3. **回報 Bug**
   - [GitHub Issues](https://github.com/zeabur/zeabur/issues)
   - 請附上：
     - 模板 YAML
     - 錯誤訊息
     - 服務日誌
     - 部署連結

---

## 預防錯誤的最佳實踐

1. **使用檢查清單**
   - 參考 [檢查清單](CHECKLIST.md)
   - 逐項檢查完成狀態

2. **先測試後多語系**
   - 先完成英文版
   - 確認部署成功
   - 再添加其他語言

3. **分階段開發**
   - 先完成基本功能
   - 測試基本流程
   - 逐步添加進階功能

4. **參考現有模板**
   - 查看本倉庫的範例
   - 學習成功的模式
   - 避免重複錯誤

---

**記住：大多數問題都可以透過仔細檢查環境變數配置來解決！** 🔍
