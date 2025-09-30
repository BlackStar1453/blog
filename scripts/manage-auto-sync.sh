#!/bin/bash

# 管理 thought 自动同步定时任务的脚本
# 支持安装、启动、停止、卸载定时任务
# 作者: AI Assistant
# 版本: 1.0.0

set -e

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 定时任务配置
PLIST_NAME="com.blog.thought-sync"
PLIST_FILE="${HOME}/Library/LaunchAgents/${PLIST_NAME}.plist"
AUTO_SYNC_SCRIPT="${SCRIPT_DIR}/auto-sync-thoughts.sh"

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

# 检查依赖
check_dependencies() {
    print_info "检查依赖..."
    
    # 检查自动同步脚本
    if [ ! -f "${AUTO_SYNC_SCRIPT}" ]; then
        print_error "自动同步脚本不存在: ${AUTO_SYNC_SCRIPT}"
        return 1
    fi
    
    # 检查脚本权限
    if [ ! -x "${AUTO_SYNC_SCRIPT}" ]; then
        print_info "设置脚本执行权限..."
        chmod +x "${AUTO_SYNC_SCRIPT}"
    fi
    
    # 检查 LaunchAgents 目录
    if [ ! -d "${HOME}/Library/LaunchAgents" ]; then
        print_info "创建 LaunchAgents 目录..."
        mkdir -p "${HOME}/Library/LaunchAgents"
    fi
    
    print_success "依赖检查通过"
    return 0
}

# 生成 plist 文件
generate_plist() {
    local hour="${1:-9}"  # 默认上午9点
    local minute="${2:-0}" # 默认0分
    
    print_info "生成 plist 配置文件..."
    
    cat > "${PLIST_FILE}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>${AUTO_SYNC_SCRIPT}</string>
    </array>
    
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>${hour}</integer>
        <key>Minute</key>
        <integer>${minute}</integer>
    </dict>
    
    <key>StandardOutPath</key>
    <string>${PROJECT_DIR}/logs/launchd-stdout.log</string>
    
    <key>StandardErrorPath</key>
    <string>${PROJECT_DIR}/logs/launchd-stderr.log</string>
    
    <key>RunAtLoad</key>
    <false/>
    
    <key>KeepAlive</key>
    <false/>
    
    <key>ProcessType</key>
    <string>Background</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin</string>
        <key>HOME</key>
        <string>${HOME}</string>
    </dict>
</dict>
</plist>
EOF
    
    print_success "plist 文件已生成: ${PLIST_FILE}"
}

# 安装定时任务
install_task() {
    local hour="${1:-9}"
    local minute="${2:-0}"
    
    print_info "安装 thought 自动同步定时任务..."
    
    # 检查依赖
    if ! check_dependencies; then
        print_error "依赖检查失败"
        return 1
    fi
    
    # 如果任务已存在，先卸载
    if is_task_loaded; then
        print_warning "任务已存在，先卸载旧任务..."
        unload_task
    fi
    
    # 生成 plist 文件
    generate_plist "${hour}" "${minute}"
    
    # 加载任务
    if launchctl load "${PLIST_FILE}"; then
        print_success "定时任务安装成功"
        print_info "任务将在每天 ${hour}:$(printf "%02d" ${minute}) 执行"
        return 0
    else
        print_error "定时任务安装失败"
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
    print_info "卸载 thought 自动同步定时任务..."
    
    # 卸载任务
    unload_task
    
    # 删除 plist 文件
    if [ -f "${PLIST_FILE}" ]; then
        rm "${PLIST_FILE}"
        print_success "plist 文件已删除"
    fi
    
    print_success "定时任务卸载完成"
}

# 启动任务
start_task() {
    print_info "启动定时任务..."
    
    if ! is_task_loaded; then
        print_error "任务未安装，请先运行 install 命令"
        return 1
    fi
    
    if launchctl start "${PLIST_NAME}"; then
        print_success "任务启动成功"
    else
        print_error "任务启动失败"
        return 1
    fi
}

# 停止任务
stop_task() {
    print_info "停止定时任务..."
    
    if ! is_task_loaded; then
        print_warning "任务未加载"
        return 0
    fi
    
    if launchctl stop "${PLIST_NAME}"; then
        print_success "任务停止成功"
    else
        print_error "任务停止失败"
        return 1
    fi
}

