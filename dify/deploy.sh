#!/bin/bash

# Dify Zeabur 快速部署腳本

set -e

TEMPLATE_FILE="zeabur-template-dify-1D4DOW.yaml"
PROJECT_NAME="${1:-dify-$(date +%Y%m%d%H%M%S)}"
REGION="${2:-hkg1}"

echo "🚀 開始部署 Dify..."
echo "   專案名稱: $PROJECT_NAME"
echo "   區域: $REGION"
echo ""

# 1. 建立專案
echo "📦 建立專案..."
npx zeabur@latest project create -n "$PROJECT_NAME" -r "$REGION"

# 2. 取得專案 ID
echo "🔍 取得專案 ID..."
PROJECT_ID=$(npx zeabur@latest project list 2>/dev/null | grep "$PROJECT_NAME" | awk '{print $1}' | sed 's/\x1b\[[0-9;]*m//g')

if [ -z "$PROJECT_ID" ]; then
    echo "❌ 無法取得專案 ID"
    exit 1
fi

echo "   專案 ID: $PROJECT_ID"
echo ""

# 3. 部署模板
echo "🎯 部署模板..."
echo "   請在提示時輸入域名 (例如: $PROJECT_NAME)"
echo ""

npx zeabur@latest template deploy -f "$TEMPLATE_FILE" --project-id "$PROJECT_ID"

echo ""
echo "✅ 部署完成！"
echo "   專案: https://zeabur.com/projects/$PROJECT_ID"
