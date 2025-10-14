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
    TEMPLATE_REPO="moris1999/blog"

    log_info "下载博客模板..."

    # 确定目标目录
    BLOG_DIR="$HOME/blog"
    if [ -d "$BLOG_DIR" ]; then
        log_warning "目录 $BLOG_DIR 已存在，将使用时间戳后缀"
        BLOG_DIR="$HOME/blog_$(date +%Y%m%d_%H%M%S)"
    fi

    # 使用 Git clone（公开仓库无需认证，只需要 git 命令）
    log_info "正在下载模板..."
    git clone "https://github.com/$TEMPLATE_REPO.git" "$BLOG_DIR" || {
        log_error "下载失败，请检查网络连接"
        exit 1
    }

    cd "$BLOG_DIR"

    # 移除模板的 Git 历史并重新初始化为独立仓库
    log_info "初始化本地 Git 仓库..."
    rm -rf .git
    git init

    # 创建教程模板文件
    log_info "创建教程模板文件..."
    cat > "welcome-tutorial-template.md" << 'TUTORIAL_EOF'
+++
title = "🎉 欢迎使用你的新博客！完整使用教程"
date = {CURRENT_DATE}
updated = {CURRENT_DATE}
description = "这是一篇自动生成的教程文章，帮助你快速上手博客的使用。完成教程后可以删除这篇文章。"
[taxonomies]
tags = ["教程", "新手指南"]
categories = ["Tutorial"]
+++

# 🎉 恭喜！你的博客已经成功部署

欢迎来到你的个人博客！这篇文章将手把手教你如何使用这个博客系统，即使你完全没有编程基础也能轻松上手。

## 📍 你现在在哪里？

你现在看到的这个网站就是你的博客！它已经成功部署到了 Cloudflare Pages 上。

- **本地预览地址**：http://127.0.0.1:8000（仅在你的电脑上可见）
- **线上地址**：{BLOG_URL}（全世界都可以访问）

## 🎯 接下来要做什么？

跟随这个教程，你将学会：

1. ✍️ 如何创建你的第一篇文章
2. 🚀 如何发布文章到网站
3. 👀 如何查看部署状态
4. 🎨 如何修改个人信息

---

## 第一步：创建你的第一篇文章 ✍️

### 方法一：使用创建脚本（推荐）

1. **打开终端**（Terminal / 命令行）
   - Mac：按 `Command + 空格`，输入 "Terminal"，回车
   - Windows：按 `Win + R`，输入 "cmd"，回车