# 查看任务状态
status_task() {
    print_info "检查任务状态..."
    
    if is_task_loaded; then
        print_success "任务已加载"
        
        # 显示任务详细信息
        echo ""
        print_info "任务详细信息:"
        launchctl list | grep "${PLIST_NAME}" || true
        
        # 显示 plist 文件信息
        if [ -f "${PLIST_FILE}" ]; then
            echo ""
            print_info "配置文件: ${PLIST_FILE}"
            
            # 提取执行时间
            local hour=$(grep -A1 "<key>Hour</key>" "${PLIST_FILE}" | grep "<integer>" | sed 's/.*<integer>\([0-9]*\)<\/integer>.*/\1/')
            local minute=$(grep -A1 "<key>Minute</key>" "${PLIST_FILE}" | grep "<integer>" | sed 's/.*<integer>\([0-9]*\)<\/integer>.*/\1/')
            
            if [ -n "$hour" ] && [ -n "$minute" ]; then
                print_info "执行时间: 每天 ${hour}:$(printf "%02d" ${minute})"
            fi
        fi
        
        # 显示日志文件
        echo ""
        print_info "日志文件:"
        echo "  - 标准输出: ${PROJECT_DIR}/logs/launchd-stdout.log"
        echo "  - 标准错误: ${PROJECT_DIR}/logs/launchd-stderr.log"
        echo "  - 同步日志: ${PROJECT_DIR}/logs/auto-sync-thoughts.log"
        
    else
        print_warning "任务未加载"
    fi
}

# 测试任务
test_task() {
    print_info "测试自动同步脚本..."
    
    if [ ! -f "${AUTO_SYNC_SCRIPT}" ]; then
        print_error "自动同步脚本不存在"
        return 1
    fi
    
    # 以测试模式运行脚本
    if "${AUTO_SYNC_SCRIPT}" --test --verbose; then
        print_success "测试通过"
    else
        print_error "测试失败"
        return 1
    fi
}

# 查看日志
view_logs() {
    local log_type="${1:-sync}"
    
    case "$log_type" in
        "sync")
            local log_file="${PROJECT_DIR}/logs/auto-sync-thoughts.log"
            ;;
        "error")
            local log_file="${PROJECT_DIR}/logs/auto-sync-thoughts-error.log"
            ;;
        "stdout")
            local log_file="${PROJECT_DIR}/logs/launchd-stdout.log"
            ;;
        "stderr")
            local log_file="${PROJECT_DIR}/logs/launchd-stderr.log"
            ;;
        *)
            print_error "未知的日志类型: $log_type"
            print_info "可用的日志类型: sync, error, stdout, stderr"
            return 1
            ;;
    esac
    
    if [ -f "$log_file" ]; then
        print_info "显示日志: $log_file"
        echo ""
        tail -n 50 "$log_file"
    else
        print_warning "日志文件不存在: $log_file"
    fi
}

# 显示帮助信息
show_help() {
    echo "thought 自动同步定时任务管理脚本"
    echo ""
    echo "使用方法: $0 <命令> [选项]"
    echo ""
    echo "命令:"
    echo "  install [小时] [分钟]  - 安装定时任务 (默认: 9:00)"
    echo "  uninstall             - 卸载定时任务"
    echo "  start                 - 启动任务"
    echo "  stop                  - 停止任务"
    echo "  status                - 查看任务状态"
    echo "  test                  - 测试同步脚本"
    echo "  logs [类型]           - 查看日志 (sync/error/stdout/stderr)"
    echo "  help                  - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 install            # 安装任务，每天9:00执行"
    echo "  $0 install 14 30      # 安装任务，每天14:30执行"
    echo "  $0 status             # 查看任务状态"
    echo "  $0 logs sync          # 查看同步日志"
    echo "  $0 test               # 测试同步功能"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        "install")
            install_task "$1" "$2"
            ;;
        "uninstall")
            uninstall_task
            ;;
        "start")
            start_task
            ;;
        "stop")
            stop_task
            ;;
        "status")
            status_task
            ;;
        "test")
            test_task
            ;;
        "logs")
            view_logs "$1"
            ;;
        "help"|"-h"|"--help")
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

# 执行主函数
main "$@"
