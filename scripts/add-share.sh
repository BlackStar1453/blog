#!/bin/bash

# 分享内容处理脚本
# 用法: ./add-share.sh "标题" < content.txt

set -e

# 导入公共函数
source "$(dirname "$0")/common.sh"

# 检查参数
if [ $# -lt 1 ]; then
    echo "用法: $0 '标题'" >&2
    exit 1
fi

TITLE="$1"
CONTENT=$(cat)

# 创建目标目录
TARGET_DIR="content/blog/shares"
mkdir -p "$TARGET_DIR"

# 生成文件名
DATE=$(date +%Y-%m-%d)
DATETIME=$(date +%Y-%m-%dT%H:%M:%S%z)
# 简单的 slug 生成函数
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
FILENAME="${DATE}-${SLUG}.md"
FILEPATH="$TARGET_DIR/$FILENAME"

# 检查文件是否已存在
if [ -f "$FILEPATH" ]; then
    echo "文件已存在: $FILEPATH" >&2
    exit 1
fi

# 提取链接（如果有的话）
LINKS=$(echo "$CONTENT" | grep -oE 'https?://[^\s]+' | head -5 || true)

# 生成 front matter
cat > "$FILEPATH" << EOF
---
title: "$TITLE"
date: $DATETIME
updated: $DATE
taxonomies:
  categories:
    - 分享
  tags:
    - 分享
    - 推荐
    - 链接
extra:
  original_links: [$(echo "$LINKS" | sed 's/^/"/' | sed 's/$/"/' | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')]
---

$CONTENT
EOF

echo "已创建分享文章: $FILEPATH"
echo "$FILEPATH"
