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
    echo -e "  ${MAGENTA}步骤 3${NC} - 📱 演示 Apple 备忘录创建文章"
    echo -e "  ${MAGENTA}步骤 4${NC} - 👀 在本地查看效果"
    echo -e "  ${MAGENTA}步骤 5${NC} - 🚀 一键提交并部署"
    
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
    echo -e "${BOLD}现在我们创建一个脚本来自动化这个过程！${NC}\n"
    
    if confirm_action "是否创建文章生成脚本？"; then
        local script_file="create-article.sh"
        
        cat > "$script_file" << 'EOFSCRIPT'
#!/bin/bash

# 博客文章创建脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}📝 创建新博客文章${NC}\n"

# 获取文章信息
read -p "文章标题: " title
read -p "文章描述: " description
read -p "标签 (用逗号分隔): " tags_input
read -p "分类 (默认: Blog): " category
category=${category:-Blog}

# 处理标签
IFS=',' read -ra tags_array <<< "$tags_input"
tags_formatted=""
for tag in "${tags_array[@]}"; do
    tag=$(echo "$tag" | xargs)  # 去除空格
    tags_formatted+="\"$tag\", "
done
tags_formatted=${tags_formatted%, }  # 移除最后的逗号和空格

# 生成文件名（从标题转换）
filename=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
current_date=$(date +%Y-%m-%d)
article_file="content/blog/${filename}.md"

# 创建文章
cat > "$article_file" << EOF
+++
title = "$title"
date = $current_date
updated = $current_date
description = "$description"
[taxonomies]
tags = [$tags_formatted]
categories = ["$category"]
+++

# $title

在这里开始写你的文章内容...

## 小节标题

文章内容...

EOF

echo -e "\n${GREEN}✓ 文章已创建：${NC}$article_file"
echo -e "${YELLOW}现在可以编辑这个文件来完善你的文章内容${NC}"
EOFSCRIPT
        
        chmod +x "$script_file"
        log_success "脚本已创建：${GREEN}$script_file${NC}"
        echo ""
        
        if confirm_action "是否现在使用脚本创建一篇文章？"; then
            echo -e "\n${CYAN}请按照提示输入文章信息：${NC}\n"
            echo -e "${YELLOW}提示：可以输入以下示例内容${NC}"
            echo -e "  标题: 使用脚本创建博客真方便"
            echo -e "  描述: 学会使用脚本后，创建文章变得非常简单"
            echo -e "  标签: 脚本,自动化,效率"
            echo -e "  分类: Blog\n"
            
            ./"$script_file"
        else
            log_info "稍后可以运行 ./$script_file 来创建文章"
        fi
    else
        log_info "跳过脚本创建"
    fi
    
    wait_for_key
}

# 步骤 3：演示 Apple 备忘录创建文章
practice_step3_notes_demo() {
    log_step "📱 步骤 3：演示 Apple 备忘录创建文章"
    
    echo -e "${BOLD}Apple 备忘录同步是一个强大的功能！${NC}"
    echo -e "${BOLD}你可以在手机或电脑的备忘录中写作，然后自动同步到博客。${NC}\n"
    
    echo -e "${CYAN}如何使用：${NC}\n"
    
    echo -e "${BOLD}1. 在 Apple 备忘录中创建笔记${NC}"
    echo -e "   - 打开备忘录 App"
    echo -e "   - 创建新笔记\n"
    
    echo -e "${BOLD}2. 使用特定标签标记笔记类型${NC}\n"
    echo -e "   ${GREEN}#blog${NC}        - 标记为博客文章"
    echo -e "   ${GREEN}#thought${NC}     - 标记为短想法"
    echo -e "   ${GREEN}#poem${NC}        - 标记为诗歌"
    echo -e "   ${GREEN}#story${NC}       - 标记为故事"
    echo -e "   ${GREEN}#translation${NC} - 标记为翻译\n"
    
    echo -e "${BOLD}3. 添加分类标签（可选）${NC}\n"
    echo -e "   ${GREEN}#journal${NC}     - 日记"
    echo -e "   ${GREEN}#book${NC}        - 读书笔记"
    echo -e "   ${GREEN}#share${NC}       - 分享"
    echo -e "   ${GREEN}#traveling${NC}   - 旅行\n"
    
    echo -e "${YELLOW}示例备忘录：${NC}\n"
    cat << 'EOF'
┌─────────────────────────────────────────┐
│ 今天的思考 #blog #journal               │
├─────────────────────────────────────────┤
│                                         │
│ 今天在咖啡馆写作时，突然意识到...      │
│                                         │
│ ## 关于写作                             │
│                                         │
│ 写作不仅是记录，更是思考的过程。        │
│ 通过文字整理思绪，让想法更加清晰。      │
│                                         │
│ ## 下一步                               │
│                                         │
│ - 坚持每天写作                          │
│ - 多读优秀的文章                        │
│                                         │
└─────────────────────────────────────────┘
EOF
    
    echo -e "\n${BOLD}4. 运行同步脚本${NC}"
    echo -e "   ${CYAN}./scripts/auto-sync-thoughts.sh${NC}  或  ${CYAN}./scripts/auto-sync-thoughts.sh${NC}\n"
    
    log_info "同步后，备忘录会自动转换为博客文章"
    log_info "并保存到对应的目录（如 content/thoughts/）"
    
    echo -e "\n${YELLOW}注意：${NC}"
    echo -e "  - 备忘录同步功能需要额外配置"
    echo -e "  - 如果你还没有配置，可以先使用手动或脚本方式创建文章"
    echo -e "  - 配置方法请参考项目文档\n"
    
    wait_for_key
}

