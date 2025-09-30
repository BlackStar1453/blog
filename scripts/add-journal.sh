#!/bin/bash

# 添加日记到 blog/journals 的脚本
# 使用方法: ./add-journal.sh "标题" < 内容
# 作者: AI Assistant
# 版本: 1.0.0

set -e

# 获取脚本所在目录
my_dir="$(dirname "$0")"
source "${my_dir}/common.sh"

# 显示帮助信息
show_help() {
    echo "使用方法: $0 \"日记标题\""
    echo ""
    echo "参数说明:"
    echo "  日记标题    - 日记的标题"
    echo "  内容        - 通过stdin传递日记内容"
    echo ""
    echo "示例:"
    echo "  echo \"今天天气很好\" | $0 \"美好的一天\""
    echo "  $0 \"周末随想\" < content.txt"
    echo ""
    echo "选项:"
    echo "  -h, --help  显示此帮助信息"
}

# 检查帮助参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 检查是否提供了标题
if [ $# -eq 0 ]; then
    echo "错误: 请提供日记标题"
    show_help
    exit 1
fi

title="$1"

# 检查标题是否为空
if [ -z "$title" ]; then
    echo "错误: 日记标题不能为空"
    exit 1
fi

# 读取内容
if [ -t 0 ]; then
    echo "错误: 请通过stdin提供日记内容"
    echo "示例: echo \"内容\" | $0 \"标题\""
    exit 1
fi

content=$(cat)

if [ -z "$content" ]; then
    echo "错误: 日记内容不能为空"
    exit 1
fi

# 定义目标目录和文件
target_dir="${my_dir}/../content/blog/journals"
current_date=$(date +%Y-%m-%d)
target_file="${target_dir}/${current_date}.md"

# 确保目标目录存在
mkdir -p "$target_dir"

# 检查文件是否已存在
if [ -f "$target_file" ]; then
    # 自动追加内容（避免交互式询问）
    echo "" >> "$target_file"
    echo "---" >> "$target_file"
    echo "" >> "$target_file"
    echo "## $title" >> "$target_file"
    echo "" >> "$target_file"
    echo "$content" >> "$target_file"
    echo "✅ 内容已追加到今天的日记: $target_file"
    echo "📝 标题: $title"
    echo "📅 日期: $current_date"
    exit 0
fi

# 获取当前时间信息
current_year=$(date +%Y)
current_month=$(date +%m)
current_day=$(date +%d)
current_hour=$(date +%H)
current_minute=$(date +%M)
current_second=$(date +%S)

# 直接创建文件（避免模板处理的复杂性）
cat > "$target_file" << EOF
---
title: "${current_year}.${current_month}.${current_day}: ${title}"
date: ${current_year}-${current_month}-${current_day}T${current_hour}:${current_minute}:${current_second}+08:00
updated: ${current_year}-${current_month}-${current_day}
taxonomies:
  categories:
    - 日记
  tags:
    - 日记
    - 生活
---

${content}
EOF

echo "✅ 日记已成功创建: $target_file"
echo "📝 标题: $title"
echo "📅 日期: $current_date"
