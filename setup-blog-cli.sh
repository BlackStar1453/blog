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
    gh auth login -h github.com
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

# 克隆仓库 - 直接克隆模板仓库
setup_repository() {
    TEMPLATE_REPO="moris1999/blog"

    log_info "克隆模板仓库 $TEMPLATE_REPO..."

    # 获取当前用户名
    GITHUB_USER=$(gh api user --jq .login)

    # 确定克隆目录
    BLOG_DIR="$HOME/blog"
    if [ -d "$BLOG_DIR" ]; then
        log_warning "目录 $BLOG_DIR 已存在，将使用时间戳后缀"
        BLOG_DIR="$HOME/blog_$(date +%Y%m%d_%H%M%S)"
    fi

    # 直接克隆模板仓库
    log_info "克隆仓库到 $BLOG_DIR..."
    git clone "https://github.com/$TEMPLATE_REPO.git" "$BLOG_DIR" || {
        log_error "克隆失败，请检查网络连接"
        exit 1
    }

    cd "$BLOG_DIR"

    # 移除原始的 origin 远程仓库
    git remote remove origin
    log_info "已移除原始远程仓库"

    # 配置 Git 使用 gh 作为凭证助手
    git config --local credential.helper ""
    git config --local --add credential.helper '!gh auth git-credential'
    log_info "已配置 Git 使用 GitHub CLI 凭证"

    # 配置 Git 用户信息为当前 GitHub 用户
    git config --local user.name "$GITHUB_USER"
    git config --local user.email "${GITHUB_USER}@users.noreply.github.com"
    log_info "已配置 Git 用户: $GITHUB_USER"

    # 确保在 main 分支
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" != "main" ]; then
        log_info "当前分支: $CURRENT_BRANCH，切换到 main 分支..."
        if git show-ref --verify --quiet refs/heads/main; then
            git checkout main
        elif git show-ref --verify --quiet refs/remotes/origin/main; then
            git checkout -b main
        else
            log_warning "未找到 main 分支，将使用当前分支: $CURRENT_BRANCH"
        fi
        CURRENT_BRANCH=$(git branch --show-current)
    fi
    log_info "当前分支: $CURRENT_BRANCH"

    # 设置全局变量
    export BLOG_DIR
    export GITHUB_REPO_NAME="blog"

    log_success "仓库克隆完成，位置：$BLOG_DIR"
    log_info "提示：稍后需要创建自己的 GitHub 仓库并设置为 origin"
}

# 运行初始化脚本
run_initialization() {
    log_info "运行博客初始化脚本..."

    cd "$BLOG_DIR"

    if [ -f "init-template.sh" ]; then
        chmod +x init-template.sh
        ./init-template.sh
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
        # 使用更精确的 sed 模式，只替换顶层配置
        # 注意：不设置 base_url，将在部署到 Cloudflare Pages 后自动设置为固定域名

        # 1. 替换 title（在文件开头部分，在第一个 section 之前）
        sed -i '' '1,/^\[/s|^title = ".*"|title = "'"${BLOG_TITLE}"'"|' config.toml

        # 2. 替换 description（在文件开头部分，在第一个 section 之前）
        sed -i '' '1,/^\[/s|^description = ".*"|description = "'"${BLOG_DESCRIPTION}"'"|' config.toml

        # 3. 替换 [extra] section 中的 author
        sed -i '' '/^\[extra\]/,/^\[/{s|^author = ".*"|author = "'"${AUTHOR_NAME}"'"|;}' config.toml

        # 5. 替换 [extra] section 中的 email
        sed -i '' '/^\[extra\]/,/^\[/{s|^email = ".*"|email = "'"${AUTHOR_EMAIL}"'"|;}' config.toml
    fi

    log_success "博客配置完成"
}

