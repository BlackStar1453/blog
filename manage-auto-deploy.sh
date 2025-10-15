#!/bin/bash

# 管理自动部署定时任务的脚本
# 支持安装、启动、停止、卸载定时任务
# 作者: AI Assistant
# 版本: 1.0.0

set -e

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 定时任务配置
PLIST_NAME="com.blog.auto-deploy"
PLIST_FILE="${HOME}/Library/LaunchAgents/${PLIST_NAME}.plist"
AUTO_DEPLOY_SCRIPT="${SCRIPT_DIR}/auto-deploy.sh"
LOG_DIR="${HOME}/.blog-auto-deploy"
LOG_FILE="${LOG_DIR}/auto-deploy.log"
ERROR_LOG="${LOG_DIR}/error.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 输出函数
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 显示帮助信息
show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 自动部署定时任务管理脚本
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

使用方法: $0 <命令> [选项]

命令:
  install [小时] [分钟]  - 安装定时任务（默认每天 9:00）
  install-boot           - 安装开机自动运行任务
  install-both [小时] [分钟] - 安装开机 + 定时任务（默认每天 14:30）
  uninstall              - 卸载定时任务
  start                  - 启动定时任务
  stop                   - 停止定时任务
  status                 - 查看任务状态
  logs                   - 查看运行日志
  test                   - 测试运行一次（不等待定时）
  help                   - 显示此帮助信息

示例:
  $0 install             # 安装定时任务，每天 9:00 执行
  $0 install 14 30       # 安装定时任务，每天 14:30 执行
  $0 install-boot        # 安装开机自动运行任务
  $0 install-both        # 安装开机 + 定时任务（每天 14:30）
  $0 install-both 16 0   # 安装开机 + 定时任务（每天 16:00）
  $0 status              # 查看任务状态
  $0 logs                # 查看运行日志
  $0 test                # 立即测试运行一次

说明:
  - 定时任务会自动检查修改、提交并部署到 Cloudflare Pages
  - 开机任务会在每次开机后自动运行一次
  - 开机 + 定时任务会在开机后和每天指定时间运行
  - 日志文件位置: ${LOG_FILE}
  - 错误日志位置: ${ERROR_LOG}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    if [ ! -f "${AUTO_DEPLOY_SCRIPT}" ]; then
        print_error "未找到 auto-deploy.sh 脚本: ${AUTO_DEPLOY_SCRIPT}"
        return 1
    fi
    
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    if ! command -v wrangler >/dev/null 2>&1; then
        missing_deps+=("wrangler")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "缺少以下依赖: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# 创建日志目录
create_log_dir() {
    if [ ! -d "${LOG_DIR}" ]; then
        mkdir -p "${LOG_DIR}"
        print_success "创建日志目录: ${LOG_DIR}"
    fi
}

# 生成 plist 文件（定时任务）
generate_plist() {
    local hour="${1:-9}"  # 默认上午9点
    local minute="${2:-0}" # 默认0分

    print_info "生成 plist 配置文件（定时任务）..."

    # 确保 LaunchAgents 目录存在
    mkdir -p "${HOME}/Library/LaunchAgents"

    cat > "${PLIST_FILE}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${AUTO_DEPLOY_SCRIPT}</string>
        <string>Auto deploy: \$(date +%Y-%m-%d\ %H:%M:%S)</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>${hour}</integer>
        <key>Minute</key>
        <integer>${minute}</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>${LOG_FILE}</string>

    <key>StandardErrorPath</key>
    <string>${ERROR_LOG}</string>

    <key>WorkingDirectory</key>
    <string>${SCRIPT_DIR}</string>

    <key>RunAtLoad</key>
    <false/>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
EOF

    print_success "plist 文件已生成: ${PLIST_FILE}"
}

# 生成 plist 文件（开机自动运行）
generate_plist_boot() {
    print_info "生成 plist 配置文件（开机自动运行）..."

    # 确保 LaunchAgents 目录存在
    mkdir -p "${HOME}/Library/LaunchAgents"

    cat > "${PLIST_FILE}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${AUTO_DEPLOY_SCRIPT}</string>
        <string>Auto deploy on boot: \$(date +%Y-%m-%d\ %H:%M:%S)</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>${LOG_FILE}</string>

    <key>StandardErrorPath</key>
    <string>${ERROR_LOG}</string>

    <key>WorkingDirectory</key>
    <string>${SCRIPT_DIR}</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
EOF

    print_success "plist 文件已生成: ${PLIST_FILE}"
}

