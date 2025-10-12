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
        REPO_NAME=$(basename "$ORIGINAL_REPO")
    else
        log_info "Fork 仓库 $ORIGINAL_REPO..."

        # 检查是否已经fork过
        EXISTING_FORK=$(gh api "repos/$CURRENT_USER/blog" 2>/dev/null | jq -r '.fork' 2>/dev/null || echo "false")

        if [ "$EXISTING_FORK" = "true" ]; then
            log_warning "检测到你已经fork过这个仓库"
            log_info "将直接克隆你的fork仓库..."
            gh repo clone "$CURRENT_USER/blog"
            REPO_NAME="blog"
        else
            # 尝试fork（显示详细错误信息）
            log_info "正在fork仓库..."

            # 临时禁用set -e以捕获错误
            set +e
            FORK_OUTPUT=$(gh repo fork "$ORIGINAL_REPO" --clone --remote --default-branch-only 2>&1)
            FORK_STATUS=$?
            set -e

            echo "DEBUG: Fork status = $FORK_STATUS" >&2
            echo "DEBUG: Fork output = $FORK_OUTPUT" >&2

            if [ $FORK_STATUS -eq 0 ]; then
                REPO_NAME=$(basename "$ORIGINAL_REPO")
                log_success "Fork成功"

                # 进入仓库目录
                cd "$REPO_NAME"

                # 获取当前用户名
                GITHUB_USER=$(gh api user --jq .login)

                # 配置Git remote
                log_info "配置Git远程仓库..."
                # gh repo fork会设置origin为用户的fork，upstream为源仓库
                # 我们需要确保origin指向用户的fork
                git remote set-url origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
                git remote set-url upstream "https://github.com/$ORIGINAL_REPO.git"

                # 获取template-init-v2分支
                log_info "切换到template-init-v2分支..."
                git fetch origin template-init-v2:template-init-v2 2>/dev/null || git fetch upstream template-init-v2:template-init-v2
                git checkout template-init-v2

                # 设置跟踪分支为origin/template-init-v2
                git branch --set-upstream-to=origin/template-init-v2 template-init-v2

                # 设置template-init-v2为默认分支
                log_info "设置template-init-v2为默认分支..."
                gh api -X PATCH "repos/$GITHUB_USER/$REPO_NAME" -f default_branch=template-init-v2 || log_warning "无法设置默认分支"

                # 返回上级目录
                cd ..

                # 重命名GitHub上的fork仓库
                if [ "$REPO_NAME" != "$BLOG_NAME" ]; then
                    log_info "重命名GitHub仓库为: $BLOG_NAME..."
                    gh repo rename "$BLOG_NAME" --yes --repo="$GITHUB_USER/$REPO_NAME" || log_warning "仓库重命名失败，将继续使用原名称"

                    # 更新remote URL为新名称
                    cd "$REPO_NAME"
                    git remote set-url origin "https://github.com/$GITHUB_USER/$BLOG_NAME.git"
                    cd ..

                    REPO_NAME="$BLOG_NAME"
                fi
            else
                log_error "Fork失败！"
                echo ""
                echo "错误信息:"
                echo "$FORK_OUTPUT"
                echo ""
                echo "可能的原因："
                echo "  1. 你已经fork过这个仓库（请检查 https://github.com/$CURRENT_USER/blog）"
                echo "  2. 仓库禁用了fork功能"
                echo "  3. GitHub API速率限制"
                echo ""
                echo "建议："
                echo "  - 如果已有fork，请先删除旧的fork仓库"
                echo "  - 或者直接克隆你的fork: gh repo clone $CURRENT_USER/blog"
                echo ""
                echo "按回车键退出..."
                read < /dev/tty
                exit 1
            fi
        fi
    fi

    # 重命名本地文件夹
    if [ "$REPO_NAME" != "$BLOG_NAME" ]; then
        mv "$REPO_NAME" "$BLOG_NAME" 2>/dev/null || true
    fi

    # 移动到用户指定的位置
    TARGET_DIR="$HOME/$BLOG_NAME"
    if [ -d "$TARGET_DIR" ]; then
        log_warning "目录 $TARGET_DIR 已存在，将使用时间戳后缀"
        TARGET_DIR="$HOME/${BLOG_NAME}_$(date +%Y%m%d_%H%M%S)"
    fi

    mv "$BLOG_NAME" "$TARGET_DIR" 2>/dev/null || mv "$REPO_NAME" "$TARGET_DIR"
    cd "$TARGET_DIR"

    # 设置全局变量供后续函数使用
    export BLOG_DIR="$TARGET_DIR"
    export GITHUB_REPO_NAME="$BLOG_NAME"

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
    if wrangler pages project create "$CF_PROJECT_NAME" --production-branch=template-init-v2; then
        log_success "项目创建成功"
    else
        log_warning "项目可能已存在，继续部署..."
    fi

    # 设置GitHub Actions自动部署
    log_info "设置GitHub Actions自动部署..."

    # 获取Cloudflare账户ID
    ACCOUNT_ID=$(wrangler whoami | grep -o '[a-f0-9]\{32\}' | head -1 || echo "")

    if [ -z "$ACCOUNT_ID" ]; then
        log_error "无法获取Cloudflare账户ID"
        return 1
    fi

    # 获取API Token
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 需要创建Cloudflare API Token用于GitHub Actions自动部署"
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
    echo "4️⃣  输入令牌名称（例如：'GitHub Actions Deploy'）"
    echo ""
    echo "5️⃣  配置权限："
    echo "   在 'Permissions' 部分："
    echo "   - 选择 'Account'"
    echo "   - 选择 'Cloudflare Pages'"
    echo "   - 选择 'Edit'"
    echo ""
    echo "6️⃣  配置账户资源："
    echo "   在 'Account Resources' 部分："
    echo "   - 选择 'Include'"
    echo "   - 选择 'All accounts'（或选择特定账户）"
    echo ""
    echo "7️⃣  点击页面底部的 'Continue to summary' 按钮"
    echo ""
    echo "8️⃣  确认信息后，点击 'Create Token' 按钮"
    echo ""
    echo "9️⃣  ⚠️  重要：复制显示的Token（只会显示一次！）"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -n "请粘贴你的Cloudflare API Token: "
    read -s CF_API_TOKEN < /dev/tty
    echo ""
    echo ""

    if [ -z "$CF_API_TOKEN" ]; then
        log_error "未提供API Token，无法设置GitHub Actions"
        return 1
    fi

    # 保存到.env文件
    log_info "保存环境变量到.env文件..."
    cd "$BLOG_DIR"

    # 创建或更新.env文件
    cat > .env << EOF
