# moltbot 模板遷移指南

從舊版 moltbot Zeabur 模板升級到新版的遷移指南。

---

## ⚠️ 重要變更

### 設定檔路徑變更
| 項目 | 舊版 | 新版 |
|------|------|------|
| 設定檔 | `/home/node/.clawdbot/clawdbot.json` | `/home/node/.clawdbot/moltbot.json` |

### Volume 結構變更
| 項目 | 舊版 | 新版 |
|------|------|------|
| 設定 Volume | `/home/node/.clawdbot` (config) | `/home/node` (data) |
| 工作區 Volume | `/home/node/clawd` (workspace) | 包含在 `/home/node` 中 |

新版將兩個 Volume 合併為單一 `/home/node` Volume，簡化資料管理。

---

## 遷移步驟

### 步驟 1：備份現有資料

在 Zeabur 控制台開啟服務的 **檔案** 頁籤，瀏覽到以下路徑進行備份：

- `/home/node/.clawdbot/clawdbot.json` - 設定檔（右鍵下載）
- `/home/node/clawd/` - 工作區資料（如有需要）

記下您的重要設定，包括：
- 自訂模型設定
- API 金鑰（如有在設定檔中）
- 已配對的聊天平台

### 步驟 2：重新部署新版模板

1. 前往 [moltbot 模板頁面](https://zeabur.com/templates/VTZ4FX)
2. 點擊 **Deploy** 部署到同一個專案
3. 在環境變數中填入您的 API 金鑰

### 步驟 3：還原設定（如需要）

在新服務的 **檔案** 頁籤，上傳備份的設定檔到 `/home/node/.clawdbot/moltbot.json`。

### 步驟 4：重新配對聊天平台

由於 Volume 結構變更，您需要重新配對聊天平台：

**Telegram：**
1. 向您的機器人發送 `/start`
2. 取得配對碼後，在 **指令** 頁籤執行：
   ```bash
   moltbot pairing approve telegram <配對碼>
   ```

其他平台請參閱 [Channels 文件](https://docs.molt.bot/channels)。

---

## 新版特色

- 🔄 **自動更新**：使用 `main` tag，重啟時自動更新到最新版本
- 🛠️ **pi-ai 修正**：修正 Google Gemini CLI user agent 問題
- 📦 **簡化 Volume**：單一 Volume 管理所有資料

---

## 常見問題

### Q: 我的對話記錄會遺失嗎？
會。由於 Volume 結構變更，舊版的對話記錄無法自動遷移。建議在遷移前備份重要對話。

### Q: 遷移後模型設定會保留嗎？
如果您使用環境變數設定 API 金鑰（如 `ZEABUR_AI_HUB_API_KEY`），新版會自動配置對應的模型。自訂模型設定需要手動還原。

---

## 需要協助？

- [GitHub Issues](https://github.com/moltbot/moltbot/issues)
- [官方文件](https://docs.molt.bot)
