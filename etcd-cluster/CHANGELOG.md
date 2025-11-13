# Changelog

本文檔記錄 etcd cluster 模板的重要變更。

## [2025-11-14] - Zeabur 部署修復

### 修復 🐛

#### 1. 轉換為環境變數配置

**問題：**
- Zeabur PREBUILT 模板中使用 `command` 參數無法正確覆蓋配置
- etcd 容器忽略命令行參數，使用默認值
- 導致 name=default, 監聽 127.0.0.1, 2381 端口未啟動

**症狀：**
```
"local-member-attributes":"{Name:default ClientURLs:[http://localhost:2379]}"
"address":"127.0.0.1:2379"
[Zeabur] Startup probe failed: dial tcp 172.31.138.13:2381: connect: connection refused
```

**解決方案：**
```yaml
# ❌ 之前（不工作）
command:
  - /usr/local/bin/etcd
  - --name=etcd1
  - --listen-client-urls=http://0.0.0.0:2379
  - ...

# ✅ 之後（工作）
env:
  ETCD_NAME:
    default: etcd1
  ETCD_LISTEN_CLIENT_URLS:
    default: http://0.0.0.0:2379
  ETCD_LISTEN_METRICS_URLS:
    default: http://0.0.0.0:2381
  ...
```

**環境變數映射：**
| 命令行參數 | 環境變數 |
|-----------|---------|
| `--name` | `ETCD_NAME` |
| `--data-dir` | `ETCD_DATA_DIR` |
| `--listen-client-urls` | `ETCD_LISTEN_CLIENT_URLS` |
| `--listen-peer-urls` | `ETCD_LISTEN_PEER_URLS` |
| `--listen-metrics-urls` | `ETCD_LISTEN_METRICS_URLS` |
| `--advertise-client-urls` | `ETCD_ADVERTISE_CLIENT_URLS` |
| `--initial-advertise-peer-urls` | `ETCD_INITIAL_ADVERTISE_PEER_URLS` |
| `--initial-cluster` | `ETCD_INITIAL_CLUSTER` |
| `--initial-cluster-state` | `ETCD_INITIAL_CLUSTER_STATE` |
| `--initial-cluster-token` | `ETCD_INITIAL_CLUSTER_TOKEN` |

**影響：**
- ✅ etcd 正確使用配置的名稱（etcd1, etcd2, etcd3）
- ✅ 監聽所有介面（0.0.0.0）而非只監聽 127.0.0.1
- ✅ 2381 metrics 端口正確啟動
- ✅ 健康檢查可以正常工作

---

## [2025-11-14] - 生產環境優化

### 新增 ✨

#### 1. 獨立的 Metrics 端口 (2381)

**變更原因：**
- 修復警告："Running http and grpc server on single port. This is not recommended for production."
- 分離監控流量和業務流量
- 符合生產環境最佳實踐

**新增配置：**
```yaml
ports:
  - id: metrics
    port: 2381
    type: HTTP

command:
  - --listen-metrics-urls=http://0.0.0.0:2381
```

**影響：**
- `/metrics` 端點從 2379 移至 2381
- `/health`, `/readyz`, `/livez` 端點從 2379 移至 2381
- 健康檢查使用 2381 端口

**Docker Compose 端口映射：**
- etcd1: 2381 → 2381
- etcd2: 2391 → 2381
- etcd3: 2401 → 2381

### 修改 🔧

#### 1. Health Check 配置

**之前：**
```yaml
healthCheck:
  type: HTTP
  port: client  # 2379
  http:
    path: /readyz
```

**之後：**
```yaml
healthCheck:
  type: HTTP
  port: metrics  # 2381
  http:
    path: /health
```

**原因：**
- 避免健康檢查干擾客戶端流量
- 更可靠的監控分離

#### 2. 移除 Dependencies

**變更：**
```yaml
# 之前
- name: etcd2
  dependencies:
    - etcd1  # ← 移除

- name: etcd3
  dependencies:
    - etcd1  # ← 移除
    - etcd2  # ← 移除
```

**原因：**
- etcd 設計為並行啟動
- Raft 協議自動處理節點發現
- 加快集群啟動速度
- 符合 Docker Compose 的配置方式

#### 3. 修正 Advertise URLs

**之前：**
```yaml
--initial-advertise-peer-urls=http://${CONTAINER_HOSTNAME}:2380
--advertise-client-urls=http://${CONTAINER_HOSTNAME}:2379
```

**之後：**
```yaml
--initial-advertise-peer-urls=http://etcd1:2380
--advertise-client-urls=http://etcd1:2379
```

**原因：**
- 與 `--initial-cluster` 配置一致
- 使用 Zeabur 內部 DNS 服務名稱
- 確保節點能正確互相發現

