#!/bin/bash

# 创建空白md文档的脚本
# 使用方法: ./create-md.sh [路径] [标题] [模板类型]

set -e

# 获取脚本所在目录
my_dir="$(dirname "$0")"
source "${my_dir}/common.sh"

# 显示帮助信息
show_help() {
    echo "使用方法: $0 [路径] [标题] [模板类型] [选项]"
    echo ""
    echo "参数说明:"
    echo "  路径        - 相对于content目录的路径，如 'blog/articles' 或 'poem'"
    echo "  标题        - 文档标题"
    echo "  模板类型    - 可选的模板类型: articles, book, dev, notes, random, daily"
    echo ""
    echo "选项:"
    echo "  --draft     - 创建草稿文档（draft: true）"
    echo "  --published - 创建已发布文档（draft: false，默认）"
    echo "  -h, --help  - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 blog/articles \"我的新文章\" articles"
    echo "  $0 blog/articles \"草稿文章\" articles --draft"
    echo "  $0 poem \"新诗歌\" notes"
    echo "  $0 story \"新故事\""
    echo ""
    echo "如果不提供参数，脚本将进入交互模式"
}

# 检查参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 解析参数
target_path=""
title=""
template_type=""
is_draft="false"

# 解析命令行参数
while [ $# -gt 0 ]; do
    case "$1" in
        --draft)
            is_draft="true"
            shift
            ;;
        --published)
            is_draft="false"
            shift
            ;;
        -*)
            echo "错误: 未知选项 $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$target_path" ]; then
                target_path="$1"
            elif [ -z "$title" ]; then
                title="$1"
            elif [ -z "$template_type" ]; then
                template_type="$1"
            else
                echo "错误: 过多的参数"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# 交互式输入缺失的参数
if [ -z "$target_path" ]; then
    echo "请输入目标路径（相对于content目录，如 'blog/articles' 或 'poem'）:"
    read -r target_path
fi

if [ -z "$title" ]; then
    echo "请输入文档标题:"
    read -r title
fi

if [ -z "$template_type" ]; then
    echo "请选择模板类型（可选: articles, book, dev, notes, random, daily，留空使用默认）:"
    read -r template_type
fi

if [ "$is_draft" = "false" ]; then
    echo "是否创建为草稿? (y/N)"
    read -r draft_confirm
    if [ "$draft_confirm" = "y" ] || [ "$draft_confirm" = "Y" ]; then
        is_draft="true"
    fi
fi

# 检查必要参数
if [ -z "$target_path" ]; then
    echo "错误: 目标路径不能为空"
    exit 1
fi

if [ -z "$title" ]; then
    echo "错误: 标题不能为空"
    exit 1
fi

# 处理路径
target_path=$(echo "$target_path" | sed 's|^/||' | sed 's|/$||')  # 移除开头和结尾的斜杠
full_target_dir="${my_dir}/../content/${target_path}"

# 创建目标目录（如果不存在）
if [ ! -d "$full_target_dir" ]; then
    mkdir -p "$full_target_dir"
    echo "✅ 创建目录: $full_target_dir"
fi

# 生成文件名（将标题转换为kebab-case）
filename=$(echo "$title" | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g' | tr '[:upper:]' '[:lower:]')

# 如果文件名为空或只包含特殊字符，使用时间戳
if [ -z "$filename" ] || [ "$filename" = "-" ]; then
    filename="untitled-$(date +%Y%m%d-%H%M%S)"
fi

# 确定文件路径
if [ -f "${full_target_dir}/index.md" ]; then
    # 如果目录下已有index.md，创建单独的文件
    file_path="${full_target_dir}/${filename}.md"
else
    # 否则创建index.md
    file_path="${full_target_dir}/index.md"
fi

# 检查文件是否已存在
if [ -f "$file_path" ]; then
    echo "警告: 文件 $file_path 已存在"
    echo "是否覆盖? (y/N)"
    read -r confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "操作已取消"
        exit 0
    fi
fi

# 选择模板
template_file=""
if [ -n "$template_type" ] && [ -f "${my_dir}/templates/${template_type}.md.tmpl" ]; then
    template_file="${my_dir}/templates/${template_type}.md.tmpl"
else
    # 根据路径自动选择模板
    case "$target_path" in
        blog/books*|books*)
            template_file="${my_dir}/templates/book.md.tmpl"
            ;;
        blog/articles*|articles*)
            template_file="${my_dir}/templates/articles.md.tmpl"
            ;;
        blog/journals*|journals*)
            template_file="${my_dir}/templates/daily.md.tmpl"
            ;;
        blog*)
            template_file="${my_dir}/templates/dev.md.tmpl"
            ;;
        *)
            template_file="${my_dir}/templates/notes.md.tmpl"
            ;;
    esac
fi

# 创建文件内容
if [ -f "$template_file" ]; then
    # 使用模板
    export TITLE="$title"
    cat "$template_file" | ${my_dir}/mo.sh > "$file_path"
    # 替换标题
    sed -i.bak "s/^title: .*/title: $title/" "$file_path"

    # 处理draft状态
    if [ "$is_draft" = "true" ]; then
        # 如果模板中没有draft字段，添加它
        if ! grep -q "^draft:" "$file_path"; then
            # 在date行后添加draft字段，确保换行正确
            sed -i.bak "/^date:/a\\
draft: true\\
" "$file_path"
        else
            sed -i.bak "s/^draft: .*/draft: true/" "$file_path"
        fi
    else
        # 确保draft为false或移除draft字段
        if grep -q "^draft:" "$file_path"; then
            sed -i.bak "s/^draft: .*/draft: false/" "$file_path"
        fi
    fi

    rm "${file_path}.bak"
else
    # 使用默认模板
    draft_line=""
    if [ "$is_draft" = "true" ]; then
        draft_line="draft: true"
    fi

    cat > "$file_path" << EOF
---
title: $title
date: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}T${CURRENT_HOUR}:${CURRENT_MINUTE}:${CURRENT_SECOND}+08:00
updated: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}
${draft_line}
taxonomies:
  categories:
    - Notes
  tags:
    -
---

<!-- more -->
EOF
fi

echo "✅ 成功创建文档: $file_path"
echo "📝 标题: $title"
echo "📁 路径: content/$target_path"
echo "📄 模板: $(basename "$template_file" .md.tmpl)"
echo "📋 状态: $(if [ "$is_draft" = "true" ]; then echo "草稿"; else echo "已发布"; fi)"
