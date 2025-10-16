#!/bin/bash

# 获取 Cloudflare Pages 项目的固定域名
# 用法: ./get-pages-domain.sh <project-name>

set -e

PROJECT_NAME="$1"

if [ -z "$PROJECT_NAME" ]; then
    echo "用法: $0 <project-name>"
    exit 1
fi

# 获取项目列表并提取指定项目的域名
# 使用 awk 精确匹配第二列（Project Name）
DOMAIN=$(wrangler pages project list 2>/dev/null | \
    awk -v proj="$PROJECT_NAME" '$2 == proj {print $4}' | \
    grep '\.pages\.dev' | \
    sed 's/,$//' | \
    head -1)

if [ -n "$DOMAIN" ]; then
    echo "https://$DOMAIN"
    exit 0
else
    echo "错误: 未找到项目 '$PROJECT_NAME' 的域名" >&2
    exit 1
fi

