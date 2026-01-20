#!/bin/bash

# Postiz Zeabur 快速部署腳本

set -e

TEMPLATE_FILE="zeabur-template-postiz-v2.11.3-CWN6IC.yaml"
PROJECT_NAME="${1:-postiz-$(date +%Y%m%d%H%M%S)}"
REGION="${2:-hkg1}"

echo "📦 Postiz (Split Services): postiz-api + postiz-frontend"
echo ""
echo "🚀 開始部署..."
echo "   模板: $TEMPLATE_FILE"
echo "   專案名稱: $PROJECT_NAME"
echo "   區域: $REGION"
echo ""

# 1. 建立專案
echo "📦 建立專案..."
npx zeabur@latest project create -n "$PROJECT_NAME" -r "$REGION"

# 2. 取得專案 ID
echo ""
echo "🔍 取得專案 ID..."
PROJECT_ID=$(npx zeabur@latest project list 2>/dev/null | grep "$PROJECT_NAME" | awk '{print $1}' | sed 's/\x1b\[[0-9;]*m//g')

if [ -z "$PROJECT_ID" ]; then
    echo "❌ 無法取得專案 ID，請手動部署："
    echo "   npx zeabur@latest template deploy -f $TEMPLATE_FILE"
    exit 1
fi

echo "   專案 ID: $PROJECT_ID"
echo "   Dashboard: https://zeabur.com/projects/$PROJECT_ID"
echo ""

# 3. 部署模板
echo "🎯 部署模板..."
echo ""
echo "┌─────────────────────────────────────────────────────────┐"
echo "│  ⚠️  請在下方提示輸入域名                                │"
echo "│     例如輸入: $PROJECT_NAME                              │"
echo "└─────────────────────────────────────────────────────────┘"
echo ""

npx zeabur@latest template deploy -f "$TEMPLATE_FILE" --project-id "$PROJECT_ID"

echo ""
echo "✅ 部署完成！"
echo ""
echo "📋 專案資訊:"
echo "   Dashboard: https://zeabur.com/projects/$PROJECT_ID"
echo ""
echo "📝 驗證步驟:"
echo "   1. 檢查 postiz-api 日誌: Backend is running on: http://localhost:3000"
echo "   2. 檢查 postiz-frontend 日誌: ready started server"
echo "   3. 訪問您設定的域名測試功能"
