  flowchart TD
      Start([容器啟動<br/>以 root 身份]) --> Launch[/launch.sh 執行/]

      Launch --> Mkdir["mkdir -p $PGDATA $PGLOG<br/>(以 root 建立)"]
      Mkdir --> Chown["chown -R postgres: $PGROOT<br/>(修正權限 → postgres:postgres)"]
      Chown --> StartPatroni["啟動 Patroni<br/>(以 postgres 使用者)"]

      StartPatroni --> P1[patroni1 啟動]
      StartPatroni --> P2[patroni2 啟動]
      StartPatroni --> P3[patroni3 啟動]

      P1 --> CheckEtcd1{檢查 etcd<br/>是否有 leader?}
      P2 --> CheckEtcd2{檢查 etcd<br/>是否有 leader?}
      P3 --> CheckEtcd3{檢查 etcd<br/>是否有 leader?}

      CheckEtcd1 --> Election[選舉競爭<br/>通過 etcd 投票]
      CheckEtcd2 --> Election
      CheckEtcd3 --> Election

      Election --> Leader{誰贏得選舉?}

      Leader -->|patroni1 當選| P1Leader["🏆 patroni1 成為 LEADER"]
      Leader -->|patroni2 當選| P2Leader["🏆 patroni2 成為 LEADER"]
      Leader -->|patroni3 當選| P3Leader["🏆 patroni3 成為 LEADER"]

      Leader -.->|其他節點| Replica["💤 成為 REPLICA<br/>(副本節點)"]

      P1Leader --> Initdb["執行 initdb<br/>初始化 PostgreSQL"]
      P2Leader --> Initdb
      P3Leader --> Initdb

      Initdb --> CreateData["建立資料庫檔案<br/>$PGDATA/<br/>├─ PG_VERSION<br/>├─ postgresql.conf<br/>└─ base/"]
      CreateData --> DataOwner["✅ 所有檔案擁有者:<br/>postgres:postgres"]
      DataOwner --> LeaderRunning["PostgreSQL 運行中<br/>接受連線"]

      Replica --> NeedInit{需要初始化<br/>資料?}
      NeedInit -->|是| Basebackup["執行 basebackup.sh<br/>(以 postgres 使用者)"]

      Basebackup --> Step1["Step 1: 建立 WAL 接收目錄<br/>WAL_FAST=/pgdata/pgroot/wal_fast<br/>mkdir -p $WAL_FAST"]

      Step1 --> Problem1["❌ 問題點 1<br/>在 K8s 環境建立的目錄<br/>變成 root:root"]

      Problem1 --> Step2["Step 2: 清理舊資料<br/>rm -fr $DATA_DIR"]

      Step2 --> Step3["Step 3: 從主節點複製資料<br/>pg_basebackup<br/>--pgdata=$DATA_DIR<br/>--dbname=host=patroni1..."]

      Step3 --> Problem2["❌ 問題點 2<br/>建立的 data/ 目錄<br/>變成 root:root"]

      Problem2 --> DirStructure["目錄結構:<br/>/home/postgres/pgdata/pgroot/<br/>├─ pg_log/ (postgres:postgres ✅)<br/>├─
  wal_fast/ (root:root ❌)<br/>└─ data/ (root:root ❌)"]

      DirStructure --> TryStart["PostgreSQL 嘗試啟動<br/>(postgres 使用者)"]

      TryStart --> PermCheck{檢查 data/<br/>目錄權限}

      PermCheck -->|root:root| Error["❌ ERROR<br/>data directory has<br/>wrong ownership<br/><br/>容器持續重啟"]

      PermCheck -->|postgres:postgres| ReplicaRunning["✅ PostgreSQL 運行<br/>從主節點同步資料"]

      style Start fill:#e1f5ff
      style Leader fill:#fff4e1
      style P1Leader fill:#c8e6c9
      style P2Leader fill:#c8e6c9
      style P3Leader fill:#c8e6c9
      style LeaderRunning fill:#4caf50,color:#fff
      style Problem1 fill:#ff5252,color:#fff
      style Problem2 fill:#ff5252,color:#fff
      style Error fill:#d32f2f,color:#fff
      style ReplicaRunning fill:#4caf50,color:#fff

sequenceDiagram
      participant K8s as Kubernetes
      participant C as Container (root)
      participant L as launch.sh
      participant P as Patroni (postgres)
      participant B as basebackup.sh
      participant PG as PostgreSQL

      K8s->>C: 啟動容器 (root user)
      C->>L: 執行 /launch.sh

      rect rgb(200, 230, 201)
          Note over L: 初始化階段
          L->>L: mkdir -p $PGDATA (root建立)
          L->>L: chown -R postgres: $PGROOT ✅
      end

      L->>P: 啟動 Patroni (切換到 postgres user)

      alt patroni1 當選 Leader
          P->>PG: 執行 initdb
          PG->>PG: 建立 data/ (postgres:postgres) ✅
          PG-->>P: 初始化完成
      else patroni2/3 是 Replica
          P->>B: 執行 basebackup.sh

          rect rgb(255, 205, 210)
              Note over B: ❌ 問題發生
              B->>B: mkdir -p $WAL_FAST
              Note right of B: 在 K8s 環境<br/>變成 root:root

              B->>B: rm -fr $DATA_DIR
              B->>B: pg_basebackup --pgdata=$DATA_DIR
              Note right of B: 建立的 data/<br/>變成 root:root
          end

          B-->>P: basebackup 完成
          P->>PG: 嘗試啟動 PostgreSQL
          PG->>PG: 檢查 data/ 權限

          alt data/ 是 root:root
              PG-->>P: ❌ ERROR: wrong ownership
              P->>P: 容器崩潰重啟
          else data/ 是 postgres:postgres (修正後)
              PG-->>P: ✅ 啟動成功
          end
      end

    
    flowchart LR
      subgraph Fix ["🔧 解決方案: 背景修正任務"]
          direction TB
          BG1["啟動背景任務<br/>(無限迴圈)"] --> Sleep["sleep 10 秒"]
          Sleep --> Check{"/pgdata/pgroot<br/>目錄存在?"}
          Check -->|是| Chown["chown -R postgres:postgres<br/>/pgdata/pgroot"]
          Check -->|否| Sleep
          Chown --> Sleep
      end

      Main["主程序<br/>exec /launch.sh init"]

      Start([容器啟動]) --> Parallel[平行執行]
      Parallel --> Fix
      Parallel --> Main

      style Fix fill:#e3f2fd
      style Main fill:#fff3e0
      style Start fill:#c8e6c9