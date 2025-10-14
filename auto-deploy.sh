#!/bin/bash

# 自动部署脚本
# 功能：检查修改 -> Git 提交 -> 构建 -> 部署到 Cloudflare Pages
# 使用方法: ./auto-deploy.sh [提交信息]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    local missing_deps=()
    
    if ! command_exists git; then
        missing_deps+=("git")
    fi
    
    if ! command_exists wrangler; then
        missing_deps+=("wrangler")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "缺少以下依赖: ${missing_deps[*]}"
        echo ""
        echo "请安装缺少的依赖："
        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                git)
                    echo "  - Git: https://git-scm.com/downloads"
                    ;;
                wrangler)
                    echo "  - Wrangler: npm install -g wrangler"
                    ;;
            esac
        done
        return 1
    fi
    
    log_success "所有依赖已安装"
    return 0
}

# 检查是否在 Git 仓库中
check_git_repo() {
    if [ ! -d ".git" ]; then
        log_error "当前目录不是 Git 仓库"
        echo ""
        echo "请先初始化 Git 仓库："
        echo "  git init"
        echo "  git add ."
        echo "  git commit -m \"Initial commit\""
        return 1
    fi
    return 0
}

# 检查 Cloudflare 认证
check_cloudflare_auth() {
    log_info "检查 Cloudflare 认证状态..."
    
    if wrangler whoami >/dev/null 2>&1; then
        log_success "Cloudflare 已认证"
        return 0
    else
        log_warning "Cloudflare 未认证"
        echo ""
        echo "请先登录 Cloudflare:"
        echo "  wrangler login"
        echo ""
        return 1
    fi
}

# 检查是否有修改
check_changes() {
    log_info "检查文件修改..."

    # 检查工作区修改（未暂存的修改）
    if ! git diff --quiet; then
        log_success "检测到工作区修改"
        return 0
    fi

    # 检查暂存区修改（已 add 但未 commit 的修改）
    if ! git diff --cached --quiet; then
        log_success "检测到暂存区修改"
        return 0
    fi

    # 检查未跟踪的文件（新创建的文件）
    if [ -n "$(git ls-files --others --exclude-standard)" ]; then
        log_success "检测到新文件"
        return 0
    fi

    log_info "没有检测到修改"
    return 1
}

# 显示修改状态
show_status() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 当前修改状态"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    git status --short
    echo ""
}

# Git 提交
git_commit() {
    local commit_message="$1"
    
    log_info "添加所有修改到 Git..."
    git add .
    
    log_info "提交修改..."
    if git commit -m "$commit_message"; then
        log_success "Git 提交成功"
        echo "📝 提交信息: $commit_message"
        echo "🔗 提交哈希: $(git rev-parse --short HEAD)"
        return 0
    else
        log_error "Git 提交失败"
        return 1
    fi
}

# 构建博客
build_blog() {
    log_info "构建博客..."
    
    if [ -f "Makefile" ]; then
        make build
    elif command_exists zola; then
        zola build
    else
        log_error "未找到构建工具（Makefile 或 zola）"
        return 1
    fi
    
    if [ ! -d "public" ]; then
        log_error "构建失败：未找到 public 目录"
        return 1
    fi
    
    log_success "博客构建完成"
    return 0
}

# 部署到 Cloudflare Pages
deploy_to_cloudflare() {
    local project_name="$1"
    
    log_info "部署到 Cloudflare Pages..."
    
    if wrangler pages deploy public --project-name="$project_name"; then
        log_success "部署成功！"
        
        # 获取部署 URL
        local deploy_url="https://${project_name}.pages.dev"
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉 部署成功！"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "🌐 访问地址: $deploy_url"
        echo "📊 Cloudflare Dashboard: https://dash.cloudflare.com"
        echo ""
        
        return 0
    else
        log_error "部署失败"
        return 1
    fi
}

# 获取 Cloudflare Pages 项目名称
get_project_name() {
    # 尝试从 config.toml 获取项目名称
    if [ -f "config.toml" ]; then
        local base_url=$(grep '^base_url = ' config.toml | sed 's/base_url = "\(.*\)"/\1/' || echo "")
        if [[ "$base_url" =~ https://([^.]+)\.pages\.dev ]]; then
            echo "${BASH_REMATCH[1]}"
            return 0
        fi
    fi
    
    # 如果无法从 config.toml 获取，列出现有项目
    log_info "无法从 config.toml 获取项目名称"
    echo ""
    echo "现有的 Cloudflare Pages 项目："
    wrangler pages project list 2>/dev/null || echo "  (无)"
    echo ""
    
    echo -n "请输入项目名称: "
    read -r project_name
    
    if [ -z "$project_name" ]; then
        log_error "项目名称不能为空"
        return 1
    fi
    
    echo "$project_name"
    return 0
}

# 主函数
main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 自动部署脚本"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # 检查依赖
    if ! check_dependencies; then
        exit 1
    fi
    
    echo ""
    
    # 检查 Git 仓库
    if ! check_git_repo; then
        exit 1
    fi
    
    # 检查 Cloudflare 认证
    if ! check_cloudflare_auth; then
        exit 1
    fi
    
    echo ""
    
    # 检查是否有修改
    if ! check_changes; then
        log_info "没有需要部署的修改"
        echo ""
        echo "如果你想强制重新部署，可以使用："
        echo "  ./deploy-to-cloudflare.sh"
        exit 0
    fi
    
    # 显示修改状态
    show_status
    
    # 获取提交信息
    local commit_message="$1"
    if [ -z "$commit_message" ]; then
        local default_message="Update: $(date +%Y-%m-%d\ %H:%M:%S)"
        echo "请输入提交信息（留空使用默认: $default_message）:"
        read -r user_input
        if [ -n "$user_input" ]; then
            commit_message="$user_input"
        else
            commit_message="$default_message"
        fi
    fi
    
    echo ""
    echo "📝 提交信息: $commit_message"
    echo ""
    
    # 询问确认
    echo "是否继续提交并部署? (Y/n)"
    read -r confirm
    if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
        log_info "操作已取消"
        exit 0
    fi
    
    echo ""
    
    # Git 提交
    if ! git_commit "$commit_message"; then
        exit 1
    fi
    
    echo ""
    
    # 构建博客
    if ! build_blog; then
        exit 1
    fi
    
    echo ""
    
    # 获取项目名称
    PROJECT_NAME=$(get_project_name)
    if [ -z "$PROJECT_NAME" ]; then
        exit 1
    fi
    
    echo ""
    
    # 部署到 Cloudflare Pages
    if ! deploy_to_cloudflare "$PROJECT_NAME"; then
        exit 1
    fi
    
    echo ""
    echo "🎉 全部完成！"
    echo ""
}

# 运行主函数
main "$@"