# 生成 plist 文件（开机 + 定时）
generate_plist_both() {
    local hour="${1:-14}"  # 默认下午2点
    local minute="${2:-30}" # 默认30分

    print_info "生成 plist 配置文件（开机 + 定时任务）..."

    # 确保 LaunchAgents 目录存在
    mkdir -p "${HOME}/Library/LaunchAgents"

    cat > "${PLIST_FILE}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${AUTO_DEPLOY_SCRIPT}</string>
        <string>Auto deploy: \$(date +%Y-%m-%d\ %H:%M:%S)</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>${hour}</integer>
        <key>Minute</key>
        <integer>${minute}</integer>
    </dict>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>${LOG_FILE}</string>

    <key>StandardErrorPath</key>
    <string>${ERROR_LOG}</string>

    <key>WorkingDirectory</key>
    <string>${SCRIPT_DIR}</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
EOF

    print_success "plist 文件已生成: ${PLIST_FILE}"
    print_info "任务将在以下时间运行："
    print_info "  1. 每次开机后"
    print_info "  2. 每天 ${hour}:${minute}"
}

# 安装定时任务
install_task() {
    local hour="${1:-9}"
    local minute="${2:-0}"

    print_info "安装自动部署定时任务..."

    # 检查依赖
    if ! check_dependencies; then
        print_error "依赖检查失败"
        return 1
    fi

    # 创建日志目录
    create_log_dir

    # 如果任务已存在，先卸载
    if is_task_loaded; then
        print_warning "任务已存在，先卸载旧任务..."
        unload_task
    fi

    # 生成 plist 文件
    generate_plist "${hour}" "${minute}"

    # 确保脚本可执行
    chmod +x "${AUTO_DEPLOY_SCRIPT}"

    # 加载任务
    if launchctl load "${PLIST_FILE}"; then
        print_success "定时任务安装成功"
        print_info "任务将在每天 ${hour}:$(printf "%02d" ${minute}) 执行"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📋 任务信息"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⏰ 执行时间: 每天 ${hour}:$(printf "%02d" ${minute})"
        echo "📝 日志文件: ${LOG_FILE}"
        echo "❌ 错误日志: ${ERROR_LOG}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "💡 提示:"
        echo "  - 查看状态: $0 status"
        echo "  - 查看日志: $0 logs"
        echo "  - 测试运行: $0 test"
        echo ""
        return 0
    else
        print_error "定时任务安装失败"
        return 1
    fi
}

# 安装开机自动运行任务
install_boot_task() {
    print_info "安装开机自动运行任务..."

    # 检查依赖
    if ! check_dependencies; then
        print_error "依赖检查失败"
        return 1
    fi

    # 创建日志目录
    create_log_dir

    # 如果任务已存在，先卸载
    if is_task_loaded; then
        print_warning "任务已存在，先卸载旧任务..."
        unload_task
    fi

    # 生成 plist 文件（开机自动运行）
    generate_plist_boot

    # 确保脚本可执行
    chmod +x "${AUTO_DEPLOY_SCRIPT}"

    # 加载任务
    if launchctl load "${PLIST_FILE}"; then
        print_success "开机自动运行任务安装成功"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📋 任务信息"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⏰ 执行时间: 每次开机后自动运行"
        echo "📝 日志文件: ${LOG_FILE}"
        echo "❌ 错误日志: ${ERROR_LOG}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "💡 提示:"
        echo "  - 查看状态: $0 status"
        echo "  - 查看日志: $0 logs"
        echo "  - 测试运行: $0 test"
        echo ""
        echo "⚠️  注意: 任务会在每次开机后自动运行一次"
        echo "   如果没有修改，脚本会自动跳过部署"
        echo ""
        return 0
    else
        print_error "开机自动运行任务安装失败"
        return 1
    fi
}

# 安装开机 + 定时任务
install_both_task() {
    local hour="${1:-14}"
    local minute="${2:-30}"

    print_info "安装开机 + 定时自动部署任务..."

    # 创建日志目录
    create_log_dir

    # 如果任务已存在，先卸载
    if is_task_loaded; then
        print_warning "任务已存在，先卸载旧任务..."
        unload_task
    fi

    # 生成 plist 文件（开机 + 定时）
    generate_plist_both "${hour}" "${minute}"

    # 确保脚本可执行
    chmod +x "${AUTO_DEPLOY_SCRIPT}"

    # 加载任务
    if launchctl load "${PLIST_FILE}"; then
        print_success "开机 + 定时任务安装成功！"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "✅ 自动部署任务已启用（开机 + 定时）"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "📋 任务信息:"
        echo "  - 任务名称: ${PLIST_NAME}"
        echo "  - 运行时间: 每次开机后 + 每天 ${hour}:${minute}"
        echo "  - 工作目录: ${SCRIPT_DIR}"
        echo "  - 日志文件: ${LOG_FILE}"
        echo "  - 错误日志: ${ERROR_LOG}"
        echo ""
        echo "📝 常用命令:"
        echo "  - 查看状态: $0 status"
        echo "  - 查看日志: $0 logs"
        echo "  - 测试运行: $0 test"
        echo ""
        echo "⚠️  注意: 任务会在以下时间自动运行："
        echo "   1. 每次开机后"
        echo "   2. 每天 ${hour}:${minute}"
        echo "   如果没有修改，脚本会自动跳过部署"
        echo ""
        return 0
    else
        print_error "开机 + 定时任务安装失败"
        return 1
    fi
}

