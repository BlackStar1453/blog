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

# 下载模板（简单模式 - 使用 Git clone，无需认证，可选择是否保留 Git）
download_template_simple() {
    TEMPLATE_REPO="BlackStar1453/blog"
    TEMPLATE_BRANCH="template"

    log_info "下载博客模板..."

    # 确定目标目录
    BLOG_DIR="$HOME/blog"
    if [ -d "$BLOG_DIR" ]; then
        log_warning "目录 $BLOG_DIR 已存在，将使用时间戳后缀"
        BLOG_DIR="$HOME/blog_$(date +%Y%m%d_%H%M%S)"
    fi

    # 使用 Git clone（公开仓库无需认证，只需要 git 命令）
    log_info "正在下载模板..."
    git clone -b "$TEMPLATE_BRANCH" "https://github.com/$TEMPLATE_REPO.git" "$BLOG_DIR" || {
        log_error "下载失败，请检查网络连接"
        exit 1
    }

    cd "$BLOG_DIR"

    # 移除模板的 Git 历史并重新初始化为独立仓库
    log_info "初始化本地 Git 仓库..."
    rm -rf .git
    git init
    git add .
    git commit -m "初始化博客" || log_warning "Git 提交失败"
    log_success "已初始化本地 Git 仓库（用于版本控制）"

    # 设置全局变量
    export BLOG_DIR
    export GITHUB_REPO_NAME="blog"

    log_success "模板下载完成，位置：$BLOG_DIR"
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
    echo -n "请输入你的个人简介 (bio): "
    read AUTHOR_BIO < /dev/tty

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

        # 4. 替换 [extra] section 中的 email
        sed -i '' '/^\[extra\]/,/^\[/{s|^email = ".*"|email = "'"${AUTHOR_EMAIL}"'"|;}' config.toml

        # 5. 替换 [extra] section 中的 bio
        sed -i '' '/^\[extra\]/,/^\[/{s|^bio = ".*"|bio = "'"${AUTHOR_BIO}"'"|;}' config.toml
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

# 验证项目名称格式
validate_project_name() {
    local name="$1"

    # 检查长度(1-58字符)
    if [ ${#name} -lt 1 ] || [ ${#name} -gt 58 ]; then
        return 1
    fi

    # 检查格式:只允许小写字母、数字和连字符,不能以连字符开头或结尾
    if ! [[ "$name" =~ ^[a-z0-9]([a-z0-9-]{0,56}[a-z0-9])?$ ]]; then
        return 1
    fi

    return 0
}

# 部署到 Cloudflare Pages
deploy_cloudflare_pages() {
    log_info "部署到 Cloudflare Pages..."

    cd "$BLOG_DIR"

    # 检查 Cloudflare 认证
    cloudflare_auth

    # 显示项目名称要求
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 项目名称要求:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • 长度: 1-58 个字符"
    echo "  • 字符: 只能包含小写字母(a-z)、数字(0-9)和连字符(-)"
    echo "  • 限制: 不能以连字符开头或结尾"
    echo "  • 示例: my-blog, blog-2024, personal-website"
    echo ""

    local CF_PROJECT_NAME
    local attempts=0
    local max_attempts=3

    while [ $attempts -lt $max_attempts ]; do
        echo -n "请输入 Cloudflare Pages 项目名称: "
        read input_name < /dev/tty

        if [ -z "$input_name" ]; then
            log_error "项目名称不能为空"
            attempts=$((attempts + 1))
            continue
        fi

        # 自动转换为小写
        CF_PROJECT_NAME=$(echo "$input_name" | tr '[:upper:]' '[:lower:]')

        # 如果转换后与输入不同,提示用户
        if [ "$CF_PROJECT_NAME" != "$input_name" ]; then
            log_info "已自动转换为小写: $CF_PROJECT_NAME"
        fi

        # 验证格式
        if validate_project_name "$CF_PROJECT_NAME"; then
            log_success "✅ 项目名称格式正确: $CF_PROJECT_NAME"
            break
        else
            log_error "❌ 项目名称格式错误"
            echo ""
            echo "错误原因可能是:"
            echo "  • 包含特殊字符(只允许字母、数字和连字符)"
            echo "  • 以连字符开头或结尾"
            echo "  • 长度不在 1-58 字符范围内"
            echo ""
            attempts=$((attempts + 1))

            if [ $attempts -lt $max_attempts ]; then
                echo "请重新输入 ($((max_attempts - attempts)) 次机会剩余)..."
                echo ""
            fi
        fi
    done

    if [ $attempts -eq $max_attempts ]; then
        log_error "超过最大尝试次数,退出"
        exit 1
    fi

    # 提交所有更改（简单模式也需要本地 git 管理）
    log_info "提交更改到本地Git..."
    git add .
    git commit -m "准备部署到Cloudflare Pages" || log_warning "没有新的更改需要提交"

    # 创建 Cloudflare Pages 项目
    log_info "创建 Cloudflare Pages 项目..."
    # 使用 main 作为生产分支
    PRODUCTION_BRANCH="main"
    if wrangler pages project create "$CF_PROJECT_NAME" --production-branch="$PRODUCTION_BRANCH"; then
        log_success "项目创建成功 (生产分支: $PRODUCTION_BRANCH)"
    else
        log_warning "项目可能已存在，继续..."
    fi

    # 获取Cloudflare账户ID
    log_info "获取Cloudflare账户信息..."
    ACCOUNT_ID=$(wrangler whoami | grep -o '[a-f0-9]\{32\}' | head -1 || echo "")

    if [ -z "$ACCOUNT_ID" ]; then
        log_error "无法获取Cloudflare账户ID"
        return 1
    fi

    log_success "账户ID: $ACCOUNT_ID"

    # 获取项目的固定域名（在构建之前）
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
        log_info "使用默认域名: $DEPLOY_URL"
    fi

    # 更新config.toml中的所有URL字段（在构建之前）
    log_info "更新config.toml中的URL..."
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

    # 构建博客（使用更新后的 config.toml）
    log_info "构建博客..."
    if [ -f "Makefile" ]; then
        make build
    else
        zola build
    fi

    # 部署
    log_info "部署到 Cloudflare Pages..."

    # 捕获部署输出
    DEPLOY_LOG=$(mktemp)
    if wrangler pages deploy public --project-name="$CF_PROJECT_NAME" 2>&1 | tee "$DEPLOY_LOG"; then
        log_success "博客已部署到 Cloudflare Pages"

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

        # 提示用户如何更新博客
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📝 如何更新博客内容"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "1️⃣  创建文章："
        echo "   ./create-article.sh"
        echo ""
        echo "2️⃣  本地预览："
        echo "   cd $BLOG_DIR"
        echo "   make serve"
        echo "   # 访问 http://localhost:1111"
        echo ""
        echo "3️⃣  部署更新："
        echo "   ./deploy-to-cloudflare.sh"
        echo ""
        echo "💡 提示："
        echo "   - 每次修改后都需要重新部署"
        echo "   - 部署后访问: $DEPLOY_URL"
        echo ""
    else
        log_error "❌ 部署失败,请检查上方错误信息"
        echo ""
        echo "常见问题:"
        echo "  • 项目名称格式错误(应该已被验证,但可能 Cloudflare 有额外限制)"
        echo "  • 网络连接问题"
        echo "  • Cloudflare 账户权限不足"
        echo "  • public 目录为空或构建失败"
        echo ""
        echo "建议操作:"
        echo "  1. 检查网络连接"
        echo "  2. 确认 Cloudflare 账户已登录: wrangler whoami"
        echo "  3. 检查 public 目录是否存在且有内容: ls -la public/"
        echo "  4. 查看完整错误信息并根据提示操作"
        echo "  5. 如需重新部署,可以运行: ./deploy-to-cloudflare.sh"
        echo ""
        rm -f "$DEPLOY_LOG"
        return 1
    fi
}

# 主函数
main() {
    echo "🚀 博客一键设置脚本"
    echo "===================="
    echo ""

    log_info "开始安装必要工具..."
    install_homebrew
    install_nodejs
    install_cloudflare_cli

    log_info "下载博客模板..."
    download_template_simple

    log_info "配置博客..."
    install_blog_dependencies
    configure_blog

    echo ""
    log_info "开始部署到 Cloudflare Pages..."
    echo ""

    # 部署到 Cloudflare Pages
    deploy_cloudflare_pages

    # 创建欢迎教程文章
    log_info "创建欢迎教程文章..."
    TUTORIAL_FILE="content/blog/欢迎使用你的新博客-完整使用教程.md"
    CURRENT_DATE=$(date +%Y-%m-%d)
    GITHUB_USER=$(git config user.name || echo "your-username")
    REPO_NAME=$(basename "$BLOG_DIR")

    # 复制模板并替换占位符
    if [ -f "welcome-tutorial-template.md" ]; then
        sed -e "s|{CURRENT_DATE}|$CURRENT_DATE|g" \
            -e "s|{BLOG_URL}|$DEPLOY_URL|g" \
            -e "s|{BLOG_DIR}|$BLOG_DIR|g" \
            -e "s|{PROJECT_NAME}|$CF_PROJECT_NAME|g" \
            -e "s|{GITHUB_USER}|$GITHUB_USER|g" \
            -e "s|{REPO_NAME}|$REPO_NAME|g" \
            "welcome-tutorial-template.md" > "$TUTORIAL_FILE"

        log_success "✅ 教程文章已创建: $TUTORIAL_FILE"

        # 重新构建并部署
        log_info "重新构建博客（包含教程文章）..."
        if [ -f "Makefile" ]; then
            make build
        else
            zola build
        fi

        log_info "部署更新..."
        wrangler pages deploy public --project-name="$CF_PROJECT_NAME" > /dev/null 2>&1

        log_success "✅ 教程文章已发布到网站"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 博客部署完成！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📍 你的博客地址: $DEPLOY_URL"
    echo ""
    echo "🎓 我们为你创建了一篇完整的使用教程，现在将自动打开你的博客..."
    echo "   教程文章会在首页显示，跟随教程学习如何使用博客！"
    echo ""
    echo "💡 提示："
    echo "  - 教程会手把手教你创建文章、发布更新"
    echo "  - 完成教程后可以删除教程文章"
    echo "  - 随时运行 ./guide-blog-usage.sh 查看命令行引导"
    echo ""

    # 等待 2 秒让用户看到提示
    sleep 2

    # 自动打开浏览器
    log_info "正在打开浏览器..."
    if command -v open > /dev/null 2>&1; then
        # macOS
        open "$DEPLOY_URL"
    elif command -v xdg-open > /dev/null 2>&1; then
        # Linux
        xdg-open "$DEPLOY_URL"
    elif command -v start > /dev/null 2>&1; then
        # Windows
        start "$DEPLOY_URL"
    else
        log_warning "无法自动打开浏览器，请手动访问: $DEPLOY_URL"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "接下来你可以选择："
    echo "1. 👀 本地预览博客（推荐）- 在本地查看教程文章"
    echo "2. 📖 查看命令行使用引导"
    echo "3. 退出"
    echo ""

    while true; do
        echo -n "请选择操作 (1-3): "
        read choice < /dev/tty
        case $choice in
            1)
                local_preview
                break
                ;;
            2)
                log_info "启动使用引导..."
                if [ -f "./guide-blog-usage.sh" ]; then
                    chmod +x ./guide-blog-usage.sh
                    ./guide-blog-usage.sh
                else
                    log_error "找不到引导脚本 guide-blog-usage.sh"
                fi
                break
                ;;
            3)
                log_success "设置完成，祝你写作愉快！"
                echo ""
                echo "💡 提示："
                echo "  - 访问 $DEPLOY_URL 查看你的博客和教程"
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
