# Twenty 模板修正清單

**模板名稱：** Twenty  
**模板網址：** https://zeabur.com/templates/0RUT0O

## 📋 關於這份清單

這份清單整理了模板中需要修正的問題，協助製作人快速定位並修正錯誤。每個問題都標明了位置、具體修正內容和參考資訊。

---

## 🔴 必須修正

### 1. Twenty Worker 缺少啟動命令 ⚠️
- **Line 199-204**（spec 層級）
- 新增 `command: ["yarn", "worker:prod"]`（與 source 平行）

### 2. Twenty Worker 缺少圖示
- **Line 194**
- 新增 `icon` 欄位（參考其他服務, 如果跟 Twenty 是相同的就使用相同的 icon ）

### 3. Template 類型不統一
- **Line 198, 230**
- 改為 `template: PREBUILT_V2`

### 4. 本地化翻譯(可用 AI 翻譯)
- **Line 281 之後**（localization 區塊）
- **已有：** en-US（預設）、es-ES、ja-JP、zh-CN
- **缺少：** zh-TW（繁體中文）,id-ID（印尼文）

每個語言區段需包含：description + variables + readme

### 5. URL 設定錯誤（Twenty 主服務）
- **Line 243**（instructions.content）: 改為 `${ZEABUR_WEB_URL}`
- **Line 264**（env.SERVER_URL）: 改為 `${ZEABUR_WEB_URL}` 並加 `readonly: true`

**說明：** `${ZEABUR_WEB_URL}` 是 Zeabur 特殊變數，會自動取回設定在 `web` port 的完整網址（包含 https:// 和網域），不需要手動拼接。詳見 [環境變數文件](https://zeabur.com/docs/zh-TW/deploy/customize-prebuilt#environment-variable)

---

## ✅ 檢查表

- [ ] 1. Twenty Worker 啟動命令
- [ ] 2. Twenty Worker 圖示
- [ ] 3. 統一使用 PREBUILT_V2
- [ ] 4. 本地化翻譯缺少（zh-TW, id-ID）
- [ ] 5. 兩處 URL 修正

---

## 🔍 人工確認

- [ ] 部署後 Worker 是否正常執行背景任務
- [ ] 檢查所有圖示是否正常顯示
- [ ] 測試服務間連線是否正常
- [ ] 測試服務基本功能是否正常(例如：建立帳號、操作資料或建立 API Key...其他等)
