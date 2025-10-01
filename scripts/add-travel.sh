#!/bin/bash

# 旅行内容处理脚本
# 用于处理包含旅行记录的备忘录内容

set -e

# 导入通用函数
source "$(dirname "$0")/common.sh"

# 检查参数
if [ $# -lt 1 ]; then
    echo "用法: $0 <标题> [内容]"
    exit 1
fi

TITLE="$1"
CONTENT="${2:-}"

# 如果没有提供内容，从标准输入读取
if [ -z "$CONTENT" ]; then
    CONTENT=$(cat)
fi

# 清理内容（移除标签）
CLEANED_CONTENT=$(echo "$CONTENT" | sed 's/#[[:alpha:]]*[[:space:]]*//g' | sed '/^[[:space:]]*$/d')

# 生成文件名（使用日期和标题）
DATE=$(date +"%Y-%m-%d")
DATETIME=$(date +"%Y-%m-%dT%H:%M:%S%z")
SAFE_TITLE=$(echo "$TITLE" | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
FILENAME="${DATE}-${SAFE_TITLE}.md"

# 目标目录
TARGET_DIR="content/blog/travels"
mkdir -p "$TARGET_DIR"

# 生成文件路径
FILEPATH="$TARGET_DIR/$FILENAME"

# 检查模板文件
TEMPLATE_FILE="scripts/templates/travel.md.tmpl"
if [ -f "$TEMPLATE_FILE" ]; then
    # 使用模板
    sed -e "s/{{TITLE}}/$TITLE/g" \
        -e "s/{{DATE}}/$DATE/g" \
        -e "s/{{CONTENT}}/$CLEANED_CONTENT/g" \
        "$TEMPLATE_FILE" > "$FILEPATH"
else
    # 使用默认格式
    cat > "$FILEPATH" << EOF
---
title: "$TITLE"
date: $DATETIME
type: "travel"
tags: ["旅行", "游记"]
location: ""
draft: false
---

# $TITLE

$CLEANED_CONTENT

## 旅行信息

- **日期**: $DATE
- **地点**: 
- **天气**: 
- **同行**: 

## 感想

## 照片

EOF
fi

echo "✅ 旅行记录已保存到: $FILEPATH"

# 如果存在 git，自动添加文件
if command -v git >/dev/null 2>&1 && [ -d .git ]; then
    git add "$FILEPATH"
    echo "📝 文件已添加到 git"
fi
