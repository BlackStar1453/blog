#!/bin/bash

# 自动同步 thought 备忘录的包装脚本
# 用于 launchd 定时任务调用
# 作者: AI Assistant
# 版本: 1.0.0

set -e

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 设置日志文件路径
LOG_DIR="${PROJECT_DIR}/logs"
LOG_FILE="${LOG_DIR}/auto-sync-thoughts.log"
ERROR_LOG="${LOG_DIR}/auto-sync-thoughts-error.log"

# 创建日志目录
mkdir -p "${LOG_DIR}"

# 日志函数
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "${LOG_FILE}" | tee -a "${ERROR_LOG}"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" | tee -a "${LOG_FILE}"
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    # 检查 Python
    if ! command -v python3 >/dev/null 2>&1; then
        log_error "Python3 未安装"
        return 1
    fi
    
    # 检查必要的 Python 库
    if ! python3 -c "import macnotesapp, rich" >/dev/null 2>&1; then
        log_error "缺少必要的 Python 库 (macnotesapp, rich)"
        return 1
    fi
    
    # 检查同步脚本
    if [ ! -f "${PROJECT_DIR}/sync_thought_notes.py" ]; then
        log_error "同步脚本不存在: ${PROJECT_DIR}/sync_thought_notes.py"
        return 1
    fi
    
    # 检查 add-thought.sh 脚本
    if [ ! -f "${SCRIPT_DIR}/add-thought.sh" ]; then
        log_error "add-thought.sh 脚本不存在: ${SCRIPT_DIR}/add-thought.sh"
        return 1
    fi
    
    # 检查 thoughts 文件
    if [ ! -f "${PROJECT_DIR}/content/thoughts/index.md" ]; then
        log_error "thoughts 文件不存在: ${PROJECT_DIR}/content/thoughts/index.md"
        return 1
    fi
    
    log_info "依赖检查通过"
    return 0
}

# 执行同步
run_sync() {
    log_info "开始自动同步 thought 备忘录..."
    
    # 切换到项目目录
    cd "${PROJECT_DIR}"
    
    # 设置环境变量
    export PATH="/usr/local/bin:/usr/bin:/bin:${PATH}"
    export PYTHONPATH="${PROJECT_DIR}:${PYTHONPATH}"
    
    # 执行同步脚本
    if python3 "${PROJECT_DIR}/sync_thought_notes.py" >> "${LOG_FILE}" 2>> "${ERROR_LOG}"; then
        log_success "同步完成"
        return 0
    else
        log_error "同步失败，请查看错误日志: ${ERROR_LOG}"
        return 1
    fi
}

# 发送通知（可选）
send_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-default}"
    
    # 使用 osascript 发送系统通知
    osascript -e "display notification \"${message}\" with title \"${title}\" sound name \"${sound}\"" 2>/dev/null || true
}

# 主函数
main() {
    log_info "========== 开始自动同步任务 =========="
    
    # 检查依赖
    if ! check_dependencies; then
        log_error "依赖检查失败，退出"
        send_notification "Thought 同步失败" "依赖检查失败" "Basso"
        exit 1
    fi
    
    # 执行同步
    if run_sync; then
        log_success "自动同步任务完成"
        
        # 检查是否有新的同步内容
        if grep -q "成功: [1-9]" "${LOG_FILE}" | tail -1; then
            send_notification "Thought 同步成功" "已同步新的 thought 到博客" "Glass"
        fi
    else
        log_error "自动同步任务失败"
        send_notification "Thought 同步失败" "请查看日志文件" "Basso"
        exit 1
    fi
    
    log_info "========== 自动同步任务结束 =========="
}

# 显示帮助信息
show_help() {
    echo "自动同步 thought 备忘录脚本"
    echo ""
    echo "使用方法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -t, --test     测试模式（不发送通知）"
    echo "  -v, --verbose  详细输出"
    echo ""
    echo "日志文件:"
    echo "  普通日志: ${LOG_FILE}"
    echo "  错误日志: ${ERROR_LOG}"
}

# 解析命令行参数
VERBOSE=false
TEST_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--test)
            TEST_MODE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 测试模式下禁用通知
if [ "$TEST_MODE" = true ]; then
    send_notification() {
        echo "通知: $1 - $2"
    }
fi

# 详细模式下输出到控制台
if [ "$VERBOSE" = true ]; then
    log_info() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "${LOG_FILE}"
    }
    
    log_error() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "${LOG_FILE}" | tee -a "${ERROR_LOG}"
    }
    
    log_success() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" | tee -a "${LOG_FILE}"
    }
fi

# 执行主函数
main "$@"
