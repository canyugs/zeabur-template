# etcd 端口配置說明

本文檔解釋 etcd 集群使用的三個端口及其用途。

## 端口總覽

| 端口 | 類型 | 用途 | 訪問者 |
|------|------|------|--------|
| **2379** | HTTP/gRPC | Client API（客戶端連接） | 應用程式、etcdctl |
| **2380** | TCP/gRPC | Peer 通訊（集群內部） | etcd 節點之間 |
| **2381** | HTTP | Metrics 和 Health Check | 監控系統、Load Balancer |

---

## 端口詳解

### 🔵 Port 2379 - Client API

**用途：** 客戶端讀寫資料的主要端口

**提供的服務：**
- gRPC API (etcd v3 API)
- HTTP API (部分端點)
- Key-Value 操作
- Watch 訂閱
- 租約管理
- 交易操作

**使用範例：**
```bash
# 使用 etcdctl
etcdctl --endpoints=http://etcd1:2379 put mykey "myvalue"
etcdctl --endpoints=http://etcd1:2379 get mykey

# 使用 HTTP API
curl http://etcd1:2379/version
```

**配置：**
```yaml
--listen-client-urls=http://0.0.0.0:2379      # 監聽所有介面
--advertise-client-urls=http://etcd1:2379     # 告訴客戶端連接地址
```

---

### 🟢 Port 2380 - Peer Communication

**用途：** etcd 節點之間的內部通訊

**提供的服務：**
- Raft 共識協議
- Leader 選舉
- 日誌複製
- 心跳檢測
- 成員管理

**通訊流程：**
```
etcd1 ←→ etcd2  (2380)
  ↓       ↓
  └──→ etcd3 ←──┘ (2380)

所有節點通過 2380 端口互相通訊
```

**配置：**
```yaml
--listen-peer-urls=http://0.0.0.0:2380              # 監聽所有介面
--initial-advertise-peer-urls=http://etcd1:2380     # 告訴其他節點連接地址
```

**安全建議：**
- ⚠️ 不要暴露到公網
- 🔒 只允許集群成員訪問
- 🛡️ 生產環境應啟用 TLS

---

### 🟡 Port 2381 - Metrics & Health

**用途：** 監控指標和健康檢查的專用端口

**為什麼需要單獨的端口？**

在 etcd v3.4 之前，metrics 和 health check 都在 2379 端口上。但這會導致：
- ❌ HTTP 和 gRPC 混在同一端口
- ❌ 監控系統可能干擾客戶端流量
- ❌ 安全性問題（需要完全開放 2379）

使用獨立的 metrics 端口後：
- ✅ 分離監控流量和業務流量
- ✅ 可以單獨設置訪問權限
- ✅ 符合生產環境最佳實踐

**提供的端點：**

#### `/health`
```bash
curl http://etcd1:2381/health
# 回傳：{"health":"true"}
```

#### `/metrics`
```bash
curl http://etcd1:2381/metrics
# Prometheus 格式的指標
# etcd_server_has_leader 1
# etcd_server_proposals_committed_total 12345
# ...
```

#### `/readyz` (v3.4.29+)
```bash
curl http://etcd1:2381/readyz
# 檢查節點是否準備好服務流量

curl http://etcd1:2381/readyz?verbose
# [+]data_corruption ok
# [+]serializable_read ok
# [+]linearizable_read ok
# ok
```

#### `/livez` (v3.4.29+)
```bash
curl http://etcd1:2381/livez
# 檢查進程是否存活
```

**配置：**
```yaml
--listen-metrics-urls=http://0.0.0.0:2381
```

**Prometheus 配置範例：**
```yaml
scrape_configs:
  - job_name: 'etcd'
    static_configs:
      - targets:
        - 'etcd1:2381'
        - 'etcd2:2381'
        - 'etcd3:2381'
```

---

## 警告訊息解析

### ⚠️ 警告 1：單端口運行 HTTP 和 gRPC

```
"Running http and grpc server on single port. This is not recommended for production."
```

**原因：**
- 當沒有設置 `--listen-metrics-urls` 時，所有服務都在 2379 端口

**影響：**
- 🐢 性能：監控流量影響業務流量
- 🔒 安全：無法細粒度控制訪問權限
- 📊 監控：難以區分流量來源

