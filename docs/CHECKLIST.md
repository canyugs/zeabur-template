# Zeabur 模板製作檢查清單

使用這份檢查清單確保你的模板符合所有要求，提高製作成功率。

## 使用說明

- ✅ 完成項目
- ⚠️ 需要注意的項目
- 🔴 必須完成的項目

---

## 準備階段

### 環境設置

- [ ] Node.js 已安裝（v18+）
- [ ] Zeabur CLI 可正常使用（`npx zeabur@latest --version`）
- [ ] 已登入 Zeabur 帳號（`npx zeabur@latest auth login`）
- [ ] VS Code 已安裝 YAML 擴展
- [ ] Git 已安裝並配置

### 服務研究

- [ ] 已閱讀服務官方文件
- [ ] 已找到 Docker 映像名稱和標籤
- [ ] 已確認預設埠號和類型（HTTP/TCP）
- [ ] 已列出所有必要的環境變數
- [ ] 已確認資料持久化目錄
- [ ] 已確認服務依賴關係（資料庫、快取等）

### 圖片準備

- [ ] 已準備服務圖示（SVG 或 PNG，512x512px+）
- [ ] 已準備封面圖片（WebP，1200x630px）
- [ ] 所有圖片 URL 可公開存取
- [ ] 已測試圖片 URL
  - 方法 1: 在瀏覽器開啟 URL，確認圖片正常顯示
  - 方法 2: 使用 `curl -I <URL>` 檢查回傳 200 OK

---

## 開發階段

### 檔案結構

- [ ] 🔴 已建立服務目錄（小寫，連字號分隔）
- [ ] 🔴 檔案命名正確（`zeabur-template-{service-name}.yaml`）
- [ ] 🔴 第一行有 schema 註解
  ```yaml
  # yaml-language-server: $schema=https://schema.zeabur.app/template.json
  ```

### 基本資訊

- [ ] 🔴 `apiVersion: zeabur.com/v1`
- [ ] 🔴 `kind: Template`
- [ ] 🔴 `metadata.name` 已填寫（首字母大寫）
- [ ] `spec.description` 清楚描述服務（1-3 句話）
- [ ] `spec.icon` URL 正確且可存取
- [ ] `spec.coverImage` URL 正確且可存取
- [ ] `spec.tags` 已選擇適當分類

### 服務定義

- [ ] 🔴 至少有一個服務
- [ ] 每個服務都有唯一的 `name`（小寫）
- [ ] 每個服務都有 `icon`
- [ ] 🔴 `template` 設為 `PREBUILT_V2`
- [ ] Docker `image` 名稱和標籤正確（避免使用 `latest`）
- [ ] `ports` 定義正確（id, port, type）
- [ ] `volumes` 路徑正確（如適用）
- [ ] 依賴關係在 `dependencies` 中正確設定

---

## 環境變數配置

### 基本配置

- [ ] 🔴 所有必要的環境變數都已定義
- [ ] 變數命名使用大寫和底線（如 `DATABASE_URL`）
- [ ] 所有環境變數都有 `default` 值

### 密碼和密鑰

- [ ] ⚠️ 密碼使用 `${PASSWORD}` 自動生成（不要使用固定密碼）
- [ ] 敏感資訊使用變數或 `${PASSWORD}`
- [ ] 需要的密碼都有 `expose: true`

### URL 配置

- [ ] 🔴 **重要：** 應用 URL 使用 `${ZEABUR_WEB_URL}`，不是 `${PUBLIC_DOMAIN}`
- [ ] URL 相關變數設為 `readonly: true`
- [ ] OAuth callback URLs 使用完整 URL

**檢查範例：**
```yaml
# ✅ 正確
env:
  APP_URL:
    default: ${ZEABUR_WEB_URL}
    readonly: true

# ❌ 錯誤
env:
  APP_URL:
    default: https://${PUBLIC_DOMAIN}
```

### 服務間連接

- [ ] 連接資訊變數（HOST, PORT）使用 `${CONTAINER_HOSTNAME}` 和 `${PORT}`
- [ ] 連接資訊變數設為 `expose: true` 和 `readonly: true`
- [ ] 所有引用其他服務變數的服務都有設定 `dependencies`
- [ ] 資料庫連接字串正確組合

**檢查範例：**
```yaml
# 資料庫服務
services:
  - name: postgresql
    spec:
      env:
        POSTGRES_HOST:
          default: ${CONTAINER_HOSTNAME}
          expose: true  # ← 必須有
          readonly: true
        POSTGRES_PORT:
          default: ${DATABASE_PORT}
          expose: true
          readonly: true

# 應用服務
  - name: app
    dependencies:
      - postgresql  # ← 必須有
    spec:
      env:
        DATABASE_URL:
          default: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
          readonly: true
```

