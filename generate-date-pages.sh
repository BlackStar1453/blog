#!/bin/bash

# 生成特殊日期页面
# 从config.toml读取配置的特殊日期,为每个日期创建页面

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTENT_DIR="$SCRIPT_DIR/content"
SPECIAL_DATES_DIR="$CONTENT_DIR/special-dates"
CONFIG_FILE="$SCRIPT_DIR/config.toml"

# 创建special-dates目录
mkdir -p "$SPECIAL_DATES_DIR"

# 从config.toml提取特殊日期配置
echo "从config.toml读取特殊日期配置..."

# 提取所有配置的日期
dates=$(grep -A 5 "^\[\[extra.special_dates.dates\]\]" "$CONFIG_FILE" | \
  grep -E "^month = |^day = " | \
  awk 'NR%2{printf "%02d-", $3; next} {printf "%02d\n", $3}')

if [ -z "$dates" ]; then
  echo "⚠️  警告: config.toml中没有配置特殊日期"
  echo "请在config.toml的[extra.special_dates]部分添加日期配置"
  exit 0
fi

# 清理旧的日期页面(除了_index.md)
find "$SPECIAL_DATES_DIR" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \;

# 为每个配置的日期创建页面
count=0
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
  count=$((count + 1))
done

echo ""
echo "✅ 完成! 共创建 $count 个日期页面"