# 步骤 4：在本地查看效果
practice_step4_local_preview() {
    log_step "👀 步骤 4：在本地查看效果"
    
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

# 步骤 5：一键提交并部署
practice_step5_commit_deploy() {
    log_step "🚀 步骤 5：一键提交并部署"
    
    echo -e "${BOLD}最后一步：将你的文章发布到互联网！${NC}\n"
    
    echo -e "${CYAN}发布流程：${NC}\n"
    echo -e "  ${MAGENTA}1.${NC} 构建静态网站"
    echo -e "  ${MAGENTA}2.${NC} 提交更改到 Git"
    echo -e "  ${MAGENTA}3.${NC} 推送到 GitHub"
    echo -e "  ${MAGENTA}4.${NC} 等待自动部署\n"
    
    # 检查是否有未提交的更改
    if [[ -n $(git status -s) ]]; then
        log_info "检测到以下文件变更："
        echo ""
        git status -s
        echo ""
        
        if confirm_action "是否提交这些更改？"; then
            # 构建网站
            log_info "步骤 1/4: 构建静态网站..."
            make build
            log_success "网站构建完成"
            echo ""
            
            # 添加所有更改
            log_info "步骤 2/4: 添加文件到 Git..."
            git add .
            log_success "文件已添加"
            echo ""
            
            # 提交更改
            echo -e "${YELLOW}请输入提交信息（描述你的更改）：${NC}"
            read -p "> " commit_message
            commit_message=${commit_message:-"添加新文章"}
            
            git commit -m "$commit_message"
            log_success "更改已提交"
            echo ""
            
            # 推送到远程
            log_info "步骤 3/4: 推送到 GitHub..."
            if git push origin main; then
                log_success "推送成功！"
                echo ""
                
                # 部署信息
                log_info "步骤 4/4: 等待自动部署..."
                echo ""
                echo -e "${GREEN}${BOLD}🎉 发布成功！${NC}\n"
                
                # 获取用户名
                GITHUB_USER=$(git config user.name || echo "your-username")
                REPO_URL="https://$(git config user.name || echo "your-username").github.io"
                
                echo -e "${CYAN}你的博客地址：${NC}"
                echo -e "  ${BLUE}${BOLD}$REPO_URL${NC}\n"
                
                echo -e "${YELLOW}注意：${NC}"
                echo -e "  - 如果这是第一次部署，需要在 GitHub 仓库设置中启用 Pages"
                echo -e "  - GitHub Pages 部署通常需要 1-2 分钟"
                echo -e "  - 稍后刷新网站即可看到新文章\n"
                
                if confirm_action "是否在浏览器中打开你的博客？"; then
                    open "$REPO_URL" 2>/dev/null || xdg-open "$REPO_URL" 2>/dev/null || log_warning "无法自动打开浏览器，请手动访问：$REPO_URL"
                fi
            else
                log_error "推送失败，请检查网络连接和权限"
            fi
        else
            log_info "跳过提交"
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
    echo -e "  ✅ 了解 Apple 备忘录同步功能"
    echo -e "  ✅ 在本地预览博客效果"
    echo -e "  ✅ 提交更改并部署到互联网\n"
    
    echo -e "${CYAN}常用命令速查：${NC}\n"
    cat << EOF
${GREEN}./create-article.sh${NC}  - 使用脚本创建新文章
${GREEN}make serve${NC}           - 启动本地预览服务器
${GREEN}make build${NC}           - 构建静态网站
${GREEN}git add . && git commit -m "..." && git push${NC} - 提交并推送更改

EOF
    
    echo -e "${CYAN}有用的资源：${NC}\n"
    echo -e "  📖 Markdown 语法：https://www.markdownguide.org/"
    echo -e "  📖 Zola 文档：https://www.getzola.org/documentation/"
    echo -e "  📖 GitHub Pages：https://pages.github.com/\n"
    
    echo -e "${YELLOW}下一步建议：${NC}\n"
    echo -e "  1. 删除示例文章，创建你的第一篇真实文章"
    echo -e "  2. 自定义 ${CYAN}config.toml${NC} 中的个人信息"
    echo -e "  3. 探索更多高级功能（如备忘录同步）"
    echo -e "  4. 分享你的博客给朋友们！\n"
    
    echo -e "${GREEN}${BOLD}开始你的博客之旅吧！ 🚀${NC}\n"
    echo -e "${CYAN}${BOLD}感谢使用博客引导！祝你写作愉快！ ✨${NC}\n"
}

# 主函数
main() {
    show_welcome
    practice_step1_manual_create
    practice_step2_script_create
    practice_step3_notes_demo
    practice_step4_local_preview
    practice_step5_commit_deploy
    show_completion
}

# 运行主函数
main
