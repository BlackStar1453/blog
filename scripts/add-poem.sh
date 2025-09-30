#!/bin/bash

# 添加诗歌到 poem 目录的脚本
# 使用方法: ./add-poem.sh "诗歌标题" < 内容
# 作者: AI Assistant
# 版本: 1.0.0

set -e

# 获取脚本所在目录
my_dir="$(dirname "$0")"
source "${my_dir}/common.sh"

# 显示帮助信息
show_help() {
    echo "使用方法: $0 \"诗歌标题\""
    echo ""
    echo "参数说明:"
    echo "  诗歌标题    - 诗歌的标题"
    echo "  内容        - 通过stdin传递诗歌内容"
    echo ""
    echo "示例:"
    echo "  echo \"春风十里不如你\" | $0 \"春日感怀\""
    echo "  $0 \"夜思\" < poem.txt"
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
    echo "错误: 请提供诗歌标题"
    show_help
    exit 1
fi

poem_title="$1"

# 检查标题是否为空
if [ -z "$poem_title" ]; then
    echo "错误: 诗歌标题不能为空"
    exit 1
fi

# 读取内容
if [ -t 0 ]; then
    echo "错误: 请通过stdin提供诗歌内容"
    echo "示例: echo \"内容\" | $0 \"标题\""
    exit 1
fi

content=$(cat)

if [ -z "$content" ]; then
    echo "错误: 诗歌内容不能为空"
    exit 1
fi

# 定义目标目录
target_dir="${my_dir}/../content/poem"

# 确保目标目录存在
mkdir -p "$target_dir"

# 生成文件名（使用计数器）
counter=1
while [ -f "${target_dir}/poem_${counter}.md" ]; do
    counter=$((counter + 1))
done

target_file="${target_dir}/poem_${counter}.md"

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
title: $poem_title
date: ${current_year}-${current_month}-${current_day}T${current_hour}:${current_minute}:${current_second}+08:00
updated: ${current_year}-${current_month}-${current_day}
author: Yao
taxonomies:
  categories:
    - 诗歌
  tags:
    - 诗歌
    - 原创
---

${content}
EOF

echo "✅ 诗歌已成功创建: $target_file"
echo "📝 标题: $poem_title"
echo "📅 日期: $(date +%Y-%m-%d)"