**解決方案：**
```yaml
# ✅ 修正後
--listen-client-urls=http://0.0.0.0:2379      # 客戶端 API
--listen-metrics-urls=http://0.0.0.0:2381     # 監控端點（分離）
```

### ⚠️ 警告 2：使用默認名稱

```
"it isn't recommended to use default name, please set a value for --name..."
```

**原因：**
- etcd 默認名稱是 `default`
- 在集群中所有節點不能同名

**解決方案：**
```yaml
# ✅ 每個節點設置唯一名稱
--name=etcd1  # 節點 1
--name=etcd2  # 節點 2
--name=etcd3  # 節點 3
```

---

## 端口在 Zeabur 中的配置

### 1. 聲明端口

```yaml
ports:
  - id: client
    port: 2379
    type: HTTP      # Client API
  - id: peer
    port: 2380
    type: TCP       # Peer 通訊
  - id: metrics
    port: 2381
    type: HTTP      # 監控端點
```

### 2. 健康檢查

```yaml
healthCheck:
  type: HTTP
  port: metrics     # ✓ 使用 metrics 端口
  http:
    path: /health
```

**為什麼用 metrics 端口？**
- ✅ 不干擾客戶端流量（2379）
- ✅ 不干擾集群通訊（2380）
- ✅ 專門為監控設計

### 3. 啟動命令

```yaml
command:
  - --listen-client-urls=http://0.0.0.0:2379
  - --listen-peer-urls=http://0.0.0.0:2380
  - --listen-metrics-urls=http://0.0.0.0:2381  # ← 關鍵！
```

---

## 網路流量圖

```
┌─────────────────────────────────────────────────────┐
│                   外部訪問                            │
│                                                       │
│  應用程式 ──→ 2379 (Client API)                      │
│  Prometheus ──→ 2381 (Metrics)                       │
│  Load Balancer ──→ 2381 (Health Check)              │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│                   etcd1                               │
│                                                       │
│  Port 2379: gRPC/HTTP API (客戶端)                   │
│  Port 2380: Peer 通訊 ◄──┬──► etcd2:2380           │
│  Port 2381: Metrics/Health │                         │
│                            └──► etcd3:2380           │
└─────────────────────────────────────────────────────┘
```

---

## 安全最佳實踐

### 1. 端口訪問控制

```yaml
# 建議的防火牆規則

# Port 2379 (Client API)
- 允許：應用伺服器、開發者
- 限制：需要認證（生產環境）

# Port 2380 (Peer)
- 允許：只有 etcd 節點之間
- 禁止：外部訪問

# Port 2381 (Metrics)
- 允許：監控系統、Load Balancer
- 可選：設置只讀訪問
```

### 2. TLS 加密

生產環境應該啟用 TLS：

```yaml
# Client TLS
--cert-file=/path/to/server.crt
--key-file=/path/to/server.key
--client-cert-auth
--trusted-ca-file=/path/to/ca.crt

# Peer TLS
--peer-cert-file=/path/to/peer.crt
--peer-key-file=/path/to/peer.key
--peer-client-cert-auth
--peer-trusted-ca-file=/path/to/peer-ca.crt
```

### 3. 認證

```bash
# 啟用認證
etcdctl user add root
etcdctl auth enable

# 使用認證
etcdctl --user=root:password put key value
```

---

## 故障排查

### 端口衝突

```bash
# 檢查端口佔用
lsof -i :2379
lsof -i :2380
lsof -i :2381

# 或使用 netstat
netstat -tlnp | grep 237
```

### 連接測試

```bash
# 測試 Client API
curl http://etcd1:2379/version

# 測試 Metrics
curl http://etcd1:2381/metrics

# 測試 Health
curl http://etcd1:2381/health

# 測試 Peer（不應該通過 curl）
# Peer 端口使用 gRPC，無法直接 curl
```

### 查看日誌

```bash
# Docker Compose
docker logs etcd1

# Kubernetes
kubectl logs etcd1

# 查找端口相關錯誤
docker logs etcd1 2>&1 | grep -i "port\|listen\|bind"
```

---

## 參考資料

- [etcd Configuration Flags](https://etcd.io/docs/v3.6/op-guide/configuration/)
- [etcd Security Model](https://etcd.io/docs/v3.6/op-guide/security/)
- [etcd Monitoring](https://etcd.io/docs/v3.6/op-guide/monitoring/)
- [Prometheus Metrics](https://etcd.io/docs/v3.6/metrics/)
