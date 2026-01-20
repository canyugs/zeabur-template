#!/bin/bash

# Plane Zeabur 快速部署腳本

set -e

TEMPLATE_FILE="zeabur-template-plane-QU5MHI.yaml"
PROJECT_NAME="${1:-plane-$(date +%Y%m%d%H%M%S)}"
REGION="${2:-hkg1}"

echo "✈️  Plane - 開源專案協作平台"
echo ""
echo "📦 服務清單:"
echo "   - postgresql (資料庫)"
echo "   - redis (快取)"
echo "   - minio (物件儲存)"
echo "   - api (Django 後端)"
echo "   - worker (Celery Worker)"
echo "   - beat-worker (Celery Beat)"
echo "   - web (Next.js 前端)"
echo "   - admin (管理後台)"
echo "   - space (協作模組)"
echo "   - plane (Caddy 反向代理)"
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
echo "⚠️  部署後注意事項:"
echo "   1. 請將域名綁定到 plane 服務 (這是唯一入口點)"
echo "   2. 由於 Plane issue #7027，需要手動重啟一次 api 服務"
echo "   3. 綁定域名到 MinIO 服務，進入 Console (port 9090)"
echo "      將 uploads bucket 設為公開，才能上傳圖片"
echo ""
echo "📝 驗證步驟:"
echo "   1. 檢查 api 服務日誌是否正常啟動"
echo "   2. 檢查 web 服務日誌: ready started server"
echo "   3. 訪問您設定的域名測試功能"
echo ""
