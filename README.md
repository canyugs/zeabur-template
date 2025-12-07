# Zeabur Template 範例集

這個儲存庫收集了各種 Zeabur 模板範例，可作為製作自己模板時的參考。

## 📖 官方文件

完整的模板製作說明請參考 **[Zeabur 官方文件 - 從 YAML 建立模板](https://zeabur.com/docs/zh-TW/template/template-in-code)**。

## 📁 模板列表

| 服務 | 說明 |
|------|------|
| [ClassroomIO](classroomio/) | 開源線上學習平台 |
| [Coze Loop](coze-loop/) | Coze 整合服務 |
| [ERPNext](erpnext/) | 開源 ERP 系統 |
| [etcd-cluster](etcd-cluster/) | etcd 分散式鍵值儲存叢集 |
| [FossFLOW](FossFLOW/) | 開源工作流程工具 |
| [Ghost](ghost/) | 開源部落格平台 |
| [Graphiti](graphiti/) | 圖形資料庫服務 |
| [MetaMCP](MetaMCP/) | MCP 聚合器 |
| [MinIO](minio/) | 高效能物件儲存 |
| [Odoo](odoo/) | 開源 ERP/CRM 系統 |
| [PostgreSQL AI Query](postgresql-ai-query/) | PostgreSQL + AI 查詢工具 |
| [PostgreSQL HA](postgresql-ha/) | PostgreSQL 高可用叢集 |
| [Postiz](postiz/) | 社群媒體管理工具 |
| [SillyTavern](sillyTavern/) | AI 角色扮演聊天介面 |
| [Supabase](supabase/) | 開源 Firebase 替代方案 |
| [Twenty CRM](twentyCRM/) | 現代化 CRM 系統 |
| [Wren AI](wrenai/) | AI 資料分析平台 |

## 🚀 快速開始

### 部署模板

```bash
# 使用 Zeabur CLI 部署
npx zeabur@latest template deploy -f <模板檔案.yaml>
```

### 上架模板

```bash
# 建立公開模板
npx zeabur@latest template create -f <模板檔案.yaml>
```

## 🔗 相關連結

- [Zeabur 官方文件](https://zeabur.com/docs)
- [從 YAML 建立模板](https://zeabur.com/docs/zh-TW/template/template-in-code)
- [Template Schema](https://schema.zeabur.app/template.json)
- [Zeabur Discord](https://discord.gg/zeabur)
