#!/bin/bash

# Cloudflare Pages 部署脚本
# 用于构建和部署博客到 Cloudflare Pages

set -e

# 颜色输出
log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[SUCCESS] $1"
}

log_warning() {
    echo "[WARNING] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查 wrangler 是否已安装
check_wrangler() {
    if ! command_exists wrangler; then
        log_error "未找到 wrangler CLI"
        echo ""
        echo "请先安装 wrangler:"
        echo "  npm install -g wrangler"
        echo ""
        exit 1
    fi
    log_success "wrangler CLI 已安装"
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
        echo -n "是否现在登录? [y/N]: "
        read -r answer < /dev/tty
        
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            wrangler login
            log_success "Cloudflare 认证完成"
        else
            log_error "需要 Cloudflare 认证才能继续"
            exit 1
        fi
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
        exit 1
    fi
    
    if [ ! -d "public" ]; then
        log_error "构建失败：未找到 public 目录"
        exit 1
    fi
    
    log_success "博客构建完成"
}

# 部署到 Cloudflare Pages
deploy_to_cloudflare() {
    local project_name="$1"

    log_info "部署到 Cloudflare Pages..."

    # 部署
    if wrangler pages deploy public --project-name="$project_name"; then
        log_success "部署成功！"

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉 部署成功！"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "🌐 访问地址: $DEPLOY_URL"
        echo "📊 Cloudflare Dashboard: https://dash.cloudflare.com"
        echo ""

        return 0
    else
        log_error "部署失败"
        return 1
    fi
}

# 更新 config.toml 中的所有 URL
update_config_urls() {
    local new_url="$1"
    
    if [ ! -f "config.toml" ]; then
        log_warning "未找到 config.toml，跳过 URL 更新"
        return
    fi
    
    log_info "更新 config.toml 中的 URL..."
    
    # 检查当前的 base_url
    CURRENT_BASE_URL=$(grep '^base_url = ' config.toml | sed 's/base_url = "\(.*\)"/\1/' || echo "")
    
    # 只有当 URL 发生变化时才更新
    if [ "$CURRENT_BASE_URL" != "$new_url" ]; then
        # 更新 base_url
        sed -i '' "s|^base_url = \".*\"|base_url = \"$new_url\"|" config.toml
        
        # 更新 extra 部分的 URL（如果存在）
        sed -i '' "s|^prefix_url = \".*\"|prefix_url = \"$new_url\"|" config.toml
        sed -i '' "s|^indieweb_url = \".*\"|indieweb_url = \"$new_url\"|" config.toml
        
        log_success "已更新所有 URL 为: $new_url"
        
        # 提交配置更改
        if command_exists git && [ -d ".git" ]; then
            git add config.toml
            git commit -m "更新 URL 为 Cloudflare Pages 固定域名" || log_warning "配置文件未发生变化"
        fi
    else
        log_info "URL 未发生变化，跳过更新"
    fi
}

# 获取或创建项目
get_or_create_project() {
    log_info "检查 Cloudflare Pages 项目..."
    
    # 列出现有项目
    echo ""
    echo "现有的 Cloudflare Pages 项目："
    wrangler pages project list 2>/dev/null || echo "  (无)"
    echo ""
    
    echo -n "请输入项目名称（新建或使用现有）: "
    read -r project_name < /dev/tty
    
    if [ -z "$project_name" ]; then
        log_error "项目名称不能为空"
        exit 1
    fi
    
    # 尝试创建项目（如果已存在会失败，但不影响后续部署）
    log_info "准备项目: $project_name"
    if wrangler pages project create "$project_name" --production-branch="main" 2>/dev/null; then
        log_success "项目创建成功"
    else
        log_info "项目已存在，将直接部署"
    fi
    
    echo "$project_name"
}

# 主函数
main() {
    echo "🚀 Cloudflare Pages 部署脚本"
    echo "================================"
    echo ""

    # 检查依赖
    check_wrangler
    check_cloudflare_auth

    echo ""

    # 获取或创建项目
    PROJECT_NAME=$(get_or_create_project)

    echo ""

    # 获取项目固定域名（在构建之前）
    log_info "获取项目固定域名..."
    FIXED_DOMAIN=$(wrangler pages project list 2>/dev/null | \
        awk -v proj="$PROJECT_NAME" '$2 == proj {print $4}' | \
        grep '\.pages\.dev' | \
        sed 's/,$//' | \
        head -1)

    if [ -n "$FIXED_DOMAIN" ]; then
        DEPLOY_URL="https://$FIXED_DOMAIN"
        log_success "✅ 固定域名: $DEPLOY_URL"
    else
        # 如果无法获取，使用项目名称构建
        DEPLOY_URL="https://${PROJECT_NAME}.pages.dev"
        log_info "使用默认域名: $DEPLOY_URL"
    fi

    # 更新 config.toml（在构建之前）
    update_config_urls "$DEPLOY_URL"

    echo ""

    # 构建博客（使用更新后的 config.toml）
    build_blog

    echo ""

    # 部署
    deploy_to_cloudflare "$PROJECT_NAME"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 下次部署"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "快速部署命令："
    echo "  ./deploy-to-cloudflare.sh"
    echo ""
    echo "或者手动执行："
    echo "  make build"
    echo "  wrangler pages deploy public --project-name=$PROJECT_NAME"
    echo ""
}

# 运行主函数
main

