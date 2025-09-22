#!/bin/bash

# 自动git提交脚本
# 使用方法: ./scripts/auto-commit.sh [提交信息] [选项]

set -e

# 获取脚本所在目录
my_dir="$(dirname "$0")"
source "${my_dir}/common.sh"

# 显示帮助信息
show_help() {
    echo "使用方法: $0 [提交信息] [选项]"
    echo ""
    echo "选项:"
    echo "  --selective  - 选择性添加文件（交互式选择）"
    echo "  --all        - 添加所有更改（默认）"
    echo "  --no-push    - 不询问是否推送到远程仓库"
    echo "  -h, --help   - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 \"添加新功能\""
    echo "  $0 \"修复bug\" --selective"
    echo "  $0 \"更新文档\" --no-push"
}

# 解析参数
commit_message=""
selective_mode="false"
no_push="false"

while [ $# -gt 0 ]; do
    case "$1" in
        --selective)
            selective_mode="true"
            shift
            ;;
        --all)
            selective_mode="false"
            shift
            ;;
        --no-push)
            no_push="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "错误: 未知选项 $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$commit_message" ]; then
                commit_message="$1"
            else
                echo "错误: 过多的参数"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# 获取当前日期作为默认提交信息
default_commit_message="Update: $(date +%Y-%m-%d)"

# 如果没有提供提交信息，询问用户
if [ -z "$commit_message" ]; then
    echo "请输入提交信息（留空使用默认: $default_commit_message）:"
    read -r user_input
    if [ -n "$user_input" ]; then
        commit_message="$user_input"
    else
        commit_message="$default_commit_message"
    fi
fi

# 切换到项目根目录
cd "${my_dir}/.."

# 检查是否在git仓库中
if [ ! -d ".git" ]; then
    echo "错误: 当前目录不是git仓库"
    exit 1
fi

# 检查是否有更改
if git diff --quiet && git diff --cached --quiet; then
    echo "ℹ️  没有检测到更改，无需提交"
    exit 0
fi

echo "📋 检查git状态..."
git status --short

echo ""
echo "📝 提交信息: $commit_message"
echo ""

# 询问确认
echo "是否继续提交? (Y/n)"
read -r confirm
if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
    echo "操作已取消"
    exit 0
fi

# 添加更改
if [ "$selective_mode" = "true" ]; then
    echo "📦 选择性添加文件..."
    echo "请选择要添加的文件（输入文件编号，多个文件用空格分隔，输入 'a' 添加所有文件）:"

    # 显示未暂存的文件
    echo ""
    echo "未暂存的更改:"
    git status --porcelain | grep -E "^( M| D|\\?\\?)" | nl -w2 -s') '

    echo ""
    read -r file_selection

    if [ "$file_selection" = "a" ] || [ "$file_selection" = "A" ]; then
        git add .
    else
        # 解析用户选择的文件编号
        for num in $file_selection; do
            if [[ "$num" =~ ^[0-9]+$ ]]; then
                file_path=$(git status --porcelain | grep -E "^( M| D|\\?\\?)" | sed -n "${num}p" | cut -c4-)
                if [ -n "$file_path" ]; then
                    git add "$file_path"
                    echo "✅ 已添加: $file_path"
                fi
            fi
        done
    fi
else
    echo "📦 添加所有更改..."
    git add .
fi

# 显示将要提交的更改
echo ""
echo "📋 将要提交的更改:"
git diff --cached --stat

echo ""

# 提交更改
echo "🚀 提交更改..."
git commit -m "$commit_message"

echo ""
echo "✅ 提交成功!"
echo "📝 提交信息: $commit_message"
echo "🔗 最新提交: $(git rev-parse --short HEAD)"

# 询问是否推送到远程仓库
if [ "$no_push" = "false" ]; then
    echo ""
    echo "是否推送到远程仓库? (y/N)"
    read -r push_confirm
    if [ "$push_confirm" = "y" ] || [ "$push_confirm" = "Y" ]; then
        echo "🌐 推送到远程仓库..."

        # 获取当前分支
        current_branch=$(git branch --show-current)

        # 检查是否有远程仓库
        if git remote | grep -q origin; then
            git push origin "$current_branch"
            echo "✅ 推送成功!"
        else
            echo "⚠️  未找到远程仓库 'origin'"
        fi
    else
        echo "ℹ️  跳过推送，更改仅保存在本地"
    fi
else
    echo "ℹ️  跳过推送（--no-push 选项）"
fi

echo ""
echo "🎉 操作完成!"