# 创建 GitHub 仓库并设置为 origin
create_github_repo() {
    log_info "创建 GitHub 仓库..."

    cd "$BLOG_DIR"

    # 获取当前用户名
    GITHUB_USER=$(gh api user --jq .login)

    # 询问仓库名称
    echo ""
    echo -n "请输入 GitHub 仓库名称 [默认: blog]: "
    read REPO_NAME < /dev/tty
    REPO_NAME=${REPO_NAME:-blog}

    # 检查仓库是否已存在
    if gh api "repos/$GITHUB_USER/$REPO_NAME" >/dev/null 2>&1; then
        log_warning "仓库 $GITHUB_USER/$REPO_NAME 已存在"
        echo ""
        echo "选项："
        echo "1. 使用现有仓库（会强制推送，覆盖远程内容）"
        echo "2. 使用不同的仓库名称"
        echo "3. 跳过创建仓库"
        echo -n "请选择 [1/2/3]: "
        read CHOICE < /dev/tty

        case $CHOICE in
            1)
                log_info "使用现有仓库: $GITHUB_USER/$REPO_NAME"
                ;;
            2)
                echo -n "请输入新的仓库名称: "
                read REPO_NAME < /dev/tty
                # 递归调用自己（但这次仓库名不同）
                export GITHUB_REPO_NAME="$REPO_NAME"
                create_github_repo
                return
                ;;
            3)
                log_warning "跳过创建 GitHub 仓库"
                return
                ;;
            *)
                log_error "无效选择"
                exit 1
                ;;
        esac
    else
        # 创建新仓库
        log_info "创建新仓库: $GITHUB_USER/$REPO_NAME"

        # 询问仓库可见性
        echo ""
        echo "仓库可见性："
        echo "1. Public（公开）"
        echo "2. Private（私有）"
        echo -n "请选择 [1/2，默认: 1]: "
        read VISIBILITY_CHOICE < /dev/tty
        VISIBILITY_CHOICE=${VISIBILITY_CHOICE:-1}

        if [ "$VISIBILITY_CHOICE" = "2" ]; then
            VISIBILITY_FLAG="--private"
        else
            VISIBILITY_FLAG="--public"
        fi

        # 创建仓库
        gh repo create "$GITHUB_USER/$REPO_NAME" \
            $VISIBILITY_FLAG \
            --description "My personal blog powered by Zola and Cloudflare Pages" \
            --source=. \
            --remote=origin || {
            log_error "创建仓库失败"
            exit 1
        }

        log_success "仓库创建成功: $GITHUB_USER/$REPO_NAME"
    fi

    # 设置 origin 远程仓库（如果还没有设置）
    if ! git remote | grep -q "^origin$"; then
        git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
        log_info "已添加 origin 远程仓库"
    fi

    # 设置 gh CLI 默认仓库
    gh repo set-default "$GITHUB_USER/$REPO_NAME"
    log_info "已设置默认仓库: $GITHUB_USER/$REPO_NAME"

    # 推送到 GitHub
    log_info "推送代码到 GitHub..."
    git push -u origin main --force || {
        log_error "推送失败"
        exit 1
    }

    log_success "代码已推送到 GitHub"

    # 设置全局变量供后续使用
    export GITHUB_REPO_NAME="$REPO_NAME"
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

