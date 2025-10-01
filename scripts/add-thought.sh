#!/bin/bash

# 添加短想法到 thoughts/index.md 的脚本
# 使用方法: ./add-thought.sh "你的短想法内容" [日期时间]
# 日期时间格式: YYYY-MM-DD 或 YYYY-MM-DD HH:MM
# 使用示例: ./scripts/add-thought.sh "你的短想法内容" [日期时间]

set -e

# 获取脚本所在目录
my_dir="$(dirname "$0")"
source "${my_dir}/common.sh"

# 显示帮助信息
show_help() {
    echo "使用方法: $0 \"短想法内容\" [日期时间]"
    echo ""
    echo "参数说明:"
    echo "  短想法内容  - 要添加的短想法文本"
    echo "  日期时间    - 可选，格式: YYYY-MM-DD 或 YYYY-MM-DD HH:MM"
    echo "               如果不提供，使用当前时间"
    echo ""
    echo "示例:"
    echo "  $0 \"今天天气真好\""
    echo "  $0 \"昨天的想法\" \"2025-09-04\""
    echo "  $0 \"特定时间的想法\" \"2025-09-04 15:30\""
    echo ""
    echo "选项:"
    echo "  -h, --help  显示此帮助信息"
}

# 检查帮助参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 检查是否提供了参数
if [ $# -eq 0 ]; then
    echo "请输入你的短想法内容:"
    read -r thought_content
    echo "请输入日期时间（格式: YYYY-MM-DD 或 YYYY-MM-DD HH:MM，留空使用当前时间）:"
    read -r custom_datetime
else
    thought_content="$1"
    custom_datetime="$2"
fi

# 检查内容是否为空
if [ -z "$thought_content" ]; then
    echo "错误: 短想法内容不能为空"
    exit 1
fi

# 定义文件路径
thoughts_file="${my_dir}/../content/thoughts/index.md"

# 检查文件是否存在
if [ ! -f "$thoughts_file" ]; then
    echo "错误: $thoughts_file 文件不存在"
    exit 1
fi

# 处理日期时间
if [ -n "$custom_datetime" ]; then
    # 验证日期格式
    if echo "$custom_datetime" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}( [0-9]{2}:[0-9]{2})?$'; then
        # 提取日期部分
        target_date=$(echo "$custom_datetime" | cut -d' ' -f1)

        # 验证日期是否有效
        if ! date -j -f "%Y-%m-%d" "$target_date" >/dev/null 2>&1; then
            echo "错误: 无效的日期格式: $target_date"
            exit 1
        fi

        current_date="$target_date"
        current_year=$(echo "$target_date" | cut -d'-' -f1)
        current_month=$(echo "$target_date" | cut -d'-' -f2 | sed 's/^0*//')
        current_day=$(echo "$target_date" | cut -d'-' -f3 | sed 's/^0*//')

        # 格式化日期显示为 YYYY.MM.DD 格式
        current_month_day=$(printf "%04d.%02d.%02d" "$current_year" "$current_month" "$current_day")
    else
        echo "错误: 日期时间格式不正确。请使用 YYYY-MM-DD 或 YYYY-MM-DD HH:MM 格式"
        exit 1
    fi
else
    # 使用当前日期和时间
    current_date=$(date +%Y-%m-%d)
    current_year=$(date +%Y)
    current_month=$(date +%m | sed 's/^0*//')
    current_day=$(date +%d | sed 's/^0*//')
    # 格式化日期显示为 YYYY.MM.DD 格式
    current_month_day=$(printf "%04d.%02d.%02d" "$current_year" "$current_month" "$current_day")
fi

# 创建新的想法条目，处理多行文本
# 将每一行都添加引用符号
formatted_content=$(echo "$thought_content" | sed 's/^/> /' | sed 's/$//')
new_thought="${formatted_content}
>
> - ${current_month_day}"

# 查找当前年份的部分
year_line=$(grep -n "## ${current_year}" "$thoughts_file" | head -1 | cut -d: -f1)

# 创建临时文件
temp_file=$(mktemp)

if [ -z "$year_line" ]; then
    # 如果找不到当前年份，说明是新年份，添加到最上方
    # 找到第一个年份标题的位置
    first_year_line=$(grep -n "^## [0-9]" "$thoughts_file" | head -1 | cut -d: -f1)

    if [ -z "$first_year_line" ]; then
        # 如果连年份标题都没有，添加到文件末尾
        cat "$thoughts_file" > "$temp_file"
        echo "" >> "$temp_file"
        echo "## ${current_year}" >> "$temp_file"
        echo "" >> "$temp_file"
        echo "$new_thought" >> "$temp_file"
        echo "" >> "$temp_file"
    else
        # 在第一个年份标题之前插入新年份
        head -n $((first_year_line - 1)) "$thoughts_file" > "$temp_file"
        echo "## ${current_year}" >> "$temp_file"
        echo "" >> "$temp_file"
        echo "$new_thought" >> "$temp_file"
        echo "" >> "$temp_file"
        echo "" >> "$temp_file"
        tail -n +$first_year_line "$thoughts_file" >> "$temp_file"
    fi
else
    # 找到了当前年份，在年份标题后立即插入新想法(最上方)
    head -n "$year_line" "$thoughts_file" > "$temp_file"
    echo "" >> "$temp_file"
    echo "$new_thought" >> "$temp_file"
    echo "" >> "$temp_file"
    echo "" >> "$temp_file"
    tail -n +$((year_line + 1)) "$thoughts_file" >> "$temp_file"
fi

# 替换原文件
mv "$temp_file" "$thoughts_file"

# 更新文件的 updated 字段
sed -i.bak "s/^updated: .*/updated: ${current_date}/" "$thoughts_file"
rm "${thoughts_file}.bak"

echo "✅ 短想法已成功添加到 thoughts/index.md"
echo "📝 内容: $thought_content"
echo "📅 日期: $current_date"
