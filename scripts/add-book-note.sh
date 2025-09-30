#!/bin/bash

# 添加读书笔记到 blog/books 的脚本
# 使用方法: ./add-book-note.sh "书名" < 内容
# 作者: AI Assistant
# 版本: 1.0.0

set -e

# 获取脚本所在目录
my_dir="$(dirname "$0")"
source "${my_dir}/common.sh"

# 显示帮助信息
show_help() {
    echo "使用方法: $0 \"书名\""
    echo ""
    echo "参数说明:"
    echo "  书名        - 书籍的名称"
    echo "  内容        - 通过stdin传递读书笔记内容"
    echo ""
    echo "示例:"
    echo "  echo \"这本书很有趣\" | $0 \"1984\""
    echo "  $0 \"挪威的森林\" < note.txt"
    echo ""
    echo "选项:"
    echo "  -h, --help  显示此帮助信息"
}

# 检查帮助参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 检查是否提供了书名
if [ $# -eq 0 ]; then
    echo "错误: 请提供书名"
    show_help
    exit 1
fi

book_title="$1"

# 检查书名是否为空
if [ -z "$book_title" ]; then
    echo "错误: 书名不能为空"
    exit 1
fi

# 读取内容
if [ -t 0 ]; then
    echo "错误: 请通过stdin提供读书笔记内容"
    echo "示例: echo \"内容\" | $0 \"书名\""
    exit 1
fi

content=$(cat)

if [ -z "$content" ]; then
    echo "错误: 读书笔记内容不能为空"
    exit 1
fi

# 定义目标目录
target_dir="${my_dir}/../content/blog/books"

# 确保目标目录存在
mkdir -p "$target_dir"

# 生成文件名（简化处理，避免中文字符问题）
# 使用Python来处理文件名生成，避免shell的字符编码问题
filename=$(python3 -c "
import re
import sys
from datetime import datetime

title = sys.argv[1]
# 检查是否包含中文字符
if re.search(r'[\u4e00-\u9fff]', title):
    # 包含中文，使用时间戳
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    print(f'book_{timestamp}')
else:
    # 纯ASCII，转换为kebab-case
    filename = re.sub(r'[^a-zA-Z0-9\-]', '-', title.lower().replace(' ', '-'))
    filename = re.sub(r'-+', '-', filename).strip('-')
    print(filename)
" "$book_title")

target_file="${target_dir}/${filename}.md"

# 检查文件是否已存在
if [ -f "$target_file" ]; then
    echo "警告: 该书的笔记文件已存在: $target_file"
    echo "是否要追加内容到现有文件? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "" >> "$target_file"
        echo "---" >> "$target_file"
        echo "" >> "$target_file"
        echo "## 新增笔记 ($(date +%Y-%m-%d))" >> "$target_file"
        echo "" >> "$target_file"
        echo "$content" >> "$target_file"
        echo "✅ 内容已追加到现有读书笔记"
        exit 0
    else
        echo "操作已取消"
        exit 1
    fi
fi

# 获取当前时间信息
current_year=$(date +%Y)
current_month=$(date +%m)
current_day=$(date +%d)
current_hour=$(date +%H)
current_minute=$(date +%M)
current_second=$(date +%S)

# 使用模板创建文件
template_file="${my_dir}/templates/book.md.tmpl"

if [ -f "$template_file" ]; then
    # 使用模板
    sed -e "s/{{CURRENT_YEAR}}/$current_year/g" \
        -e "s/{{CURRENT_MONTH}}/$current_month/g" \
        -e "s/{{CURRENT_DATE}}/$current_day/g" \
        -e "s/{{CURRENT_HOUR}}/$current_hour/g" \
        -e "s/{{CURRENT_MINUTE}}/$current_minute/g" \
        -e "s/{{CURRENT_SECOND}}/$current_second/g" \
        -e "s/title: /title: $book_title/g" \
        "$template_file" > "$target_file"
    
    # 添加内容
    echo "" >> "$target_file"
    echo "## 笔记" >> "$target_file"
    echo "" >> "$target_file"
    echo "$content" >> "$target_file"
else
    # 手动创建
    cat > "$target_file" << EOF
---
title: $book_title
date: ${current_year}-${current_month}-${current_day}T${current_hour}:${current_minute}:${current_second}+08:00
updated: ${current_year}-${current_month}-${current_day}
taxonomies:
  categories:
    - Books
  tags:
    - Books
    - 阅读
extra:
  rating: 6
  author: 
---

## 笔记

${content}
EOF
fi

echo "✅ 读书笔记已成功创建: $target_file"
echo "📚 书名: $book_title"
echo "📅 日期: $(date +%Y-%m-%d)"
