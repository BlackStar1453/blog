#!/bin/bash

# 博客助手主脚本
# 集成所有博客操作功能

set -e

# 获取脚本所在目录
my_dir="$(dirname "$0")"

# 显示帮助信息
show_help() {
    echo "博客助手 - 自动化博客操作工具"
    echo ""
    echo "使用方法: $0 <命令> [参数...]"
    echo ""
    echo "可用命令:"
    echo "  thought <内容> [时间]    - 添加短想法到thoughts"
    echo "  create <路径> <标题> [模板] [选项] - 创建新的md文档"
    echo "  commit [信息] [选项]     - 自动git提交"
    echo "  help                     - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 thought \"今天天气真好\""
    echo "  $0 thought \"昨天的想法\" \"2025-09-04\""
    echo "  $0 thought \"特定时间的想法\" \"2025-09-04 15:30\""
    echo "  $0 create \"poem\" \"新诗歌\" \"notes\""
    echo "  $0 create \"blog/articles\" \"我的文章\" \"articles\""
    echo "  $0 create \"blog/articles\" \"草稿文章\" \"articles\" --draft"
    echo "  $0 commit \"添加新内容\""
    echo "  $0 commit \"修复bug\" --selective"
    echo "  $0 commit  # 使用默认提交信息"
    echo ""
    echo "快捷工作流:"
    echo "  1. 添加短想法: $0 thought \"内容\" [时间]"
    echo "  2. 创建文档: $0 create \"路径\" \"标题\""
    echo "  3. 提交更改: $0 commit"
}

# 检查参数
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

command="$1"
shift

case "$command" in
    "thought")
        if [ $# -eq 0 ]; then
            echo "错误: 请提供短想法内容"
            echo "使用方法: $0 thought \"你的短想法内容\" [时间]"
            exit 1
        fi
        "${my_dir}/add-thought.sh" "$1" "$2"
        ;;
    
    "create")
        if [ $# -lt 2 ]; then
            echo "错误: 请提供路径和标题"
            echo "使用方法: $0 create <路径> <标题> [模板类型] [选项]"
            exit 1
        fi
        # 传递所有参数给create-md.sh
        "${my_dir}/create-md.sh" "$@"
        ;;
    
    "commit")
        # 传递所有参数给auto-commit.sh
        "${my_dir}/auto-commit.sh" "$@"
        ;;
    
    "help"|"-h"|"--help")
        show_help
        ;;
    
    *)
        echo "错误: 未知命令 '$command'"
        echo ""
        show_help
        exit 1
        ;;
esac
