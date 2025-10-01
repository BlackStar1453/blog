#!/bin/bash

# 故事内容处理脚本
# 用于处理包含故事的备忘录内容

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

# 生成文件名（使用时间戳和标题）
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SAFE_TITLE=$(echo "$TITLE" | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
FILENAME="story_${TIMESTAMP}_${SAFE_TITLE}.md"

# 目标目录
TARGET_DIR="content/blog/stories"
mkdir -p "$TARGET_DIR"

# 生成文件路径
FILEPATH="$TARGET_DIR/$FILENAME"

# 生成 frontmatter
cat > "$FILEPATH" << EOF
---
title: "$TITLE"
date: $(date +"%Y-%m-%dT%H:%M:%S%z")
type: "story"
tags: ["故事", "创作"]
draft: false
---

# $TITLE

$CLEANED_CONTENT
EOF

echo "✅ 故事已保存到: $FILEPATH"

# 如果存在 git，自动添加文件
if command -v git >/dev/null 2>&1 && [ -d .git ]; then
    git add "$FILEPATH"
    echo "📝 文件已添加到 git"
fi