# 部署到 Cloudflare Pages
deploy_cloudflare_pages() {
    log_info "部署到 Cloudflare Pages..."

    cd "$BLOG_DIR"

    # 检查 Cloudflare 认证
    cloudflare_auth

    echo -n "请输入 Cloudflare Pages 项目名称: "
    read CF_PROJECT_NAME < /dev/tty

    # 提交所有更改
    log_info "提交更改到Git..."
    git add .
    git commit -m "准备部署到Cloudflare Pages" || log_warning "没有新的更改需要提交"

    # 构建博客
    if [ -f "Makefile" ]; then
        make build
    else
        zola build
    fi

    # 创建 Cloudflare Pages 项目
    log_info "创建 Cloudflare Pages 项目..."
    # 使用 main 作为生产分支
    PRODUCTION_BRANCH="main"
    if wrangler pages project create "$CF_PROJECT_NAME" --production-branch="$PRODUCTION_BRANCH"; then
        log_success "项目创建成功 (生产分支: $PRODUCTION_BRANCH)"
    else
        log_warning "项目可能已存在，继续部署..."
    fi


    # 获取Cloudflare账户ID
    log_info "获取Cloudflare账户信息..."
    ACCOUNT_ID=$(wrangler whoami | grep -o '[a-f0-9]\{32\}' | head -1 || echo "")

    if [ -z "$ACCOUNT_ID" ]; then
        log_error "无法获取Cloudflare账户ID"
        return 1
    fi
    
    log_success "账户ID: $ACCOUNT_ID"

    # 获取GitHub用户名和仓库名
    GITHUB_USER=$(gh api user --jq .login)
    GITHUB_REPO="${GITHUB_REPO_NAME:-$(basename "$BLOG_DIR")}"

    # 启用GitHub Actions（fork的仓库默认禁用）
    log_info "启用GitHub Actions..."

    # 步骤1: 启用 Actions 权限
    if gh api -X PUT "repos/$GITHUB_USER/$GITHUB_REPO/actions/permissions" \
        -f enabled=true \
        -f allowed_actions=all 2>/dev/null; then
        log_success "GitHub Actions 权限已启用"
    else
        log_warning "无法自动启用 GitHub Actions 权限"
    fi

    # 步骤2: 对于 fork 仓库，需要额外启用 workflows
    # 检查是否是 fork
    IS_FORK=$(gh api "repos/$GITHUB_USER/$GITHUB_REPO" --jq .fork 2>/dev/null || echo "false")
    if [ "$IS_FORK" = "true" ]; then
        log_warning "检测到 fork 仓库，workflows 默认禁用"
        echo ""
        echo "⚠️  重要: Fork 仓库的 workflows 需要手动启用"
        echo ""
        echo "请按以下步骤操作:"
        echo "1. 浏览器会自动打开 Actions 页面"
        echo "2. 点击绿色按钮: 'I understand my workflows, go ahead and enable them'"
        echo "3. 完成后回到终端按回车继续"
        echo ""
        echo -n "按回车打开 Actions 页面..."
        read < /dev/tty

        # 打开浏览器
        open "https://github.com/$GITHUB_USER/$GITHUB_REPO/actions" 2>/dev/null || \
        xdg-open "https://github.com/$GITHUB_USER/$GITHUB_REPO/actions" 2>/dev/null || \
        echo "请手动访问: https://github.com/$GITHUB_USER/$GITHUB_REPO/actions"

        echo ""
        echo -n "启用 workflows 后按回车继续..."
        read < /dev/tty

        log_success "Workflows 已启用"

    # 设置GitHub Secrets
    log_info "设置GitHub Secrets..."
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 需要 Cloudflare API Token 用于 GitHub Actions 自动部署"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "请按照以下步骤操作："
    echo ""
    echo "1️⃣  访问 Cloudflare API Tokens 页面"
    echo "   https://dash.cloudflare.com/profile/api-tokens"
    echo ""
    echo "2️⃣  点击 'Create Token' 按钮"
    echo ""
    echo "3️⃣  选择 'Create Custom Token'"
    echo ""
    echo "4️⃣  配置权限："
    echo "   - Account > Cloudflare Pages > Edit"
    echo ""
    echo "5️⃣  创建并复制 Token"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -n "请粘贴你的 Cloudflare API Token: "
    read -s CF_API_TOKEN < /dev/tty
    echo ""
    echo ""
    
    if [ -z "$CF_API_TOKEN" ]; then
        log_warning "未提供 API Token，跳过自动设置"
        echo ""
        echo "请稍后手动在 GitHub 仓库设置中添加以下 secrets:"
        echo "  - CLOUDFLARE_API_TOKEN"
        echo "  - CLOUDFLARE_ACCOUNT_ID: $ACCOUNT_ID"
        echo ""
        echo "访问: https://github.com/$GITHUB_USER/$GITHUB_REPO/settings/secrets/actions"
        echo ""
    else
        # 设置 CLOUDFLARE_API_TOKEN
        log_info "设置 CLOUDFLARE_API_TOKEN..."
        if echo "$CF_API_TOKEN" | gh secret set CLOUDFLARE_API_TOKEN --repo="$GITHUB_USER/$GITHUB_REPO"; then
            log_success "✓ CLOUDFLARE_API_TOKEN 已设置"
        else
            log_error "设置 CLOUDFLARE_API_TOKEN 失败"
            echo "请手动设置: https://github.com/$GITHUB_USER/$GITHUB_REPO/settings/secrets/actions"
        fi
        
        # 设置 CLOUDFLARE_ACCOUNT_ID
        log_info "设置 CLOUDFLARE_ACCOUNT_ID..."
        if echo "$ACCOUNT_ID" | gh secret set CLOUDFLARE_ACCOUNT_ID --repo="$GITHUB_USER/$GITHUB_REPO"; then
            log_success "✓ CLOUDFLARE_ACCOUNT_ID 已设置"
        else
            log_error "设置 CLOUDFLARE_ACCOUNT_ID 失败"
            echo "请手动设置: https://github.com/$GITHUB_USER/$GITHUB_REPO/settings/secrets/actions"
        fi
        
        log_success "GitHub Secrets 设置完成"
    fi        
        if echo "$ACCOUNT_ID" | gh secret set CLOUDFLARE_ACCOUNT_ID --repo="$GITHUB_USER/$GITHUB_REPO" 2>/dev/null; then
            log_success "已设置 CLOUDFLARE_ACCOUNT_ID"
        else
            log_warning "无法自动设置 CLOUDFLARE_ACCOUNT_ID，请手动设置"
        fi
    else
        log_warning "跳过 GitHub Secrets 设置"
        echo "请手动在 GitHub 仓库设置中添加以下 secrets:"
        echo "  - CLOUDFLARE_API_TOKEN"
        echo "  - CLOUDFLARE_ACCOUNT_ID"
        echo "访问: https://github.com/$GITHUB_USER/$GITHUB_REPO/settings/secrets/actions"
    fi

    # 更新GitHub Actions workflow文件中的项目名称
    if [ -f ".github/workflows/build.yml" ]; then
        CURRENT_BRANCH=$(git branch --show-current)
        sed -i '' "s/projectName: blog/projectName: $CF_PROJECT_NAME/" .github/workflows/build.yml

        git add .github/workflows/build.yml
        git commit -m "更新GitHub Actions配置为项目: $CF_PROJECT_NAME" || true

        log_success "GitHub Actions配置完成"
        echo ""
        echo "✅ 自动部署已设置！"
        echo "现在每次push到 $CURRENT_BRANCH 分支时，GitHub Actions会自动："
        echo "1. 构建博客"
        echo "2. 部署到Cloudflare Pages"
        echo ""
    else
        log_warning "未找到GitHub Actions配置文件"
    fi

    # 部署
    log_info "部署到 Cloudflare Pages..."

    # 捕获部署输出
    DEPLOY_LOG=$(mktemp)
    if wrangler pages deploy public --project-name="$CF_PROJECT_NAME" 2>&1 | tee "$DEPLOY_LOG"; then
        log_success "博客已部署到 Cloudflare Pages"

        # 获取项目的固定域名（不是临时部署URL）
        log_info "获取项目固定域名..."
        FIXED_DOMAIN=$(wrangler pages project list 2>/dev/null | \
            awk -v proj="$CF_PROJECT_NAME" '$2 == proj {print $4}' | \
            grep '\.pages\.dev' | \
            sed 's/,$//' | \
            head -1)

        if [ -n "$FIXED_DOMAIN" ]; then
            DEPLOY_URL="https://$FIXED_DOMAIN"
            log_success "✅ 固定域名: $DEPLOY_URL"
        else
            # 如果无法获取，使用项目名称构建（通常项目名就是subdomain）
            DEPLOY_URL="https://${CF_PROJECT_NAME}.pages.dev"
            log_warning "使用默认域名: $DEPLOY_URL"
        fi

        # 更新config.toml中的所有URL字段
        log_info "更新config.toml中的所有URL..."
        if [ -f "config.toml" ]; then
            # 检查当前的base_url
            CURRENT_BASE_URL=$(grep '^base_url = ' config.toml | sed 's/base_url = "\(.*\)"/\1/' || echo "")

            # 只有当URL发生变化时才更新
            if [ "$CURRENT_BASE_URL" != "$DEPLOY_URL" ]; then
                # 更新base_url
                sed -i '' "s|^base_url = \".*\"|base_url = \"$DEPLOY_URL\"|" config.toml

                # 更新extra部分的URL（如果存在）
                sed -i '' "s|^prefix_url = \".*\"|prefix_url = \"$DEPLOY_URL\"|" config.toml
                sed -i '' "s|^indieweb_url = \".*\"|indieweb_url = \"$DEPLOY_URL\"|" config.toml

                log_success "已更新所有URL为: $DEPLOY_URL"

                # 提交配置更改
                git add config.toml
                git commit -m "更新所有URL为Cloudflare Pages固定域名: $FIXED_DOMAIN" || log_warning "配置文件未发生变化"
            else
                log_info "URL未发生变化，跳过更新"
            fi
        fi


        if [ -n "$ACCOUNT_ID" ]; then
            DASHBOARD_URL="https://dash.cloudflare.com/${ACCOUNT_ID}/pages/view/${CF_PROJECT_NAME}"
            echo ""
            echo "🎉 部署成功！"
            echo "🌐 固定访问地址: $DEPLOY_URL"
            echo "📊 查看部署详情: $DASHBOARD_URL"
            echo ""
            echo "💡 提示："
            echo "  - 固定域名已设置到 config.toml 的所有URL字段"
            echo "  - 该域名永久有效，不会随部署变化"
            echo "  - 在 Dashboard 中可以查看部署状态和设置"
        else
            echo ""
            echo "🎉 部署成功！"
            echo "🌐 固定访问地址: $DEPLOY_URL"
            echo "📊 请访问 Cloudflare Dashboard 查看部署详情"
            echo "💡 地址: https://dash.cloudflare.com -> Pages -> $CF_PROJECT_NAME"
        fi

        # 清理临时文件
        rm -f "$DEPLOY_LOG"

        # 推送所有更改到远程仓库
        log_info "推送更改到远程仓库..."
        CURRENT_BRANCH=$(git branch --show-current)
        if git push origin "$CURRENT_BRANCH" 2>&1; then
            log_success "已推送到远程仓库"
            echo ""
            echo "📝 提示："
            echo "  - 本地修改后执行: git add . && git commit -m '你的提交信息'"
            echo "  - 推送到远程: git push origin $CURRENT_BRANCH"
            echo "  - GitHub Actions会自动触发部署"
            echo ""
            echo "🔍 查看 GitHub Actions 运行状态:"
            echo "  gh run list --limit 5"
            echo "  或访问: https://github.com/$GITHUB_USER/$GITHUB_REPO/actions"
        else
            log_warning "推送失败"
            echo ""
            echo "可能的原因:"
            echo "  1. 网络连接问题"
            echo "  2. GitHub 认证过期"
            echo "  3. 分支保护规则"
            echo ""
            echo "解决方案:"
            echo "  1. 检查网络连接"
            echo "  2. 刷新 GitHub 认证: gh auth refresh -h github.com -s workflow"
            echo "  3. 手动推送: cd $BLOG_DIR && git push origin $CURRENT_BRANCH"
            echo ""
        fi
    else
        log_error "部署失败，请检查项目名称是否正确"
        rm -f "$DEPLOY_LOG"
    fi
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

    log_info "配置博客..."
    # 由于克隆的是已经初始化完成的仓库，跳过初始化步骤
    # run_initialization
    install_blog_dependencies
    configure_blog

    echo ""
    log_info "创建 GitHub 仓库..."
    echo ""

    # 创建 GitHub 仓库并设置为 origin
    create_github_repo

    echo ""
    log_info "开始自动部署到 Cloudflare Pages..."
    echo ""

    # 自动部署到 Cloudflare Pages
    deploy_cloudflare_pages

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 博客部署完成！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "接下来你可以选择："
    echo "1. 📖 查看使用引导（推荐新手）- 了解如何创建文章、管理内容"
    echo "2. 👀 本地预览博客"
    echo "3. 退出"
    echo ""

    while true; do
        echo -n "请选择操作 (1-3): "
        read choice < /dev/tty
        case $choice in
            1)
                log_info "启动使用引导..."
                if [ -f "./guide-blog-usage.sh" ]; then
                    chmod +x ./guide-blog-usage.sh
                    ./guide-blog-usage.sh
                else
                    log_error "找不到引导脚本 guide-blog-usage.sh"
                fi
                break
                ;;
            2)
                local_preview
                break
                ;;
            3)
                log_success "设置完成，祝你写作愉快！"
                echo ""
                echo "💡 提示："
                echo "  - 随时运行 ./guide-blog-usage.sh 查看使用引导"
                echo "  - 博客目录: $BLOG_DIR"
                echo ""
                break
                ;;
            *)
                log_error "无效选择，请输入 1-3"
                ;;
        esac
    done
}

# 运行主函数
main "$@"
