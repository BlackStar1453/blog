#!/bin/bash

# 生成特殊日期页面
# 为每个有内容的日期(MM-DD)创建一个页面

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTENT_DIR="$SCRIPT_DIR/content"
SPECIAL_DATES_DIR="$CONTENT_DIR/special-dates"

# 创建special-dates目录
mkdir -p "$SPECIAL_DATES_DIR"

# 收集所有有内容的日期(MM-DD格式)
echo "收集所有有内容的日期..."
dates=$(find "$CONTENT_DIR/blog" -name "*.md" -type f -exec grep -h "^date = \|^updated = " {} \; | \
  sed 's/date = //g; s/updated = //g; s/"//g' | \
  grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2}" | \
  cut -d'-' -f2-3 | \
  sort -u)

# 为每个日期创建页面
for date in $dates; do
  month=$(echo "$date" | cut -d'-' -f1)
  day=$(echo "$date" | cut -d'-' -f2)
  
  # 创建日期目录
  date_dir="$SPECIAL_DATES_DIR/$date"
  mkdir -p "$date_dir"
  
  # 创建index.md
  cat > "$date_dir/index.md" << EOF
+++
title = "${month}月${day}日"
description = "查看所有年份${month}月${day}日的内容"
template = "special_date.html"

[extra]
target_date = "$date"
+++
EOF
  
  echo "✓ 创建页面: /special-dates/$date/"
done

echo ""
echo "✅ 完成! 共创建 $(echo "$dates" | wc -l | tr -d ' ') 个日期页面"

