# Tailscale Setup Plan for OpenClaw Zeabur Template

## Goal

在 OpenClaw 容器中安裝 Tailscale，讓 OpenClaw gateway 透過 Tailscale 私有網路 (tailnet) 存取，提供 HTTPS + MagicDNS 自動憑證，不需暴露在公網。

## Key Discovery: OpenClaw Built-in Tailscale Support

OpenClaw gateway 內建 Tailscale Serve 整合（[docs](https://docs.openclaw.ai/web/control-ui#integrated-tailscale-serve-preferred)）：

```bash
openclaw gateway --tailscale serve
```

- Gateway 留在 loopback，Tailscale Serve 處理 HTTPS proxy
- 支援 Tailscale 身份認證（`tailscale-user-login` header），不需 token
- 透過 `gateway.auth.allowTailscale: true` 控制

**因此 setup script 只需：安裝 Tailscale → 啟動 tailscaled → 認證。OpenClaw 自己處理 serve。**

另一個選項（不推薦，無 HTTPS）：
```bash
openclaw gateway --bind tailnet --token "$(openssl rand -hex 32)"
```

## Why Same Container (Not Sidecar)

- `tailscale serve` [只支援 localhost backend](https://github.com/tailscale/tailscale/issues/8751)，無法 proxy 到跨服務 hostname
- Zeabur 不支援 Docker 的 `network_mode: service:`（共享網路棧）
- 因此 Tailscale 必須裝在同一容器，透過 `localhost:18789` 直通 OpenClaw gateway

## Tailscale Pricing

個人使用免費（[pricing](https://tailscale.com/pricing)）：

| Plan | Price | Users | Devices |
|------|-------|-------|---------|
| **Personal (Free)** | **$0** | 3 | 100 |
| Personal Plus | $5/mo | 6 | 100 |
| Starter | $6/user/mo | — | — |

免費方案包含所有核心功能：WireGuard 加密、MagicDNS、HTTPS 憑證、Tailscale Serve。

## Implementation — 分階段

### Phase 1: Setup Script (planned)

建立 `openclaw/setup-tailscale.sh`，獨立的安裝腳本。

腳本流程：
1. 檢查 `TS_AUTHKEY` → 未設定則跳過 (exit 0)
2. 偵測架構 (`uname -m` → amd64/arm64)
3. 安裝 Tailscale 二進位（靜態 tarball → `~/bin/`）
   - 從 `https://pkgs.tailscale.com/stable/` 下載
   - 已安裝且版本一致則跳過
4. 啟動 tailscaled（背景執行，userspace networking）
   - `--tun=userspace-networking`（非 root 用戶）
   - `--statedir=~/.tailscale/state`
   - `--socket=~/.tailscale/tailscaled.sock`
   - 等待 socket ready（30 秒 timeout）
5. 認證（`tailscale up --authkey=$TS_AUTHKEY`）
   - 已認證（BackendState = Running）則跳過
   - `--hostname=$TS_HOSTNAME`（預設：openclaw）
6. 顯示狀態與後續步驟

設計原則：
- 冪等（idempotent）：可重複執行
- 容錯（fail-safe）：非關鍵步驟用 `|| true`
- 遵循現有風格：POSIX `/bin/sh`、`set -e`、`node -e` 解析 JSON
- `TS_AUTHKEY` 未設定時優雅跳過

### Phase 2: Gateway Integration (future)

修改 `start_gateway.sh`，偵測 tailscaled 是否運行，自動切換啟動模式：

```sh
#!/bin/sh
if tailscale --socket="$HOME/.tailscale/tailscaled.sock" status >/dev/null 2>&1; then
  # Tailscale available → use integrated serve (HTTPS, identity auth)
  exec node dist/index.js gateway --tailscale serve --allow-unconfigured
else
  # Fallback → standard HTTP with token
  exec node dist/index.js gateway --allow-unconfigured --bind "${OPENCLAW_GATEWAY_BIND}" --port "${OPENCLAW_GATEWAY_PORT}" --token "${OPENCLAW_GATEWAY_TOKEN}"
fi
```

需要：
- 修改 `zeabur-template-openclaw-VTZ4FX.yaml` 中的 `start_gateway.sh`
- 在 `startup.sh` 加入可選的 Tailscale 初始化
- 新增 `TS_AUTHKEY`、`TS_HOSTNAME` 環境變數到模板

### Phase 3: Template Integration (future)

- 在 YAML 模板加入 `setup-tailscale.sh` 作為 Zeabur config 注入
- 加入 `TS_AUTHKEY` 環境變數（使用者可選填）
- 更新使用說明文件

## Key Technical Details

| Item | Value |
|------|-------|
| Tailscale install | Static tarball from `pkgs.tailscale.com/stable/` |
| Binaries location | `~/bin/tailscale`, `~/bin/tailscaled` |
| State dir | `~/.tailscale/state/` (persistent) |
| Socket | `~/.tailscale/tailscaled.sock` |
| Logs | `~/.tailscale/tailscaled.log` |
| Networking mode | Userspace (`--tun=userspace-networking`) |
| No root needed | Yes (userspace mode) |
| OpenClaw flag | `openclaw gateway --tailscale serve` |

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `TS_AUTHKEY` | Yes | — | Tailscale auth key; script skips if unset |
| `TS_VERSION` | No | `1.82.5` | Tailscale version to install |
| `TS_HOSTNAME` | No | `openclaw` | Hostname on tailnet |
| `OPENCLAW_GATEWAY_PORT` | No | `18789` | Gateway port (already in template) |

## Access Result

| Method | URL | Auth |
|--------|-----|------|
| HTTPS (preferred) | `https://openclaw.tailnet-name.ts.net` | Tailscale identity (no token) |
| Direct (alternative) | `http://<tailscale-ip>:18789` | Token required |

## Container Environment

- Image: `ghcr.io/openclaw/openclaw:2026.2.2` (Linux)
- User: `node` (non-root) → 必須用 userspace networking
- Home/Volume: `/home/node` (persistent across restarts)
- Gateway port: 18789
- PATH: `/home/node/bin:/usr/local/sbin:...`

## File Layout

```
/home/node/
  bin/
    tailscale          # CLI binary
    tailscaled         # daemon binary
  .tailscale/
    state/             # persistent auth state (survives restart)
    tailscaled.sock    # unix socket for CLI ↔ daemon
    tailscaled.log     # daemon log output
```

## Files

- `openclaw/setup-tailscale.sh` — Phase 1 安裝腳本 (planned)
- `openclaw/TAILSCALE-SETUP-PLAN.md` — 本文件
