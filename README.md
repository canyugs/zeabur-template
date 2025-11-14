# Zeabur 模板撰寫指南

歡迎來到 Zeabur 模板撰寫指南！本專案提供完整的文件和工具，協助你為 Zeabur 平台撰寫高品質的服務模板。

## 什麼是 Zeabur 模板？

Zeabur 模板使用 YAML 格式定義，讓使用者可以一鍵部署完整的應用程式堆疊。無論是資料庫、應用服務還是完整的開發環境，都可以透過模板快速啟動。

## 快速導航

### 🚀 新手入門

- **[從零開始製作模板](docs/GUIDE.md)** - 詳細的步驟化指南，適合第一次撰寫模板
- **[Docker Compose 轉換指南](docs/DOCKER_COMPOSE_MIGRATION.md)** - 將現有的 docker-compose.yml 轉換成 Zeabur 模板
- **[檢查清單](docs/CHECKLIST.md)** - 完整的製作和發布檢查清單

### 📚 進階文件

- **[最佳實踐](docs/BEST_PRACTICES.md)** - 設計模式、命名規範、資源管理
- **[技術參考](docs/REFERENCE.md)** - 模板結構、內建變數、Schema 規範
- **[疑難排解](docs/TROUBLESHOOTING.md)** - 常見錯誤和解決方案

## 選擇適合你的指南

### 你是新手？
👉 從 **[完整製作指南](docs/GUIDE.md)** 開始，跟著步驟一步步完成

### 你有 Docker Compose 檔案？
👉 使用 **[轉換指南](docs/DOCKER_COMPOSE_MIGRATION.md)** 快速轉換

### 遇到問題？
👉 查看 **[疑難排解](docs/TROUBLESHOOTING.md)** 找解決方案

### 想了解最佳實踐？
👉 閱讀 **[最佳實踐](docs/BEST_PRACTICES.md)** 提升模板品質

## 範例模板

本倉庫包含多個實際範例供參考：

- **[Odoo](odoo/zeabur-template-odoo.yaml)** - 完整的 ERP 系統，包含 PostgreSQL 資料庫
- **[MetaMCP](MetaMCP/zeabur-template-metamcp.yaml)** - MCP 聚合器，展示雙服務依賴
- **[Twenty CRM](twentyCRM/)** - CRM 系統，完整的多服務架構

## 核心概念

### 模板結構

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
    services: []
localization:
    zh-TW: {}
    zh-CN: {}
```

### 關鍵特性

- **一鍵部署** - 使用者無需手動配置即可部署完整堆疊
- **環境變數管理** - 自動處理服務間的連接和配置
- **多語系支援** - 支援英文、繁中、簡中、日文、西班牙文、印尼文
- **網域自動綁定** - Zeabur 自動提供 .zeabur.app 網域

## 快速開始

### 1. 安裝工具

```bash
# 安裝 Zeabur CLI
npm install -g @zeabur/cli

# 或使用 npx（不需全域安裝）
npx zeabur@latest --version
```

### 2. 建立第一個模板

```bash
# 建立服務目錄
mkdir my-service
cd my-service

# 建立模板檔案
touch zeabur-template-my-service.yaml
```

### 3. 測試部署

```bash
# 登入 Zeabur
npx zeabur@latest auth login

# 部署測試
npx zeabur@latest template deploy zeabur-template-my-service.yaml
```

### 4. 完整流程

詳細步驟請參考 **[完整製作指南](docs/GUIDE.md)**

## 測試與驗證

### Schema 驗證

在 VS Code 中，第一行的 schema 註解會自動啟用驗證：

```yaml
# yaml-language-server: $schema=https://schema.zeabur.app/template.json
```

### 必要檢查

- ✅ 所有圖片 URL 可正常存取
- ✅ 環境變數配置正確
- ✅ 服務依賴關係正確
- ✅ 多語系翻譯完整（至少英文、繁中、簡中）
- ✅ README 說明清楚

完整檢查清單請參考 **[檢查清單](docs/CHECKLIST.md)**

## 貢獻指南

我們歡迎任何形式的貢獻！

### 提交模板

1. Fork 本倉庫
2. 建立新的服務目錄
3. 撰寫模板檔案（參考 [製作指南](docs/GUIDE.md)）
4. 準備截圖和圖示
5. 確認通過所有檢查（參考 [檢查清單](docs/CHECKLIST.md)）
6. 提交 Pull Request

### PR 檢查清單

- [ ] 模板通過 schema 驗證
- [ ] 包含完整的多語系翻譯
- [ ] 提供截圖（screenshot.webp）
- [ ] 所有圖片資源可正常存取
- [ ] 已在 Zeabur 平台測試部署成功
- [ ] README 說明完整

## 參考資源

- [Zeabur 官方文件](https://zeabur.com/docs)
- [Template Schema](https://schema.zeabur.app/template.json)
- [Prebuilt Service Schema](https://schema.zeabur.app/prebuilt.json)
- [Zeabur 範本倉庫](https://github.com/zeabur/zeabur)

## 需要協助？

- 📖 查看 [疑難排解](docs/TROUBLESHOOTING.md)
- 💬 加入 [Zeabur Discord](https://discord.gg/zeabur)
- 🐛 回報問題到 [GitHub Issues](https://github.com/zeabur/zeabur/issues)

## 授權

MIT License

---

**開始你的第一個模板：** [完整製作指南](docs/GUIDE.md) | [Docker Compose 轉換](docs/DOCKER_COMPOSE_MIGRATION.md)
