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
TIMESTAMP=$(date +%H%M%S)

# 生成 slug: 保留中文、字母、数字,其他字符替换为 -
# 使用 Python 处理中文字符
SLUG=$(python3 -c "
import re
import sys
title = sys.argv[1]
# 替换空格为短横线
slug = re.sub(r'\s+', '-', title)
# 保留中文、字母、数字和短横线
slug = re.sub(r'[^\u4e00-\u9fa5a-zA-Z0-9-]', '', slug)
# 移除多余的短横线
slug = re.sub(r'-+', '-', slug)
slug = slug.strip('-')
# 限制长度
print(slug[:50] if slug else '')
" "$TITLE")

# 如果 slug 为空,使用时间戳
if [ -z "$SLUG" ]; then
    SLUG="share-${TIMESTAMP}"
fi

FILENAME="${DATE}-${SLUG}.md"
FILEPATH="$TARGET_DIR/$FILENAME"

# 如果文件已存在,添加时间戳后缀
if [ -f "$FILEPATH" ]; then
    FILENAME="${DATE}-${SLUG}-${TIMESTAMP}.md"
    FILEPATH="$TARGET_DIR/$FILENAME"
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
