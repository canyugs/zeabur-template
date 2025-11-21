#!/bin/bash

# Supabase Google OAuth 驗證腳本

echo "==================================="
echo "Supabase Google OAuth 驗證測試"
echo "==================================="
echo ""

# 設定您的 Supabase URL（請修改為您的實際 URL）
SUPABASE_URL="${1:-http://localhost:8000}"

# Anon Key (從 docker-compose.yml 或 .env 獲取)
ANON_KEY="${2:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE}"

echo "📍 測試 URL: $SUPABASE_URL"
echo ""

# 測試 1: 檢查 Auth Settings API
echo "1️⃣  測試 Auth Settings API..."
echo "-----------------------------------"
SETTINGS_RESPONSE=$(curl -s "${SUPABASE_URL}/auth/v1/settings" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${ANON_KEY}")
echo "$SETTINGS_RESPONSE" | jq '.'
echo ""

# 檢查 Google 是否啟用
GOOGLE_ENABLED=$(echo "$SETTINGS_RESPONSE" | jq -r '.external.google')
echo "✓ Google Provider 啟用狀態: $GOOGLE_ENABLED"
echo ""

if [ "$GOOGLE_ENABLED" = "true" ]; then
    echo "✅ Google OAuth 已啟用！"
else
    echo "❌ Google OAuth 未啟用"
    exit 1
fi

# 測試 2: 檢查 Health
echo ""
echo "2️⃣  測試 Auth Health..."
echo "-----------------------------------"
HEALTH_RESPONSE=$(curl -s "${SUPABASE_URL}/auth/v1/health")
echo "$HEALTH_RESPONSE" | jq '.'
echo ""

# 測試 3: 生成 Google OAuth URL
echo ""
echo "3️⃣  生成 Google OAuth 登錄 URL..."
echo "-----------------------------------"
echo "請在瀏覽器中訪問以下 URL 來測試 Google 登錄："
echo ""
echo "${SUPABASE_URL}/auth/v1/authorize?provider=google"
echo ""
echo "如果配置正確，應該會重定向到 Google 登錄頁面。"
echo ""

echo "==================================="
echo "測試完成！"
echo "==================================="
