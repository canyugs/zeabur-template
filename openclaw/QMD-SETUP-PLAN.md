# QMD Setup Plan for OpenClaw Zeabur Template

## Goal

為 OpenClaw Zeabur 模板加入 QMD（本地搜尋 sidecar）支援，讓 OpenClaw 的 workspace memory 能透過 BM25 + 向量搜尋 + LLM reranking 進行語意搜尋，取代預設的全文搜尋。

## What is QMD

- [github.com/tobi/qmd](https://github.com/tobi/qmd) — 本地 CLI 搜尋引擎
- 結合 BM25 + 向量搜尋 + LLM reranking
- 需要 Bun runtime，首次使用時自動下載 ~2GB GGUF 模型
- OpenClaw 透過 `memory.backend: "qmd"` 設定啟用

## Implementation — 分階段

### Phase 1: Setup Script (done)

建立 `openclaw/setup-qmd.sh`，獨立的安裝腳本，不動現有的 YAML 或啟動腳本。

腳本流程：
1. 安裝 Bun（若尚未安裝）
2. 安裝 QMD（`bun install -g github:tobi/qmd`）
3. 建立 XDG 目錄（`~/.openclaw/agents/main/qmd/`）
4. 建立 QMD collection，索引 workspace memory 檔案
5. 建立索引（`qmd update` + `qmd embed`）
6. 注入 QMD 設定到 `openclaw.json`

設計原則：
- 冪等（idempotent）：可重複執行
- 容錯（fail-safe）：非關鍵步驟用 `|| true`
- 遵循現有風格：POSIX `/bin/sh`、`set -e`、`node -e` 操作 JSON

### Phase 2: Template Integration (future)

將 setup-qmd.sh 整合進 Zeabur 模板，需要：
- 在 `zeabur-template-openclaw-VTZ4FX.yaml` 加入 config 注入腳本到 `/opt/openclaw/setup-qmd.sh`
- 在 `startup.sh` 加入可選的 QMD 初始化呼叫
- 可能新增環境變數（如 `OPENCLAW_ENABLE_QMD=true`）控制是否啟用
- 考慮 QMD 的 ~2GB 模型下載對首次啟動時間的影響

### Phase 3: Runtime Integration (future)

- 確保 QMD daemon 在容器重啟後自動恢復
- 定期更新索引的排程（OpenClaw 內建 `update.interval` 設定）
- 監控 QMD 狀態與健康檢查

## Key Technical Details

| Item | Value |
|------|-------|
| Bun install | `curl -fsSL https://bun.sh/install \| bash` |
| QMD install | `bun install -g github:tobi/qmd` |
| QMD binary | `~/.bun/bin/qmd` |
| XDG config | `~/.openclaw/agents/main/qmd/xdg-config` |
| XDG cache | `~/.openclaw/agents/main/qmd/xdg-cache` |
| GGUF models (~2GB) | embedding-gemma-300M, qwen3-reranker-0.6B, qmd-query-expansion-1.7B |
| SQLite index | `$XDG_CACHE_HOME/qmd/index.sqlite` |
| OpenClaw config key | `memory.backend: "qmd"` |

## openclaw.json QMD Config Block

```json
{
  "memory": {
    "backend": "qmd",
    "citations": "auto",
    "qmd": {
      "includeDefaultMemory": true,
      "update": {
        "interval": "5m",
        "onBoot": true,
        "embedInterval": "5m"
      },
      "limits": {
        "maxResults": 6,
        "maxSnippetChars": 700,
        "maxInjectedChars": 4000,
        "timeoutMs": 4000
      }
    }
  }
}
```

## Container Environment

- Image: `ghcr.io/openclaw/openclaw:2026.2.2`（Linux）
- User: `node`, Home: `/home/node`
- Volume: `/home/node`（跨重啟持久化）
- State dir: `/home/node/.openclaw`（`$OPENCLAW_STATE_DIR`）
- Workspace: `/home/node/.openclaw/workspace`（`$OPENCLAW_WORKSPACE_DIR`）

## Files

- `openclaw/setup-qmd.sh` — Phase 1 安裝腳本 (done)
- `openclaw/QMD-SETUP-PLAN.md` — 本文件
