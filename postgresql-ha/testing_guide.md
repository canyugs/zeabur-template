# PostgreSQL HA 測試指南

本指南概述了測試 PostgreSQL 高可用性 (HA) 叢集模板的流程。內容涵蓋使用 Docker Compose 進行的本地測試，以及在 Zeabur 上的生產環境測試。

## 第一部分：本地測試 (Docker Compose)

儲存庫中的 `docker-compose.yml` 提供了一種快速的方法來在本地驗證 Patroni 和 PostgreSQL 的配置。請注意，本地設置使用單個 etcd 節點，而生產環境模板使用 3 節點的 etcd 叢集。

### 1. 啟動叢集

```bash
cd postgresql-ha
docker compose up -d
```

### 2. 驗證叢集狀態

等待約 1-2 分鐘讓叢集初始化。然後檢查狀態：

```bash
# 檢查容器狀態
docker compose ps

# 檢查 Patroni 叢集狀態（從任意節點）
docker compose exec patroni1 curl -s http://localhost:8008/cluster | jq .
```

你應該會看到：
- 3 個成員 (`patroni1`, `patroni2`, `patroni3`)
- 一個領導者 (Role: `Leader`)
- 兩個副本 (Role: `Replica`)
- 狀態：`running`

### 3. 測試複製 (Replication)

連接到 **領導者 (Leader)** 寫入數據：

```bash
# 找出領導者（例如：patroni1）
docker compose exec patroni1 psql -U postgres -c "CREATE TABLE test (id serial PRIMARY KEY, name text);"
docker compose exec patroni1 psql -U postgres -c "INSERT INTO test (name) VALUES ('replication_test');"
```

連接到 **副本 (Replica)** 讀取數據：

```bash
# 從副本讀取（例如：patroni2）
docker compose exec patroni2 psql -U postgres -c "SELECT * FROM test;"
```

### 4. 測試自動故障轉移 (Failover)

1. 確認目前的領導者（例如 `patroni1`）。
2. 停止領導者容器：

```bash
docker compose stop patroni1
```

3. 觀察其他節點的日誌以查看選舉過程：

```bash
docker compose logs -f patroni2 patroni3
```

4. 驗證已選出新的領導者：

```bash
docker compose exec patroni2 curl -s http://localhost:8008/cluster | jq .
```

5. 重新啟動舊的領導者：

```bash
docker compose start patroni1
```

6. 驗證它作為副本重新加入（它應該會自動同步）。

---

## 第二部分：生產環境測試 (Zeabur)

這將測試完整的模板功能，包括擴展和多節點 etcd。

### 1. 初始部署

1. 從 Zeabur 市場部署 **PostgreSQL HA** 模板。
2. 等待所有 6 個服務變為健康狀態（3 個 etcd + 3 個 Patroni）。
3. **驗證**：
   - 訪問 `patroni1` 的端點：`http://<patroni1-domain>/cluster`
   - 確保所有 3 個成員都存在且健康。

### 2. 數據持久性與複製測試

1. **連接到 Master 節點**（假設 `patroni1` 是 Master）：

   ```bash
   # 使用 Zeabur 提供的連接字串 (Connection String)
   # 格式: postgresql://postgres:<PASSWORD>@<HOST>:<PORT>/postgres
   psql "postgresql://postgres:PASSWORD@patroni1.zeabur.app:5432/postgres"
   ```

2. **寫入測試數據**：

   ```sql
   CREATE TABLE replication_test (id serial PRIMARY KEY, data text, created_at timestamp DEFAULT now());
   INSERT INTO replication_test (data) VALUES ('Sync Test 1');
   ```

3. **驗證複製**：
   連接到 Replica 節點（例如 `patroni2` 或 `patroni3`）並查詢數據：

   ```bash
   # 連接到 patroni2
   psql "postgresql://postgres:PASSWORD@patroni2.zeabur.app:5432/postgres" -c "SELECT * FROM replication_test;"
   ```

   **預期結果**：應該能看到剛才寫入的 'Sync Test 1'。

### 3. 故障轉移測試

1. 識別目前的 Master 節點（透過 `/cluster` API）。
2. 在 Zeabur 儀表板中，**重新啟動 (Restart)** 或 **暫停 (Suspend)** Master 服務。
3. 在另一個節點上監控 `/cluster` API。
4. **預期結果**：
   - 幾秒鐘內，應該會選出新的 Master。
   - 叢集狀態應該顯示新的拓撲結構。
   - 資料庫連接應該自動重新連接到新的 Master（如果使用支援此功能的客戶端，或在重新連接時）。

### 4. 擴展測試 (Scaling Up)

**目標**：從 3 個節點擴展到 5 個節點。

#### 步驟 4.1：新增 etcd 節點
1. 按照 `README.md` 的說明新增 `etcd4` 和 `etcd5`。
2. **操作**：
   - 在現有的 etcd 節點上執行 `etcdctl member add`。
   - 為 `etcd4` 部署 `etcd Node (Expanding)` 模板。
   - 對 `etcd5` 重複相同步驟。
3. **驗證**：
   - 執行 `etcdctl member list` 查看是否有 5 個成員。

#### 步驟 4.2：更新 Patroni 配置
1. 更新 `patroni1`、`patroni2`、`patroni3` 上的 `ETCD3_HOSTS` 環境變數，以包含新的 etcd 節點。
2. 逐一重新啟動它們。

#### 步驟 4.3：新增 Patroni 節點
1. 為 `patroni4` 部署 `Patroni PostgreSQL (Expanding)` 模板。
   - 將 `Cluster Scope` 設定為 `pg-ha`。
   - 將 `Node Name` 設定為 `patroni4`。
   - 使用正確的密碼。
2. 對 `patroni5` 重複相同步驟。
3. **驗證**：
   - 檢查 `/cluster` API。
   - 你應該看到 5 個 Patroni 節點（1 個 Leader，4 個 Replicas）。

### 5. 縮減測試 (Scaling Down)

**目標**：從 5 個節點縮減回 3 個節點。

1. **移除 Patroni 節點**：
   - 識別一個 **Replica** 節點（例如 `patroni5`）。
   - 在 Zeabur 中刪除 `patroni5` 服務。
   - 驗證叢集狀態顯示它已消失。
2. **移除 etcd 節點**：
   - 為 `etcd5` 執行 `etcdctl member remove <id>`。
   - 在 Zeabur 中刪除 `etcd5` 服務。
   - 驗證 `etcdctl member list` 顯示 4 個成員。

### 6. 災難恢復 (可選)

1. **模擬數據丟失**：
   - 刪除一個 Replica 的服務和 Volume。
   - 使用相同名稱重新部署該服務。
   - **預期**：它應該自動從目前的 Master 引導（Basebackup）並重新加入叢集。