### 新增文檔 📚

1. **PORTS.md** - 端口配置詳細說明
   - 三個端口的用途和區別
   - 警告訊息解析
   - 安全最佳實踐
   - 故障排查指南

2. **HEALTH_CHECKS.md** - 健康檢查端點說明
   - `/health`, `/readyz`, `/livez` 的區別
   - Kubernetes 集成範例
   - 詳細的輸出格式說明

3. **TESTING.md** - 測試指南
   - 本地和遠程測試
   - CI/CD 集成
   - 故障排查

4. **DEPLOYMENT.md** - 部署指南
   - 多種部署方式
   - 生產環境考量
   - 監控和備份策略

### 測試更新 🧪

#### test.sh 支援遠程測試

**新增功能：**
```bash
# 本地測試（Docker Compose）
./test.sh

# 遠程測試（Zeabur/生產環境）
ETCD_ENDPOINTS=https://etcd1.zeabur.app:2379,... ./test.sh

# 帶認證的遠程測試
ETCD_ENDPOINTS=... ETCD_USER=root ETCD_PASSWORD=secret ./test.sh
```

**測試覆蓋：**
- 自動檢測本地/遠程模式
- 20 個測試全部支援兩種模式
- 統一的測試輸出格式

---

## 端口變更總結

### Docker Compose

| 節點 | 之前 | 之後 |
|------|------|------|
| etcd1 | 2379, 2380 | 2379, 2380, **2381** |
| etcd2 | 2389, 2390 | 2389, 2390, **2391** |
| etcd3 | 2399, 2400 | 2399, 2400, **2401** |

### Zeabur Template

| 端口 | 用途 | 類型 |
|------|------|------|
| 2379 | Client API | HTTP |
| 2380 | Peer 通訊 | TCP |
| **2381** | **Metrics/Health** | **HTTP** (新增) |

---

## 遷移指南

### 從舊版本升級

如果你正在使用舊版本的模板，請按以下步驟升級：

#### 1. Docker Compose 用戶

```bash
# 停止舊集群
docker-compose down

# 拉取最新配置
git pull

# 啟動新集群
docker-compose up -d

# 驗證 metrics 端口
curl http://localhost:2381/metrics  # etcd1
curl http://localhost:2391/metrics  # etcd2
curl http://localhost:2401/metrics  # etcd3
```

#### 2. Zeabur 用戶

重新部署模板即可，Zeabur 會自動：
- 添加 2381 端口
- 更新健康檢查配置
- 重啟所有服務

#### 3. 更新監控配置

如果你使用 Prometheus，更新 scrape 配置：

**之前：**
```yaml
scrape_configs:
  - job_name: 'etcd'
    static_configs:
      - targets:
        - 'etcd1:2379'
        - 'etcd2:2379'
        - 'etcd3:2379'
```

**之後：**
```yaml
scrape_configs:
  - job_name: 'etcd'
    static_configs:
      - targets:
        - 'etcd1:2381'  # ← 改用 metrics 端口
        - 'etcd2:2381'
        - 'etcd3:2381'
```

#### 4. 更新健康檢查 URL

**之前：**
- `http://etcd1:2379/health`
- `http://etcd1:2379/readyz`

**之後：**
- `http://etcd1:2381/health`  ← 新端口
- `http://etcd1:2381/readyz`  ← 新端口

---

## 向後兼容性

### ✅ 完全兼容

- **客戶端 API** (2379)：完全不受影響
- **資料格式**：無任何變更
- **集群協議**：Raft 協議不變

### ⚠️ 需要調整

- **監控系統**：需更新 scrape 目標端口 (2379 → 2381)
- **健康檢查**：需更新端點 URL
- **防火牆規則**：需開放 2381 端口

---

## 性能影響

### 預期改善 📈

1. **客戶端延遲降低**
   - 監控流量不再干擾業務流量
   - 2379 端口負載減輕

2. **更可靠的健康檢查**
   - 獨立端口不受客戶端流量影響
   - 更準確的監控數據

3. **更快的啟動速度**
   - 移除不必要的依賴
   - 並行啟動所有節點

### 資源使用 💻

- **額外端口**：+1 (2381)
- **記憶體**：無影響
- **CPU**：無影響
- **網路**：略微增加（獨立的 metrics 連接）

---

## 已知問題

目前無已知問題。

---

## 貢獻者

感謝以下改進建議：
- 發現端口配置警告
- 發現 `CONTAINER_HOSTNAME` 不一致問題
- 建議移除不必要的 dependencies

---

## 下一步計劃

### 考慮中的功能

- [ ] TLS/SSL 支援
- [ ] RBAC 認證範例
- [ ] 自動備份腳本
- [ ] Grafana Dashboard 範例
- [ ] 性能調優指南