2. **进入博客目录**
   \`\`\`bash
   cd {BLOG_DIR}
   \`\`\`

3. **运行创建脚本**
   \`\`\`bash
   ./create-article.sh
   \`\`\`

4. **按提示输入信息**
   - 文章标题：例如 "我的第一篇博客"
   - 文章描述：例如 "这是我的第一篇博客文章"
   - 标签：例如 "生活,随笔"（用逗号分隔）
   - 分类：例如 "Blog"

5. **编辑文章内容**

   脚本会自动创建文件并告诉你文件路径，例如：
   \`\`\`
   ✅ 文章创建成功！
   📄 文件路径: content/blog/我的第一篇博客.md
   \`\`\`

   用任何文本编辑器打开这个文件，在 \`+++\` 下方写入你的文章内容。

### 方法二：手动创建文件

1. 在 \`content/blog/\` 目录下创建一个新的 \`.md\` 文件
2. 文件名可以是中文或英文，例如 \`我的第一篇博客.md\`
3. 复制模板到文件中并编辑

---

## 第二步：本地预览文章 👀

在发布之前，先在本地预览一下效果：

1. **启动本地服务器**
   \`\`\`bash
   cd {BLOG_DIR}
   make serve
   \`\`\`

2. **打开浏览器访问**

   在浏览器中打开：http://127.0.0.1:8000

   你应该能看到刚才创建的文章出现在首页！

3. **实时预览**

   服务器会自动监听文件变化，你修改文章后保存，刷新浏览器就能看到最新效果。

4. **停止服务器**

   在终端按 \`Ctrl + C\` 即可停止服务器。

---

## 第三步：发布文章到网站 🚀

确认文章没问题后，就可以发布到线上了！

1. **运行部署脚本**
   \`\`\`bash
   cd {BLOG_DIR}
   ./deploy-to-cloudflare.sh
   \`\`\`

2. **等待部署完成**

   脚本会自动完成以下步骤：
   - ✅ 获取 Cloudflare Pages 域名
   - ✅ 更新配置文件
   - ✅ 构建网站
   - ✅ 部署到 Cloudflare Pages
   - ✅ 提交代码到 GitHub（触发自动部署）

3. **查看部署结果**

   部署成功后，脚本会显示你的博客地址和部署状态链接。

---

## 第四步：查看部署状态 📊

### 方法一：查看 Cloudflare Pages 部署状态

1. 访问 [Cloudflare Dashboard](https://dash.cloudflare.com)
2. 登录你的账号
3. 点击左侧菜单 "Workers & Pages"
4. 找到你的项目（项目名：{PROJECT_NAME}）
5. 点击进入，查看 "Deployments" 标签页
6. 最新的部署记录会显示状态：
   - 🟡 Building：正在构建
   - 🟢 Success：部署成功
   - 🔴 Failed：部署失败

### 方法二：查看 GitHub Actions 部署状态

1. 访问你的 GitHub 仓库：https://github.com/{GITHUB_USER}/{REPO_NAME}
2. 点击顶部的 "Actions" 标签
3. 查看最新的 workflow 运行状态

---

## 第五步：查看更新后的网站 🎨

部署完成后（通常 1-3 分钟），访问你的博客地址：

**{BLOG_URL}**

你应该能看到：
- ✅ 新创建的文章出现在首页
- ✅ 文章数量和字数统计已更新
- ✅ 归档页面显示所有文章

---

## 🎨 进阶：修改个人信息

想要修改博客的个人信息？编辑 \`config.toml\` 文件：

\`\`\`toml
[extra]
author = "你的名字"           # 修改作者名
email = "your@email.com"      # 修改邮箱
bio = "你的个人简介"          # 修改个人简介
\`\`\`

修改后，重新部署即可生效。

---

## 📝 常用命令速查

\`\`\`bash
# 创建新文章
./create-article.sh

# 本地预览
make serve

# 部署到 Cloudflare Pages
./deploy-to-cloudflare.sh

# 查看使用指南
./guide-blog-usage.sh
\`\`\`

---

## ❓ 常见问题

### Q1: 部署后网站没有更新？

**A:** 等待 1-3 分钟，Cloudflare Pages 和 GitHub Actions 需要时间构建和部署。

### Q2: 如何删除这篇教程文章？

**A:** 删除 \`content/blog/欢迎使用你的新博客-完整使用教程.md\` 文件，然后重新部署即可。

### Q3: 文章中的图片如何添加？

**A:** 将图片放在 \`static/images/\` 目录下，然后在文章中使用：
\`\`\`markdown
![图片描述](/images/your-image.jpg)
\`\`\`

### Q4: 如何修改博客主题颜色？

**A:** 编辑 \`static/site/styles/\` 目录下的 CSS 文件。

### Q5: 忘记 Cloudflare Pages 项目名了？

**A:** 运行 \`./get-pages-domain.sh\` 查看所有项目。

---

## 🎉 恭喜你完成教程！

现在你已经学会了：
- ✅ 创建文章
- ✅ 本地预览
- ✅ 发布到网站
- ✅ 查看部署状态

接下来，开始你的博客之旅吧！

**记得完成教程后删除这篇文章哦！**

---

## 📚 更多资源

- [Zola 官方文档](https://www.getzola.org/documentation/)
- [Markdown 语法指南](https://www.markdownguide.org/)
- [Cloudflare Pages 文档](https://developers.cloudflare.com/pages/)

祝你写作愉快！✨
TUTORIAL_EOF

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

# 部署到 Cloudflare Pages
deploy_cloudflare_pages() {
    log_info "部署到 Cloudflare Pages..."

    cd "$BLOG_DIR"

    # 检查 Cloudflare 认证
    cloudflare_auth

    echo -n "请输入 Cloudflare Pages 项目名称: "
    read CF_PROJECT_NAME < /dev/tty

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
        log_error "部署失败，请检查项目名称是否正确"
        rm -f "$DEPLOY_LOG"
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