### Volume 配置

- [ ] Volume 路徑正確（查看服務文件）
- [ ] 不期望 Volume 有預設檔案
- [ ] 如需配置檔案，使用 `configs` 或 `init`

**常見資料目錄檢查：**
- [ ] PostgreSQL: `/var/lib/postgresql/data`
- [ ] MySQL: `/var/lib/mysql`
- [ ] MongoDB: `/data/db`
- [ ] Redis: `/data`

---

## 資源檢查

### 圖片資源

- [ ] 🔴 模板圖示（`spec.icon`）可正常存取
- [ ] 封面圖片（`spec.coverImage`）可正常存取
- [ ] 所有服務圖示（`services[].icon`）可正常存取
- [ ] 圖片在瀏覽器中正常顯示
- [ ] 圖片格式正確（SVG/PNG/WebP）
- [ ] 圖片大小合理（< 1MB）

**測試方法：**

**方法 1: 瀏覽器測試（推薦）**
```
1. 複製圖片 URL 到瀏覽器
2. 確認圖片正常顯示，沒有 404 錯誤
```

**方法 2: 命令列測試**
```bash
curl -I https://example.com/icon.svg
# 預期：HTTP/2 200
```

### 使用者變數（如有）

- [ ] `variables` 定義正確
- [ ] `key` 使用大寫底線（如 `PUBLIC_DOMAIN`）
- [ ] `type` 正確（`DOMAIN` 或 `STRING`）
- [ ] `name` 和 `description` 清楚易懂
- [ ] DOMAIN 變數有對應的 `domainKey` 設定

---

## 測試階段

### 本地驗證

- [ ] 🔴 VS Code 沒有紅色波浪線錯誤
- [ ] YAML 格式正確
- [ ] 所有必填欄位已填寫

### 部署測試（英文版）

⚠️ **重要：在添加多語系之前，必須先測試英文版部署成功**

- [ ] 🔴 執行 `npx zeabur@latest template deploy zeabur-template-{service-name}.yaml`
- [ ] 🔴 部署成功，取得模板 URL
- [ ] 🔴 所有服務正常啟動（無 Error 狀態）
- [ ] 檢查服務日誌，無明顯錯誤

### 功能測試

- [ ] 🔴 環境變數正確顯示在 Zeabur 平台
- [ ] `${PASSWORD}` 已被替換成實際密碼
- [ ] `${ZEABUR_WEB_URL}` 顯示完整 URL
- [ ] 引用的變數（如 `${POSTGRES_HOST}`）有正確的值
- [ ] 網域綁定成功
- [ ] 可以透過網域存取服務
- [ ] 服務的基本功能正常（登入、資料操作等）
- [ ] 資料持久化正常（重啟服務後資料仍存在）

### 服務間連接測試

- [ ] 應用服務可以連接資料庫
- [ ] 應用服務可以連接快取（如適用）
- [ ] Worker 可以連接資料庫（如適用）
- [ ] 沒有連接錯誤

---

## 文件撰寫

### README 內容

- [ ] 包含服務簡介
- [ ] 包含快速開始步驟
- [ ] 列出預設憑證（如有）
- [ ] 說明重要的環境變數
- [ ] 包含官方文件連結
- [ ] 使用 Markdown 格式
- [ ] 變數使用 `${}` 格式（如 `${POSTGRES_HOST}`）
- [ ] 內容清楚易懂，適合新使用者

---

## 多語系階段

⚠️ **只有在確認英文版部署成功後，才進行這個階段**

### 翻譯準備

- [ ] 英文版已完成並測試成功
- [ ] 🔴 準備翻譯全部 5 種語言（zh-TW, zh-CN, ja-JP, es-ES, id-ID）

### 繁體中文（zh-TW）

- [ ] 🔴 `localization.zh-TW.description` 已翻譯
- [ ] `localization.zh-TW.variables` 包含所有變數
- [ ] 所有變數的 `key` 和 `type` 與英文版相同
- [ ] 🔴 `localization.zh-TW.readme` 已翻譯
- [ ] 術語使用正確（伺服器、資料庫、網域等）
- [ ] 變數名稱（`${}`）未被翻譯
- [ ] URL 未被翻譯

### 簡體中文（zh-CN）

- [ ] 🔴 `localization.zh-CN.description` 已翻譯
- [ ] `localization.zh-CN.variables` 包含所有變數
- [ ] 所有變數的 `key` 和 `type` 與英文版相同
- [ ] 🔴 `localization.zh-CN.readme` 已翻譯
- [ ] 術語使用正確（服务器、数据库、域名等）
- [ ] 變數名稱（`${}`）未被翻譯
- [ ] URL 未被翻譯

### 日文（ja-JP）

