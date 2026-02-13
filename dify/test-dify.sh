#!/bin/bash
set -euo pipefail

# ============================================================
# Dify Zeabur 部署自動化測試腳本
# ============================================================
# 使用方式:
#   chmod +x test-dify.sh
#   ./test-dify.sh https://your-dify-domain.zeabur.app [app-api-key]
#
# 參數:
#   $1 = Dify 實例 URL (必填)
#   $2 = App API Key (選填，跳過則不測 /v1 API)
# ============================================================

BASE_URL="${1:?請提供 Dify 實例 URL，例如: ./test-dify.sh https://dify.example.com}"
# 移除尾部斜線
BASE_URL="${BASE_URL%/}"
API_KEY="${2:-}"

PASS=0
FAIL=0
SKIP=0
RESULTS=()

# --- 工具函式 ---

check() {
  local name="$1"
  local url="$2"
  local method="${3:-GET}"
  local expected_code="${4:-200}"
  local data="${5:-}"
  local extra_headers="${6:-}"

  if [[ "$method" == "GET" ]]; then
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" $extra_headers 2>/dev/null || echo "000")
  else
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 30 \
      -X "$method" "$url" \
      -H "Content-Type: application/json" \
      $extra_headers \
      -d "$data" 2>/dev/null || echo "000")
  fi

  if [[ "$code" == "$expected_code" ]]; then
    echo "  ✅ $name (HTTP $code)"
    PASS=$((PASS + 1))
    RESULTS+=("PASS|$name")
  else
    echo "  ❌ $name (期望 $expected_code, 實際 $code)"
    FAIL=$((FAIL + 1))
    RESULTS+=("FAIL|$name|期望=$expected_code 實際=$code")
  fi
}

check_json() {
  local name="$1"
  local url="$2"
  local field="$3"

  response=$(curl -s --max-time 10 "$url" 2>/dev/null || echo "{}")
  value=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$field',''))" 2>/dev/null || echo "")

  if [[ -n "$value" ]]; then
    echo "  ✅ $name ($field=$value)"
    PASS=$((PASS + 1))
    RESULTS+=("PASS|$name")
  else
    echo "  ❌ $name (回應中找不到 '$field')"
    FAIL=$((FAIL + 1))
    RESULTS+=("FAIL|$name|missing $field")
  fi
}

skip() {
  local name="$1"
  local reason="$2"
  echo "  ⏭️  $name (跳過: $reason)"
  SKIP=$((SKIP + 1))
  RESULTS+=("SKIP|$name|$reason")
}

separator() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $1"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================
# Phase 1: 基礎設施健康檢查
# ============================================================
separator "Phase 1: 基礎設施健康檢查"

# 1.1 Web 服務 (307 redirect to /apps or /install is normal before setup)
check "Web 前端可訪問" "$BASE_URL/" GET 307

# 1.2 API 健康檢查 (use /console/api/setup as health probe)
check_json "API 健康檢查" "$BASE_URL/console/api/setup" "step"

# 1.3 API 版本資訊 (requires current_version query param)
check "API 版本端點" "$BASE_URL/console/api/version?current_version=0.0.0" GET 200

# ============================================================
# Phase 2: Nginx 路由驗證
# ============================================================
separator "Phase 2: Nginx 路由驗證"

# /console/api → api:5001
check "路由 /console/api" "$BASE_URL/console/api/setup" GET 200

# /api → api:5001 (需要認證，401 表示路由正確)
check "路由 /api (需認證)" "$BASE_URL/api/parameters" GET 401

# /v1 → api:5001 (需要 API Key，401 表示路由正確)
check "路由 /v1 (需 API Key)" "$BASE_URL/v1/parameters" GET 401

# /files → api:5001
check "路由 /files" "$BASE_URL/files/not-exist" GET 404

# /explore → web:3000
check "路由 /explore" "$BASE_URL/explore/apps" GET 200

# /e/ → plugin-daemon:5002 (404 = daemon 收到請求但 hook 不存在, 需要尾部斜線)
check "路由 /e/ (plugin-daemon)" "$BASE_URL/e/test-nonexistent/" GET 404

# /mcp → api:5001 (404 = 路由到達 API 但 MCP 端點需要特定協議)
check "路由 /mcp" "$BASE_URL/mcp/test" GET "404"

# /triggers → api:5001
check "路由 /triggers" "$BASE_URL/triggers/test" GET "404"

# / → web:3000 (分享頁面路由)
check "路由 /chat (web)" "$BASE_URL/chat/nonexistent" GET 200
check "路由 /completion (web)" "$BASE_URL/completion/nonexistent" GET 200
check "路由 /workflow (web)" "$BASE_URL/workflow/nonexistent" GET 200
check "路由 /chatbot (web)" "$BASE_URL/chatbot/nonexistent" GET 200

# ============================================================
# Phase 3: Console API 功能
# ============================================================
separator "Phase 3: Console API 端點"

