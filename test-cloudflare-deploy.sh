#!/bin/bash

# Cloudflare Pages 部署测试脚本
# 用于测试获取正确的固定域名逻辑

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

# 测试 Cloudflare Pages 部署和域名获取
test_cloudflare_deploy() {
    log_info "开始测试 Cloudflare Pages 部署流程..."
    
    # 检查必要工具
    if ! command_exists wrangler; then
        log_error "未找到 wrangler，请先安装: npm install -g wrangler"
        exit 1
    fi
    
    if ! command_exists jq; then
        log_warning "未找到 jq，将尝试安装..."
        if command_exists brew; then
            brew install jq
        else
            log_error "请手动安装 jq: brew install jq"
            exit 1
        fi
    fi
    
    # 检查 Cloudflare 认证
    if ! wrangler whoami >/dev/null 2>&1; then
        log_info "需要登录 Cloudflare..."
        wrangler login
    fi
    
    log_success "Cloudflare 已认证"
    
    # 获取账户ID
    log_info "获取 Cloudflare 账户信息..."
    ACCOUNT_ID=$(wrangler whoami | grep -o '[a-f0-9]\{32\}' | head -1 || echo "")
    
    if [ -z "$ACCOUNT_ID" ]; then
        log_error "无法获取 Cloudflare 账户 ID"
        exit 1
    fi
    
    log_success "账户 ID: $ACCOUNT_ID"
    
    # 输入项目名称
    echo ""
    echo -n "请输入要测试的 Cloudflare Pages 项目名称: "
    read CF_PROJECT_NAME < /dev/tty
    
    if [ -z "$CF_PROJECT_NAME" ]; then
        log_error "项目名称不能为空"
        exit 1
    fi
    
    # 获取 API Token（使用 wrangler pages project list 来验证认证）
    log_info "验证 API 访问权限..."

    # 使用 wrangler pages project list 来获取项目列表
    # 这会使用已认证的凭据
    PROJECT_LIST=$(wrangler pages project list 2>/dev/null | grep -w "$CF_PROJECT_NAME" || echo "")

    if [ -n "$PROJECT_LIST" ]; then
        log_success "项目已存在: $CF_PROJECT_NAME"

        # 使用 wrangler 直接获取项目信息（更可靠）
        log_info "获取项目详细信息..."

        # 创建临时文件来捕获输出
        TEMP_OUTPUT=$(mktemp)

        # 使用 wrangler pages deployment list 来获取部署信息
        # 从中可以提取项目的 pages.dev 域名
        wrangler pages deployment list --project-name="$CF_PROJECT_NAME" 2>/dev/null | head -20 > "$TEMP_OUTPUT" || true

        # 从输出中提取 .pages.dev 域名
        SUBDOMAIN=$(grep -o "${CF_PROJECT_NAME}[^[:space:]]*\.pages\.dev" "$TEMP_OUTPUT" | sed 's/\.pages\.dev$//' | head -1 || echo "$CF_PROJECT_NAME")

        rm -f "$TEMP_OUTPUT"
        
        if [ -n "$SUBDOMAIN" ] && [ "$SUBDOMAIN" != "null" ]; then
            FIXED_DOMAIN="https://${SUBDOMAIN}.pages.dev"
            log_success "✅ 找到固定域名: $FIXED_DOMAIN"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📌 项目信息"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "项目名称: $CF_PROJECT_NAME"
            echo "固定域名: $FIXED_DOMAIN"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
        else
            log_error "无法获取项目的固定域名"
            exit 1
        fi
    else
        log_warning "项目不存在，将创建新项目..."
        
        # 创建项目
        log_info "创建 Cloudflare Pages 项目..."
        if wrangler pages project create "$CF_PROJECT_NAME" --production-branch="main"; then
            log_success "项目创建成功"
            
            # 等待项目创建完成
            sleep 2
            
            # 获取新创建项目的固定域名
            log_info "获取新项目的固定域名..."

            # 新创建的项目，subdomain 就是项目名称
            # Cloudflare Pages 的 subdomain 格式是：项目名.pages.dev
            # 如果项目名重复，会自动添加随机后缀
            SUBDOMAIN="$CF_PROJECT_NAME"
            
            if [ -n "$SUBDOMAIN" ] && [ "$SUBDOMAIN" != "null" ]; then
                FIXED_DOMAIN="https://${SUBDOMAIN}.pages.dev"
                log_success "✅ 新项目固定域名: $FIXED_DOMAIN"
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "📌 新项目信息"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "项目名称: $CF_PROJECT_NAME"
                echo "固定域名: $FIXED_DOMAIN"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
            else
                log_error "无法获取新项目的固定域名"
                exit 1
            fi
        else
            log_error "项目创建失败"
            exit 1
        fi
    fi
    
    # 测试部署（如果有 public 目录）
    if [ -d "public" ]; then
        echo ""
        echo -n "是否要测试部署到 $CF_PROJECT_NAME? (y/n): "
        read DEPLOY_CONFIRM < /dev/tty
        
        if [ "$DEPLOY_CONFIRM" = "y" ] || [ "$DEPLOY_CONFIRM" = "Y" ]; then
            log_info "开始部署..."
            
            # 捕获部署输出
            DEPLOY_LOG=$(mktemp)
            if wrangler pages deploy public --project-name="$CF_PROJECT_NAME" 2>&1 | tee "$DEPLOY_LOG"; then
                log_success "部署成功"
                
                # 从部署输出中提取临时 URL（用于对比）
                TEMP_URL=$(grep -o 'https://[^[:space:]]*\.pages\.dev' "$DEPLOY_LOG" | tail -1 || echo "")
                
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "🎉 部署完成"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "固定域名（应该使用这个）: $FIXED_DOMAIN"
                if [ -n "$TEMP_URL" ]; then
                    echo "临时部署 URL（不要使用）: $TEMP_URL"
                fi
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "💡 提示："
                echo "  - 固定域名永远不变，应该用于 config.toml 的 base_url"
                echo "  - 临时 URL 每次部署都会变化，不应该使用"
                echo ""
                
                # 清理临时文件
                rm -f "$DEPLOY_LOG"
            else
                log_error "部署失败"
                rm -f "$DEPLOY_LOG"
                exit 1
            fi
        else
            log_info "跳过部署测试"
        fi
    else
        log_warning "未找到 public 目录，跳过部署测试"
        echo ""
        echo "💡 提示："
        echo "  - 固定域名: $FIXED_DOMAIN"
        echo "  - 这个域名应该用于 config.toml 的 base_url"
        echo ""
    fi
    
    log_success "测试完成！"
}

# 运行测试
test_cloudflare_deploy

