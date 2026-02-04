#!/bin/bash

# WrenAI Zeabur 快速部署腳本

set -e

TEMPLATE_FILE="wrenai-zeabur-template.yml"

# 顯示使用說明
show_usage() {
    echo "Usage: ./deploy.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --project-id ID    使用現有專案 ID 部署"
    echo "  -n, --name NAME        新專案名稱 (預設: wrenai-時間戳)"
    echo "  -r, --region REGION    區域 (預設: hnd1)"
    echo "  -h, --help             顯示此說明"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh                              # 建立新專案並部署"
    echo "  ./deploy.sh -p 6971d5c8c6666cb8b81a7b4c  # 部署到現有專案"
    echo "  ./deploy.sh -n my-wrenai -r tyo1         # 指定名稱和區域"
}

# 解析參數
PROJECT_ID=""
PROJECT_NAME=""
REGION="hnd1"

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project-id)
            PROJECT_ID="$2"
            shift 2
            ;;
        -n|--name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "未知選項: $1"
            show_usage
            exit 1
            ;;
    esac
done

# 設定預設專案名稱
if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME="wrenai-$(date +%Y%m%d%H%M%S)"
fi

echo "🧠 WrenAI: GenBI (Generative BI) - Text-to-SQL & Text-to-Chart"
echo ""
echo "📦 服務清單:"
echo "   • wren-engine    - 核心引擎"
echo "   • wren-ui        - 網頁介面"
echo "   • ibis-server    - Ibis 伺服器"
echo "   • wren-ai-service - AI 服務"
echo "   • qdrant         - 向量資料庫"
echo ""

# 如果沒有指定專案 ID，建立新專案
if [ -z "$PROJECT_ID" ]; then
    echo "🚀 建立新專案..."
    echo "   專案名稱: $PROJECT_NAME"
    echo "   區域: $REGION"
    echo ""

    npx zeabur@latest project create -n "$PROJECT_NAME" -r "$REGION" -i=false

    echo ""
    echo "🔍 取得專案 ID..."
    PROJECT_ID=$(npx zeabur@latest project list -i=false 2>/dev/null | grep "$PROJECT_NAME" | awk '{print $1}' | sed 's/\x1b\[[0-9;]*m//g')

    if [ -z "$PROJECT_ID" ]; then
        echo "❌ 無法取得專案 ID，請手動部署："
        echo "   npx zeabur@latest template deploy -f $TEMPLATE_FILE"
        exit 1
    fi
else
    echo "🎯 使用現有專案: $PROJECT_ID"
fi

echo ""
echo "   專案 ID: $PROJECT_ID"
echo "   Dashboard: https://zeabur.com/projects/$PROJECT_ID"
echo ""

# 部署模板
echo "🚀 部署模板..."
echo ""
echo "┌─────────────────────────────────────────────────────────┐"
echo "│  ⚠️  部署時需要填入以下資訊:                             │"
echo "│     1. Domain - 您的 Wren AI 網域                       │"
echo "│     2. OpenAI API Key - 用於 AI 功能                    │"
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
echo "   1. 等待所有 5 個服務啟動完成"
echo "   2. 檢查 wren-engine 日誌: SERVER STARTED"
echo "   3. 檢查 wren-ui 日誌: ready started server"
echo "   4. 訪問您設定的域名開始使用"
echo ""
echo "💡 使用提示:"
echo "   • 首次使用需連接資料庫 (PostgreSQL, MySQL, BigQuery 等)"
echo "   • 連接後 WrenAI 會自動分析 Schema 並建立語義層"
echo "   • 接著就可以用自然語言查詢資料庫了！"
echo ""
