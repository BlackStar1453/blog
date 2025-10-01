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
DATETIME=$(date +"%Y-%m-%dT%H:%M:%S")
TIMESTAMP=$(date +"%H%M%S")

# 生成 slug: 保留中文、字母、数字
SLUG=$(python3 -c "
import re
import sys
title = sys.argv[1]
slug = re.sub(r'\s+', '-', title)
slug = re.sub(r'[^\u4e00-\u9fa5a-zA-Z0-9-]', '', slug)
slug = re.sub(r'-+', '-', slug)
slug = slug.strip('-')
print(slug[:50] if slug else '')
" "$TITLE")

# 如果 slug 为空,使用时间戳
if [ -z "$SLUG" ]; then
    SLUG="travel-${TIMESTAMP}"
fi

FILENAME="${DATE}-${SLUG}.md"

# 目标目录
TARGET_DIR="content/blog/travels"
mkdir -p "$TARGET_DIR"

# 生成文件路径
FILEPATH="$TARGET_DIR/$FILENAME"

# 如果文件已存在,添加时间戳后缀
if [ -f "$FILEPATH" ]; then
    FILENAME="${DATE}-${SLUG}-${TIMESTAMP}.md"
    FILEPATH="$TARGET_DIR/$FILENAME"
fi

# 检查模板文件
TEMPLATE_FILE="scripts/templates/travel.md.tmpl"
if [ -f "$TEMPLATE_FILE" ]; then
    # 使用模板
    sed -e "s/{{TITLE}}/$TITLE/g" \
        -e "s/{{DATE}}/$DATETIME/g" \
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
