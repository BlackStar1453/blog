#!/bin/bash

# Cloudflare Pages 部署测试脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Cloudflare 认证
cloudflare_auth() {
    if wrangler whoami >/dev/null 2>&1; then
        log_success "Cloudflare 已认证"
        return
    fi
    
    log_info "开始 Cloudflare 认证..."
    wrangler login
    log_success "Cloudflare 认证完成"
}

# 部署到 Cloudflare Pages
deploy_cloudflare_pages() {
    log_info "部署到 Cloudflare Pages..."

    # 检查 Cloudflare 认证
    cloudflare_auth

    echo -n "请输入 Cloudflare Pages 项目名称: "
    read CF_PROJECT_NAME < /dev/tty

    # 提交所有更改
    log_info "提交更改到Git..."
    git add .
    git commit -m "准备部署到Cloudflare Pages" || log_warning "没有新的更改需要提交"

    # 构建博客
    log_info "构建博客..."
    if [ -f "Makefile" ]; then
        make build
    else
        zola build
    fi

    # 创建 Cloudflare Pages 项目（指定生产分支）
    log_info "创建 Cloudflare Pages 项目..."
    if wrangler pages project create "$CF_PROJECT_NAME" --production-branch=template-init-v2; then
        log_success "项目创建成功"
    else
        log_warning "项目可能已存在，继续部署..."
    fi

    # 部署（不使用任何可能导致非交互模式的参数）
    log_info "部署到 Cloudflare Pages..."
    echo "执行命令: wrangler pages deploy public --project-name=\"$CF_PROJECT_NAME\""
    
    # 捕获部署输出
    DEPLOY_LOG=$(mktemp)
    if wrangler pages deploy public --project-name="$CF_PROJECT_NAME" 2>&1 | tee "$DEPLOY_LOG"; then
        log_success "博客已部署到 Cloudflare Pages"

        # 从部署输出中提取实际的访问地址
        DEPLOY_URL=$(grep -o 'https://[^[:space:]]*\.pages\.dev' "$DEPLOY_LOG" | tail -1 || echo "")

        # 如果没有找到完整URL，使用项目名称构建
        if [ -z "$DEPLOY_URL" ]; then
            DEPLOY_URL="https://${CF_PROJECT_NAME}.pages.dev"
        fi

        # 更新config.toml中的base_url
        log_info "更新config.toml中的base_url..."
        if [ -f "config.toml" ]; then
            # 使用sed更新base_url
            sed -i '' "s|^base_url = \".*\"|base_url = \"$DEPLOY_URL\"|" config.toml
            log_success "已更新base_url为: $DEPLOY_URL"

            # 提交配置更改
            git add config.toml
            git commit -m "更新base_url为部署地址: $DEPLOY_URL" || log_warning "配置文件未发生变化"
        fi

        # 获取Cloudflare账户ID
        ACCOUNT_ID=$(wrangler whoami | grep -o '[a-f0-9]\{32\}' | head -1 || echo "")

        if [ -n "$ACCOUNT_ID" ]; then
            DASHBOARD_URL="https://dash.cloudflare.com/${ACCOUNT_ID}/pages/view/${CF_PROJECT_NAME}"
            echo ""
            echo "🎉 部署成功！"
            echo "🌐 访问地址: $DEPLOY_URL"
            echo "📊 查看部署详情: $DASHBOARD_URL"
            echo "💡 在Dashboard中可以查看部署状态和设置"
        else
            echo ""
            echo "🎉 部署成功！"
            echo "🌐 访问地址: $DEPLOY_URL"
            echo "📊 请访问 Cloudflare Dashboard 查看部署详情"
            echo "💡 地址: https://dash.cloudflare.com -> Pages -> $CF_PROJECT_NAME"
        fi

        # 清理临时文件
        rm -f "$DEPLOY_LOG"
    else
        log_error "部署失败，请检查项目名称是否正确"
        rm -f "$DEPLOY_LOG"
    fi
}

# 主函数
main() {
    echo "🚀 Cloudflare Pages 部署测试脚本"
    echo "=================================="
    
    # 检查必要工具
    if ! command_exists wrangler; then
        log_error "Cloudflare CLI (wrangler) 未安装，请先安装: npm install -g wrangler"
        exit 1
    fi
    
    if ! command_exists zola && ! [ -f "Makefile" ]; then
        log_error "Zola 未安装且没有 Makefile，请先安装 Zola"
        exit 1
    fi
    
    deploy_cloudflare_pages
}

# 运行主函数
main "$@"
