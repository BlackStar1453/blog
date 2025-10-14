#!/bin/bash

# 博客文章创建脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}📝 创建新博客文章${NC}\n"

# 获取文章信息
read -p "文章标题: " title
read -p "文章描述: " description
read -p "标签 (用逗号分隔): " tags_input
read -p "分类 (默认: Blog): " category
category=${category:-Blog}

# 处理标签
IFS=',' read -ra tags_array <<< "$tags_input"
tags_formatted=""
for tag in "${tags_array[@]}"; do
    tag=$(echo "$tag" | xargs)  # 去除空格
    tags_formatted+="\"$tag\", "
done
tags_formatted=${tags_formatted%, }  # 移除最后的逗号和空格

# 生成文件名（从标题转换）
filename=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
current_date=$(date +%Y-%m-%d)
article_file="content/blog/${filename}.md"

# 创建文章
cat > "$article_file" << EOF
+++
title = "$title"
date = $current_date
updated = $current_date
description = "$description"
[taxonomies]
tags = [$tags_formatted]
categories = ["$category"]
+++

# $title

在这里开始写你的文章内容...

## 小节标题

文章内容...

EOF

echo -e "\n${GREEN}✓ 文章已创建：${NC}$article_file"
echo -e "${YELLOW}现在可以编辑这个文件来完善你的文章内容${NC}"

