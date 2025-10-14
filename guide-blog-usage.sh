#!/bin/bash

# 博客使用引导脚本 - 实践演示版
# 通过实际操作帮助用户学习如何使用博客系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓ SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠ WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗ ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}$1${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# 等待用户按键继续
wait_for_key() {
    echo -e "\n${YELLOW}按回车键继续下一步...${NC}"
    read -r
}

# 等待用户确认
confirm_action() {
    local prompt="$1"
    echo -e "\n${YELLOW}${prompt} (y/n): ${NC}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         🎯 博客系统实践演示 - 从零到发布 🚀               ║
║                                                           ║
║   通过 5 个实践步骤，学会创建、预览和发布博客文章         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    echo -e "${BOLD}实践步骤概览：${NC}\n"
    echo -e "  ${MAGENTA}步骤 1${NC} - 📝 手动创建示例文章"
    echo -e "  ${MAGENTA}步骤 2${NC} - 🤖 通过脚本创建示例文章"
    echo -e "  ${MAGENTA}步骤 3${NC} - 👀 在本地查看效果"
    echo -e "  ${MAGENTA}步骤 4${NC} - 🚀 部署到 Cloudflare Pages"
    
    wait_for_key
}

# 步骤 1：手动创建示例文章
practice_step1_manual_create() {
    log_step "📝 步骤 1：手动创建示例文章"
    
    echo -e "${BOLD}现在我们来手动创建第一篇博客文章！${NC}\n"
    
    echo -e "${CYAN}文章格式说明：${NC}"
    echo -e "每篇文章都需要包含 ${GREEN}Front Matter${NC}（文章元数据）和正文内容\n"
    
    cat << 'EOF'
Front Matter 示例：
+++
title = "文章标题"
date = 2024-01-15
updated = 2024-01-15
description = "文章简介"
[taxonomies]
tags = ["标签1", "标签2"]
categories = ["Blog"]
+++

# 文章正文

这里是文章的正文内容...
EOF
    
    echo -e "\n${BOLD}现在让我们创建一篇文章：${NC}\n"
    
    if confirm_action "是否创建手动示例文章？"; then
        local article_file="content/blog/manual-first-post.md"
        local current_date=$(date +%Y-%m-%d)
        
        cat > "$article_file" << EOF
+++
title = "我的第一篇手动创建的博客"
date = $current_date
updated = $current_date
description = "这是我手动创建的第一篇博客文章"
[taxonomies]
tags = ["开始", "手动创建"]
categories = ["Blog"]
+++

# 我的第一篇手动创建的博客

今天我学会了如何手动创建博客文章！

## 创建步骤

1. 在 \`content/blog/\` 目录下创建 .md 文件
2. 添加 Front Matter 元数据
3. 编写文章正文
4. 保存文件

## 感想

手动创建文章让我更好地理解了博客的文件结构和格式要求。

虽然需要手动编写 Front Matter，但这样可以完全掌控文章的每个细节。

## 下一步

接下来我将学习如何使用脚本自动创建文章，这样会更加高效！
EOF
        
        log_success "文章已创建：${GREEN}$article_file${NC}"
        echo ""
        echo -e "${BOLD}文章内容预览：${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        cat "$article_file"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        log_info "跳过手动创建文章"
    fi
    
    wait_for_key
}

# 步骤 2：通过脚本创建示例文章
practice_step2_script_create() {
    log_step "🤖 步骤 2：通过脚本创建示例文章"

    echo -e "${BOLD}手动创建文章虽然灵活，但重复工作较多。${NC}"
    echo -e "${BOLD}我们已经为你准备好了一个脚本来自动化这个过程！${NC}\n"

    if [ -f "./create-article.sh" ]; then
        log_success "找到文章创建脚本：${GREEN}./create-article.sh${NC}"
        echo ""

        if confirm_action "是否现在使用脚本创建一篇文章？"; then
            echo -e "\n${CYAN}请按照提示输入文章信息：${NC}\n"
            echo -e "${YELLOW}提示：可以输入以下示例内容${NC}"
            echo -e "  标题: 使用脚本创建博客真方便"
            echo -e "  描述: 学会使用脚本后，创建文章变得非常简单"
            echo -e "  标签: 脚本,自动化,效率"
            echo -e "  分类: Blog\n"

            ./create-article.sh
        else
            log_info "稍后可以运行 ./create-article.sh 来创建文章"
        fi
    else
        log_warning "未找到 create-article.sh 脚本"
        log_info "请确保脚本在当前目录中"
    fi

    wait_for_key
}

# 步骤 3：在本地查看效果
practice_step3_local_preview() {
    log_step "👀 步骤 3：在本地查看效果"
    
    echo -e "${BOLD}现在我们已经创建了一些文章，让我们在本地预览博客效果！${NC}\n"
    
    echo -e "${CYAN}本地预览的好处：${NC}"
    echo -e "  ✓ 在发布前查看文章效果"
    echo -e "  ✓ 实时预览修改结果"
    echo -e "  ✓ 检查格式和排版"
    echo -e "  ✓ 确保一切正常后再发布\n"
    
    echo -e "${BOLD}启动预览服务器：${NC}"
    echo -e "  ${GREEN}make serve${NC}\n"
    
    echo -e "${BOLD}访问地址：${NC}"
    echo -e "  ${CYAN}http://localhost:8000${NC}\n"
    
    echo -e "${YELLOW}提示：${NC}"
    echo -e "  - 预览服务器会自动监听文件变化"
    echo -e "  - 修改文章后，浏览器会自动刷新"
    echo -e "  - 按 ${RED}Ctrl+C${NC} 停止预览服务器\n"
    
    if confirm_action "是否现在启动预览服务器？"; then
        log_info "正在启动预览服务器..."
        log_info "服务器将在 http://localhost:8000 运行"
        log_info "按 Ctrl+C 停止服务器并继续下一步"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        make serve || true
        
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        log_success "预览服务器已停止"
    else
        log_info "跳过预览，稍后可以运行 'make serve' 来预览"
    fi
    
    wait_for_key
}

# 步骤 4：部署到 Cloudflare Pages
practice_step4_deploy() {
    log_step "🚀 步骤 4：部署到 Cloudflare Pages"

    echo -e "${BOLD}最后一步：将你的文章发布到互联网！${NC}\n"

    echo -e "${CYAN}发布流程：${NC}\n"
    echo -e "  ${MAGENTA}1.${NC} 构建静态网站"
    echo -e "  ${MAGENTA}2.${NC} 部署到 Cloudflare Pages\n"
    
    # 检查是否有未提交的更改
    if [[ -n $(git status -s) ]]; then
        log_info "检测到以下文件变更："
        echo ""
        git status -s
        echo ""

        if confirm_action "是否部署这些更改？"; then
            log_info "使用部署脚本..."
            echo ""

            if [ -f "./deploy-to-cloudflare.sh" ]; then
                ./deploy-to-cloudflare.sh

                echo ""
                echo -e "${GREEN}${BOLD}🎉 部署成功！${NC}\n"

                echo -e "${YELLOW}提示：${NC}"
                echo -e "  - 部署通常需要 1-2 分钟"
                echo -e "  - 稍后刷新网站即可看到新文章\n"
            else
                log_error "未找到部署脚本 deploy-to-cloudflare.sh"
                echo ""
                echo "手动部署步骤："
                echo "  1. make build"
                echo "  2. wrangler pages deploy public --project-name=YOUR_PROJECT_NAME"
            fi
        else
            log_info "跳过部署"
        fi
    else
        log_info "没有检测到文件变更"
        echo -e "${YELLOW}提示：创建或修改文章后再运行此步骤${NC}"
    fi
    
    wait_for_key
}

# 显示完成总结
show_completion() {
    log_step "🎉 完成！"
    
    echo -e "${GREEN}${BOLD}恭喜！你已经完成了博客系统的实践演示！${NC}\n"
    
    echo -e "${CYAN}你学会了：${NC}\n"
    echo -e "  ✅ 手动创建博客文章"
    echo -e "  ✅ 使用脚本自动创建文章"
    echo -e "  ✅ 在本地预览博客效果"
    echo -e "  ✅ 部署到 Cloudflare Pages\n"
    
    echo -e "${CYAN}常用命令速查：${NC}\n"
    cat << EOF
${GREEN}./create-article.sh${NC}         - 使用脚本创建新文章
${GREEN}make serve${NC}                  - 启动本地预览服务器
${GREEN}./deploy-to-cloudflare.sh${NC}  - 部署到 Cloudflare Pages

EOF
    
    echo -e "${CYAN}有用的资源：${NC}\n"
    echo -e "  📖 Markdown 语法：https://www.markdownguide.org/"
    echo -e "  📖 Zola 文档：https://www.getzola.org/documentation/"
    echo -e "  📖 Cloudflare Pages：https://pages.cloudflare.com/\n"

    echo -e "${YELLOW}下一步建议：${NC}\n"
    echo -e "  1. 删除示例文章，创建你的第一篇真实文章"
    echo -e "  2. 自定义 ${CYAN}config.toml${NC} 中的个人信息"
    echo -e "  3. 分享你的博客给朋友们！\n"
    
    echo -e "${GREEN}${BOLD}开始你的博客之旅吧！ 🚀${NC}\n"
    echo -e "${CYAN}${BOLD}感谢使用博客引导！祝你写作愉快！ ✨${NC}\n"
}

# 主函数
main() {
    show_welcome
    practice_step1_manual_create
    practice_step2_script_create
    practice_step3_local_preview
    practice_step4_deploy
    show_completion
}

# 运行主函数
main