- [ ] 🔴 `localization.ja-JP.description` 已翻譯
- [ ] `localization.ja-JP.variables` 包含所有變數
- [ ] 所有變數的 `key` 和 `type` 與英文版相同
- [ ] 🔴 `localization.ja-JP.readme` 已翻譯
- [ ] 術語使用正確
- [ ] 變數名稱（`${}`）未被翻譯
- [ ] URL 未被翻譯

### 西班牙文（es-ES）

- [ ] 🔴 `localization.es-ES.description` 已翻譯
- [ ] `localization.es-ES.variables` 包含所有變數
- [ ] 所有變數的 `key` 和 `type` 與英文版相同
- [ ] 🔴 `localization.es-ES.readme` 已翻譯
- [ ] 術語使用正確
- [ ] 變數名稱（`${}`）未被翻譯
- [ ] URL 未被翻譯

### 印尼文（id-ID）

- [ ] 🔴 `localization.id-ID.description` 已翻譯
- [ ] `localization.id-ID.variables` 包含所有變數
- [ ] 所有變數的 `key` 和 `type` 與英文版相同
- [ ] 🔴 `localization.id-ID.readme` 已翻譯
- [ ] 術語使用正確
- [ ] 變數名稱（`${}`）未被翻譯
- [ ] URL 未被翻譯

### 多語系驗證

- [ ] 再次部署測試，確認多語系顯示正常
- [ ] 切換語言時，內容正確顯示
- [ ] 變數在所有語言中都正確顯示

---

## 提交階段

### 最終檢查

- [ ] 所有圖片 URL 再次測試可存取
- [ ] VS Code 無錯誤提示
- [ ] 已在 Zeabur 平台成功部署
- [ ] 所有功能測試通過
- [ ] 多語系翻譯完整

### 準備提交

- [ ] 建立清楚的 commit 訊息（使用 Conventional Commits）
- [ ] 準備 PR 描述
- [ ] 包含測試部署連結
- [ ] 包含截圖

### PR 檢查清單

- [ ] 🔴 模板通過 schema 驗證
- [ ] 🔴 包含完整的多語系翻譯（zh-TW, zh-CN, ja-JP, es-ES, id-ID）
- [ ] 提供截圖（`screenshot.webp`）
- [ ] 🔴 所有圖片資源可正常存取且無破圖
- [ ] 🔴 已在 Zeabur 平台測試部署成功
- [ ] README 說明完整

### Git 提交

```bash
# 檢查檔案
git status

# 加入檔案
git add {service-name}/

# 提交（使用 Conventional Commits 格式）
git commit -m "feat: add {ServiceName} template"

# 推送
git push origin add-{service-name}-template
```

---

## 常見遺漏項目提醒

### ⚠️ 最容易遺漏的檢查項目

1. **環境變數**
   - [ ] 忘記設定 `expose: true`
   - [ ] 忘記設定 `dependencies`
   - [ ] URL 使用 `${PUBLIC_DOMAIN}` 而非 `${ZEABUR_WEB_URL}`

2. **圖片**
   - [ ] 圖片 URL 使用 GitHub blob 而非 raw URL
   - [ ] 圖片 URL 未測試是否可存取

3. **多語系**
   - [ ] 某些語言遺漏部分變數
   - [ ] 變數名稱被翻譯
   - [ ] 沒有測試多語系顯示

4. **測試**
   - [ ] 只在本地驗證，沒有實際部署測試
   - [ ] 部署後沒有測試功能

---

## 快速自檢命令

```bash
# 1. 測試所有圖片 URL
# 方法 A: 在瀏覽器中開啟每個 URL，確認圖片顯示正常
# 方法 B: 使用命令列
curl -I <icon-url>
curl -I <cover-image-url>

# 2. 驗證 YAML 格式（VS Code）
# 開啟檔案，檢查是否有紅色波浪線

# 3. 部署測試
npx zeabur@latest template deploy zeabur-template-{service-name}.yaml

# 4. 檢查 Git 狀態
git status
```

---

## 各階段預估時間

- **準備階段**：30-60 分鐘
- **開發階段**：1-3 小時
- **測試階段**：30-60 分鐘
- **多語系階段**：30-60 分鐘
- **提交階段**：15-30 分鐘

**總計**：約 3-6 小時（視服務複雜度而定）

---

## 需要協助？

如果在任何步驟遇到問題：

- 📖 查看 [疑難排解](TROUBLESHOOTING.md)
- 📚 查看 [完整製作指南](GUIDE.md)
- 💬 加入 [Zeabur Discord](https://discord.gg/zeabur)

---

**完成所有檢查後，恭喜你！你的模板已經準備好提交了！** 🎉

**列印提示：** 這份檢查清單可以列印出來，逐項勾選完成狀態。
