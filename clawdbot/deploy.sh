#!/bin/bash

# Clawdbot Zeabur 快速部署腳本

set -e

TEMPLATE_FILE="zeabur-template-openclaw-VTZ4FX.yaml"
PROJECT_NAME="${1:-clawdbot-$(date +%Y%m%d%H%M%S)}"
REGION="${2:-hkg1}"

echo "🤖 Clawdbot: Personal AI Assistant with Multi-Platform Gateway"
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
echo "│  ⚠️  請在下方提示輸入域名和 API 金鑰                     │"
echo "│     域名例如: $PROJECT_NAME                              │"
echo "│     API 金鑰可選填（按 Enter 跳過）                      │"
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
echo "   1. 檢查 clawdbot 日誌確認 Gateway 已啟動"
echo "   2. 訪問您設定的域名開啟 Web UI"
echo "   3. 使用 Gateway Token 進行身份驗證"
echo "   4. 配置訊息平台連接 (WhatsApp, Telegram, etc.)"
echo ""
echo "📚 文件: https://docs.clawd.bot"
