#!/bin/bash

# 博客一键设置脚本 - 完全基于控制台
# 适用于 macOS 系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 安装 Homebrew
install_homebrew() {
    if command_exists brew; then
        log_success "Homebrew 已安装"
        return
    fi
    
    log_info "安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # 添加到 PATH
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    
    log_success "Homebrew 安装完成"
}

# 安装 GitHub CLI
install_github_cli() {
    if command_exists gh; then
        log_success "GitHub CLI 已安装"
        return
    fi
    
    log_info "安装 GitHub CLI..."
    brew install gh
    log_success "GitHub CLI 安装完成"
}

# 安装 Cloudflare CLI
install_cloudflare_cli() {
    if command_exists wrangler; then
        log_success "Cloudflare CLI 已安装"
        return
    fi
    
    log_info "安装 Cloudflare CLI..."
    npm install -g wrangler
    log_success "Cloudflare CLI 安装完成"
}

# 安装 Node.js (wrangler 依赖)
install_nodejs() {
    if command_exists node; then
        log_success "Node.js 已安装"
        return
    fi
    
    log_info "安装 Node.js..."
    brew install node
    log_success "Node.js 安装完成"
}

# GitHub 认证
github_auth() {
    if gh auth status >/dev/null 2>&1; then
        log_success "GitHub 已认证"
        return
    fi

    log_info "开始 GitHub 认证..."
    gh auth login
    log_success "GitHub 认证完成"
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

# Fork 和克隆仓库
setup_repository() {
    # 硬编码原始仓库地址
    ORIGINAL_REPO="BlackStar1453/blog"

    echo -n "请输入你的博客名称 (例如: my-blog): "
    read BLOG_NAME < /dev/tty

    # 获取当前用户名
    CURRENT_USER=$(gh api user --jq .login)

    # 创建临时目录进行操作
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    if [ "$CURRENT_USER" = "BlackStar1453" ]; then
        log_info "检测到你是仓库所有者，直接克隆仓库..."
        gh repo clone "$ORIGINAL_REPO"
    else
        log_info "Fork 仓库 $ORIGINAL_REPO..."
        gh repo fork "$ORIGINAL_REPO" --clone --remote
    fi

    # 重命名本地文件夹
    REPO_NAME=$(basename "$ORIGINAL_REPO")
    if [ "$REPO_NAME" != "$BLOG_NAME" ]; then
        mv "$REPO_NAME" "$BLOG_NAME"
    fi

    # 移动到用户指定的位置
    TARGET_DIR="$HOME/$BLOG_NAME"
    if [ -d "$TARGET_DIR" ]; then
        log_warning "目录 $TARGET_DIR 已存在，将使用时间戳后缀"
        TARGET_DIR="$HOME/${BLOG_NAME}_$(date +%Y%m%d_%H%M%S)"
    fi

    mv "$BLOG_NAME" "$TARGET_DIR"
    cd "$TARGET_DIR"

    # 设置全局变量供后续函数使用
    export BLOG_DIR="$TARGET_DIR"

    log_success "仓库设置完成，位置：$BLOG_DIR"
}

# 运行初始化脚本
run_initialization() {
    log_info "运行博客初始化脚本..."

    cd "$BLOG_DIR"

    # 切换到 template-init-v2 分支
    git checkout template-init-v2

    if [ -f "init-template-simple.sh" ]; then
        chmod +x init-template-simple.sh
        ./init-template-simple.sh
    else
        log_warning "未找到初始化脚本，跳过此步骤"
    fi

    log_success "博客初始化完成"
}

# 安装博客依赖
install_blog_dependencies() {
    log_info "安装博客依赖..."

    cd "$BLOG_DIR"

    if [ -f "Makefile" ]; then
        make install
    else
        log_warning "未找到 Makefile，手动安装依赖..."
        brew install zola
    fi

    log_success "博客依赖安装完成"
}

# 配置个人信息
configure_blog() {
    log_info "配置博客个人信息..."

    cd "$BLOG_DIR"

    echo -n "请输入你的博客标题: "
    read BLOG_TITLE < /dev/tty
    echo -n "请输入你的博客描述: "
    read BLOG_DESCRIPTION < /dev/tty
    echo -n "请输入你的姓名: "
    read AUTHOR_NAME < /dev/tty
    echo -n "请输入你的邮箱: "
    read AUTHOR_EMAIL < /dev/tty

    # 获取 GitHub 用户名
    GITHUB_USERNAME=$(gh api user --jq .login)

    # 更新 config.toml
    if [ -f "config.toml" ]; then
        sed -i '' "s|base_url = \".*\"|base_url = \"https://${GITHUB_USERNAME}.github.io\"|" config.toml
        sed -i '' "s|title = \".*\"|title = \"${BLOG_TITLE}\"|" config.toml
        sed -i '' "s|description = \".*\"|description = \"${BLOG_DESCRIPTION}\"|" config.toml
        sed -i '' "s|author = \".*\"|author = \"${AUTHOR_NAME}\"|" config.toml
        sed -i '' "s|email = \".*\"|email = \"${AUTHOR_EMAIL}\"|" config.toml
    fi

    log_success "博客配置完成"
}

# 本地预览
local_preview() {
    log_info "启动本地预览..."
    log_info "博客将在 http://localhost:1111 运行"
    log_info "按 Ctrl+C 停止预览"

    cd "$BLOG_DIR"

    if [ -f "Makefile" ]; then
        make serve
    else
        zola serve
    fi
}

# 部署到 GitHub Pages
deploy_github_pages() {
    log_info "部署到 GitHub Pages..."

    cd "$BLOG_DIR"

    # 提交更改
    git add .
    git commit -m "初始化博客配置"
    git push origin main

    # 启用 GitHub Pages
    gh api repos/:owner/:repo/pages \
        --method POST \
        --field source.branch=main \
        --field source.path=/ \
        2>/dev/null || log_warning "GitHub Pages 可能已经启用"

    GITHUB_USERNAME=$(gh api user --jq .login)
    log_success "博客已部署到: https://${GITHUB_USERNAME}.github.io"
}

# 部署到 Cloudflare Pages
deploy_cloudflare_pages() {
    log_info "部署到 Cloudflare Pages..."

    cd "$BLOG_DIR"

    # 检查 Cloudflare 认证
    cloudflare_auth

    echo -n "请输入 Cloudflare Pages 项目名称: "
    read CF_PROJECT_NAME < /dev/tty

    # 构建博客
    if [ -f "Makefile" ]; then
        make build
    else
        zola build
    fi

    # 创建 Cloudflare Pages 项目
    wrangler pages project create "$CF_PROJECT_NAME" || log_warning "项目可能已存在"

    # 部署
    wrangler pages deploy public --project-name="$CF_PROJECT_NAME"

    log_success "博客已部署到 Cloudflare Pages"
}

# 主函数
main() {
    echo "🚀 博客一键设置脚本"
    echo "===================="
    
    log_info "开始安装必要工具..."
    install_homebrew
    install_nodejs
    install_github_cli
    install_cloudflare_cli
    
    log_info "检查认证状态..."
    github_auth

    echo ""
    echo "GitHub 认证完成！接下来设置博客..."
    echo ""
    
    log_info "设置博客仓库..."
    setup_repository
    
    log_info "初始化博客..."
    run_initialization
    install_blog_dependencies
    configure_blog
    
    echo ""
    echo "🎉 博客设置完成！"
    echo ""
    echo "接下来你可以选择："
    echo "1. 本地预览博客"
    echo "2. 部署到 GitHub Pages"
    echo "3. 部署到 Cloudflare Pages"
    echo "4. 退出"
    echo ""
    
    while true; do
        echo -n "请选择操作 (1-4): "
        read choice < /dev/tty
        case $choice in
            1)
                local_preview
                break
                ;;
            2)
                deploy_github_pages
                break
                ;;
            3)
                deploy_cloudflare_pages
                break
                ;;
            4)
                log_success "设置完成，祝你写作愉快！"
                break
                ;;
            *)
                log_error "无效选择，请输入 1-4"
                ;;
        esac
    done
}

# 运行主函数
main "$@"