# 检查任务是否已加载
is_task_loaded() {
    launchctl list | grep -q "${PLIST_NAME}" 2>/dev/null
}

# 卸载任务
unload_task() {
    if is_task_loaded; then
        launchctl unload "${PLIST_FILE}" 2>/dev/null || true
        print_success "任务已卸载"
    fi
}

# 卸载定时任务
uninstall_task() {
    print_info "卸载自动部署定时任务..."
    
    # 卸载任务
    unload_task
    
    # 删除 plist 文件
    if [ -f "${PLIST_FILE}" ]; then
        rm -f "${PLIST_FILE}"
        print_success "已删除 plist 文件"
    fi
    
    print_success "定时任务已完全卸载"
    echo ""
    echo "💡 提示: 日志文件仍保留在 ${LOG_DIR}"
    echo "   如需删除日志，请手动执行: rm -rf ${LOG_DIR}"
}

# 启动任务
start_task() {
    if ! is_task_loaded; then
        print_error "任务未安装，请先运行: $0 install"
        return 1
    fi
    
    print_info "启动定时任务..."
    launchctl start "${PLIST_NAME}"
    print_success "任务已启动"
}

# 停止任务
stop_task() {
    if ! is_task_loaded; then
        print_error "任务未安装"
        return 1
    fi
    
    print_info "停止定时任务..."
    launchctl stop "${PLIST_NAME}"
    print_success "任务已停止"
}

# 查看任务状态
show_status() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 自动部署任务状态"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if is_task_loaded; then
        print_success "任务状态: 已安装并运行"
        
        # 显示任务详情
        if [ -f "${PLIST_FILE}" ]; then
            local hour=$(grep -A1 "<key>Hour</key>" "${PLIST_FILE}" | tail -1 | sed 's/.*<integer>\(.*\)<\/integer>.*/\1/')
            local minute=$(grep -A1 "<key>Minute</key>" "${PLIST_FILE}" | tail -1 | sed 's/.*<integer>\(.*\)<\/integer>.*/\1/')
            echo "⏰ 执行时间: 每天 ${hour}:$(printf "%02d" ${minute})"
        fi
        
        echo "📝 日志文件: ${LOG_FILE}"
        echo "❌ 错误日志: ${ERROR_LOG}"
        
        # 显示最近的日志
        if [ -f "${LOG_FILE}" ]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📋 最近的运行日志（最后 10 行）"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            tail -10 "${LOG_FILE}"
        fi
    else
        print_warning "任务状态: 未安装"
        echo ""
        echo "💡 提示: 运行 '$0 install' 安装定时任务"
    fi
    
    echo ""
}

# 查看日志
show_logs() {
    if [ ! -f "${LOG_FILE}" ]; then
        print_warning "日志文件不存在: ${LOG_FILE}"
        return 1
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 运行日志"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    tail -50 "${LOG_FILE}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 查看完整日志: tail -f ${LOG_FILE}"
    echo "💡 查看错误日志: tail -f ${ERROR_LOG}"
    echo ""
}

# 测试运行
test_run() {
    print_info "测试运行自动部署脚本..."
    echo ""
    
    if [ ! -f "${AUTO_DEPLOY_SCRIPT}" ]; then
        print_error "未找到脚本: ${AUTO_DEPLOY_SCRIPT}"
        return 1
    fi
    
    # 确保脚本可执行
    chmod +x "${AUTO_DEPLOY_SCRIPT}"
    
    # 运行脚本
    "${AUTO_DEPLOY_SCRIPT}" "Test deploy: $(date +%Y-%m-%d\ %H:%M:%S)"
}

# 主函数
main() {
    local command="${1:-help}"

    case "$command" in
        install)
            install_task "${2}" "${3}"
            ;;
        install-boot)
            install_boot_task
            ;;
        install-both)
            install_both_task "${2}" "${3}"
            ;;
        uninstall)
            uninstall_task
            ;;
        start)
            start_task
            ;;
        stop)
            stop_task
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        test)
            test_run
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"

