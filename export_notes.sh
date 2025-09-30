#!/bin/bash

# macOS备忘录导出脚本
# 提供常用的导出预设

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/notes_to_markdown.py"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
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
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 未安装"
        exit 1
    fi
    
    if ! python3 -c "import macnotesapp" 2>/dev/null; then
        print_error "macnotesapp 库未安装"
        print_info "请运行: python3 -m pip install macnotesapp markdownify rich"
        exit 1
    fi
    
    if [ ! -f "$PYTHON_SCRIPT" ]; then
        print_error "找不到 notes_to_markdown.py 脚本"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
macOS备忘录导出工具

用法: $0 [选项] [预设名称]

预设:
  recent      导出最近30天的备忘录
  work        导出工作相关备忘录
  personal    导出个人备忘录
  long        导出长备忘录（>1000字）
  short       导出短备忘录（<100字）

选项:
  -o, --output DIR    输出目录
  -d, --days N        导出最近N天的备忘录
  -k, --keywords      按关键词搜索
  -l, --list          仅列出，不导出
  -h, --help          显示此帮助信息

示例:
  $0 recent                    # 使用recent预设
  $0 -d 7                      # 导出最近7天
  $0 -k "工作" "项目"          # 按关键词搜索
  $0 -l -d 30                  # 列出最近30天的备忘录
  $0 --output ~/Documents/notes recent  # 导出到指定目录

EOF
}

# 执行预设
run_preset() {
    local preset="$1"
    local output_dir="$2"
    
    case "$preset" in
        "recent")
            print_info "使用预设: 最近30天的备忘录"
            python3 "$PYTHON_SCRIPT" --days 30 --organize date ${output_dir:+--output "$output_dir"}
            ;;
        "work")
            print_info "使用预设: 工作相关备忘录"
            python3 "$PYTHON_SCRIPT" --keywords "工作" "项目" "会议" "任务" --organize folder ${output_dir:+--output "$output_dir"}
            ;;
        "personal")
            print_info "使用预设: 个人备忘录"
            python3 "$PYTHON_SCRIPT" --keywords "个人" "想法" "日记" "感想" --organize date ${output_dir:+--output "$output_dir"}
            ;;
        "long")
            print_info "使用预设: 长备忘录（>1000字）"
            python3 "$PYTHON_SCRIPT" --min-length 1000 --organize length ${output_dir:+--output "$output_dir"}
            ;;
        "short")
            print_info "使用预设: 短备忘录（<100字）"
            python3 "$PYTHON_SCRIPT" --max-length 100 --organize length ${output_dir:+--output "$output_dir"}
            ;;
        *)
            print_error "未知预设: $preset"
            print_info "可用预设: recent, work, personal, long, short"
            exit 1
            ;;
    esac
}

# 主函数
main() {
    check_dependencies
    
    local output_dir=""
    local days=""
    local keywords=()
    local list_only=false
    local preset=""
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            -d|--days)
                days="$2"
                shift 2
                ;;
            -k|--keywords)
                shift
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    keywords+=("$1")
                    shift
                done
                ;;
            -l|--list)
                list_only=true
                shift
                ;;
            recent|work|personal|long|short)
                preset="$1"
                shift
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果指定了预设，执行预设
    if [ -n "$preset" ]; then
        run_preset "$preset" "$output_dir"
        return
    fi
    
    # 构建命令
    local cmd="python3 \"$PYTHON_SCRIPT\""
    
    if [ -n "$output_dir" ]; then
        cmd="$cmd --output \"$output_dir\""
    fi
    
    if [ -n "$days" ]; then
        cmd="$cmd --days $days"
    fi
    
    if [ ${#keywords[@]} -gt 0 ]; then
        cmd="$cmd --keywords"
        for keyword in "${keywords[@]}"; do
            cmd="$cmd \"$keyword\""
        done
    fi
    
    if [ "$list_only" = true ]; then
        cmd="$cmd --list-only"
    fi
    
    # 如果没有任何参数，显示帮助
    if [ -z "$output_dir" ] && [ -z "$days" ] && [ ${#keywords[@]} -eq 0 ] && [ "$list_only" = false ]; then
        show_help
        exit 0
    fi
    
    # 执行命令
    print_info "执行命令: $cmd"
    eval "$cmd"
}

main "$@"