# Cloudflare配置
CLOUDFLARE_API_TOKEN=$CF_API_TOKEN
CLOUDFLARE_ACCOUNT_ID=$ACCOUNT_ID

# 项目配置
CLOUDFLARE_PROJECT_NAME=$CF_PROJECT_NAME
EOF

    # 确保.env在.gitignore中
    if ! grep -q "^\.env$" .gitignore 2>/dev/null; then
        echo ".env" >> .gitignore
        log_info "已将.env添加到.gitignore"
    fi

    log_success "环境变量已保存到.env文件"

    # 获取GitHub用户名和仓库名
    GITHUB_USER=$(gh api user --jq .login)
    GITHUB_REPO="${GITHUB_REPO_NAME:-$(basename "$BLOG_DIR")}"

    # 启用GitHub Actions（fork的仓库默认禁用）
    log_info "启用GitHub Actions..."
    gh api -X PUT "repos/$GITHUB_USER/$GITHUB_REPO/actions/permissions" \
        -f enabled=true \
        -f allowed_actions=all 2>/dev/null || log_warning "无法启用Actions，可能需要手动启用"

    # 设置GitHub Secrets
    log_info "设置GitHub Secrets..."

    # 设置secrets
    echo "$CF_API_TOKEN" | gh secret set CLOUDFLARE_API_TOKEN --repo="$GITHUB_USER/$GITHUB_REPO"
    echo "$ACCOUNT_ID" | gh secret set CLOUDFLARE_ACCOUNT_ID --repo="$GITHUB_USER/$GITHUB_REPO"

    # 更新GitHub Actions workflow文件中的项目名称
    if [ -f ".github/workflows/build.yml" ]; then
        sed -i '' "s/projectName: blog/projectName: $CF_PROJECT_NAME/" .github/workflows/build.yml
        sed -i '' "s/- main/- template-init-v2/" .github/workflows/build.yml

        git add .github/workflows/build.yml
        git commit -m "更新GitHub Actions配置为项目: $CF_PROJECT_NAME" || true

        log_success "GitHub Actions配置完成"
        echo ""
        echo "✅ 自动部署已设置！"
        echo "现在每次push到template-init-v2分支时，GitHub Actions会自动："
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
