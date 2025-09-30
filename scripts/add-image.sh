#!/bin/bash

# 图片内容处理脚本
# 用于处理包含图片的备忘录内容

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

# 运行 Apple Cloud Notes Parser 提取图片
echo "正在提取 Apple Notes 中的图片..."
NOTES_PARSER_DIR="apple_cloud_notes_parser"
if [ -d "$NOTES_PARSER_DIR" ]; then
    cd "$NOTES_PARSER_DIR"
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

    # 运行解析器，使用 --one-output-folder 选项总是输出到同一个文件夹
    ruby notes_cloud_ripper.rb --mac ~/Library/Group\ Containers/group.com.apple.notes --one-output-folder > /dev/null 2>&1

    # 检查是否有新的图片文件
    NOTES_OUTPUT_DIR="output/notes_rip"
    if [ -d "$NOTES_OUTPUT_DIR/files" ]; then
        # 创建博客静态文件目录
        BLOG_IMAGES_DIR="../static/images/notes"
        mkdir -p "$BLOG_IMAGES_DIR"

        # 复制所有图片文件到博客目录，使用时间戳避免重名
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        find "$NOTES_OUTPUT_DIR/files" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" \) | while read -r img_file; do
            img_basename=$(basename "$img_file")
            img_name="${img_basename%.*}"
            img_ext="${img_basename##*.}"
            new_name="${TIMESTAMP}_${img_name}.${img_ext}"
            cp "$img_file" "$BLOG_IMAGES_DIR/$new_name"
            echo "复制图片: $new_name"
        done

        echo "已提取图片到: $BLOG_IMAGES_DIR"
    fi

    cd ..
else
    echo "警告: Apple Cloud Notes Parser 未找到，跳过图片提取"
fi

# 生成文件名
DATE=$(date +%Y-%m-%d)
SLUG=$(generate_slug "$TITLE")
FILENAME="${DATE}-${SLUG}.md"
TARGET_DIR="content/blog/images"
TARGET_FILE="$TARGET_DIR/$FILENAME"

# 确保目标目录存在
mkdir -p "$TARGET_DIR"

# 检查文件是否已存在
if [ -f "$TARGET_FILE" ]; then
    echo "文件已存在: $TARGET_FILE"
    exit 1
fi

# 处理内容中的图片引用
PROCESSED_CONTENT="$CONTENT"

# 如果内容包含图片标识，添加图片引用说明
if [[ "$CONTENT" == *"#图片"* ]]; then
    PROCESSED_CONTENT="$CONTENT

---

**📸 图片说明**: 此笔记包含图片内容。图片已从 Apple Notes 中提取并保存到 \`/static/images/notes/\` 目录中。

如需在文章中引用图片，请使用以下格式：
\`\`\`markdown
![图片描述](/images/notes/图片文件名.png)
\`\`\`

可用的图片文件请查看 \`static/images/notes/\` 目录。"
fi

# 生成前置元数据
FRONTMATTER=$(cat << EOF
+++
title = "$TITLE"
date = $(date +%Y-%m-%dT%H:%M:%S%z)
categories = ["图片"]
tags = ["图片", "图文", "照片"]
+++

EOF
)

# 写入文件
echo "$FRONTMATTER" > "$TARGET_FILE"
echo "$PROCESSED_CONTENT" >> "$TARGET_FILE"

echo "✅ 图片内容已保存到: $TARGET_FILE"