check "登入端點可達" "$BASE_URL/console/api/login" POST 400 '{}' ""
check "設定頁面可達" "$BASE_URL/console/api/setup" GET 200
check "功能列表" "$BASE_URL/console/api/features" GET "401"

# ============================================================
# Phase 4: Service API (/v1) — 需要 API Key
# ============================================================
separator "Phase 4: Service API (/v1)"

if [[ -n "$API_KEY" ]]; then
  # 取得 App 參數
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "$BASE_URL/v1/parameters" \
    -H "Authorization: Bearer $API_KEY" 2>/dev/null || echo "000")
  if [[ "$code" == "200" ]]; then
    echo "  ✅ GET /v1/parameters (HTTP $code)"
    PASS=$((PASS + 1))
    RESULTS+=("PASS|GET /v1/parameters")
  else
    echo "  ❌ GET /v1/parameters (HTTP $code)"
    FAIL=$((FAIL + 1))
    RESULTS+=("FAIL|GET /v1/parameters|HTTP $code")
  fi

  # 取得 App meta
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "$BASE_URL/v1/meta" \
    -H "Authorization: Bearer $API_KEY" 2>/dev/null || echo "000")
  if [[ "$code" == "200" ]]; then
    echo "  ✅ GET /v1/meta (HTTP $code)"
    PASS=$((PASS + 1))
    RESULTS+=("PASS|GET /v1/meta")
  else
    echo "  ❌ GET /v1/meta (HTTP $code)"
    FAIL=$((FAIL + 1))
    RESULTS+=("FAIL|GET /v1/meta|HTTP $code")
  fi

  # Chat API (blocking mode)
  echo "  🔄 測試 Chat API (可能需要幾秒)..."
  response=$(curl -s --max-time 60 \
    -X POST "$BASE_URL/v1/chat-messages" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"inputs": {}, "query": "Say hello in one word", "response_mode": "blocking", "user": "test-script"}' \
    2>/dev/null || echo '{"error": "timeout"}')

  conversation_id=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('conversation_id',''))" 2>/dev/null || echo "")
  answer=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('answer',''))" 2>/dev/null || echo "")
  if [[ -n "$answer" ]]; then
    echo "  ✅ POST /v1/chat-messages — 回覆: \"$answer\""
    PASS=$((PASS + 1))
    RESULTS+=("PASS|POST /v1/chat-messages")
  else
    error=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message', d.get('error','unknown')))" 2>/dev/null || echo "unknown")
    echo "  ❌ POST /v1/chat-messages — 錯誤: $error"
    FAIL=$((FAIL + 1))
    RESULTS+=("FAIL|POST /v1/chat-messages|$error")
  fi

  # 對話列表
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "$BASE_URL/v1/conversations?user=test-script" \
    -H "Authorization: Bearer $API_KEY" 2>/dev/null || echo "000")
  if [[ "$code" == "200" ]]; then
    echo "  ✅ GET /v1/conversations (HTTP $code)"
    PASS=$((PASS + 1))
    RESULTS+=("PASS|GET /v1/conversations")
  else
    echo "  ❌ GET /v1/conversations (HTTP $code)"
    FAIL=$((FAIL + 1))
    RESULTS+=("FAIL|GET /v1/conversations|HTTP $code")
  fi

  # 訊息列表 (v1.13.0+ 需要 conversation_id)
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "$BASE_URL/v1/messages?user=test-script&conversation_id=$conversation_id" \
    -H "Authorization: Bearer $API_KEY" 2>/dev/null || echo "000")
  if [[ "$code" == "200" ]]; then
    echo "  ✅ GET /v1/messages (HTTP $code)"
    PASS=$((PASS + 1))
    RESULTS+=("PASS|GET /v1/messages")
  else
    echo "  ❌ GET /v1/messages (HTTP $code)"
    FAIL=$((FAIL + 1))
    RESULTS+=("FAIL|GET /v1/messages|HTTP $code")
  fi

else
  skip "GET /v1/parameters" "未提供 API Key"
  skip "GET /v1/meta" "未提供 API Key"
  skip "POST /v1/chat-messages" "未提供 API Key"
  skip "GET /v1/conversations" "未提供 API Key"
  skip "GET /v1/messages" "未提供 API Key"
fi

# ============================================================
# 結果摘要
# ============================================================
separator "測試結果摘要"

TOTAL=$((PASS + FAIL + SKIP))
echo ""
echo "  總計: $TOTAL 項測試"
echo "  ✅ 通過: $PASS"
echo "  ❌ 失敗: $FAIL"
echo "  ⏭️  跳過: $SKIP"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "  失敗項目:"
  for r in "${RESULTS[@]}"; do
    if [[ "$r" == FAIL* ]]; then
      echo "    - ${r#FAIL|}"
    fi
  done
  echo ""
  exit 1
else
  echo "  🎉 所有測試通過！"
  echo ""
  exit 0
fi
