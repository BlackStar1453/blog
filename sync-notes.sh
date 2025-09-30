#!/bin/bash

# 备忘录同步启动脚本
# 自动检测并使用正确的Python环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检测Python环境
detect_python() {
    local python_cmd=""

    # 优先使用Homebrew Python
    if command -v /opt/homebrew/bin/python3 &> /dev/null; then
        python_cmd="/opt/homebrew/bin/python3"
        echo -e "${GREEN}✅ 使用Homebrew Python: $python_cmd${NC}" >&2
    elif command -v python3 &> /dev/null; then
        python_cmd="python3"
        echo -e "${YELLOW}⚠️  使用系统Python: $python_cmd${NC}" >&2
    else
        echo -e "${RED}❌ 未找到Python3，请先安装Python${NC}" >&2
        exit 1
    fi

    echo "$python_cmd"
}

# 检查依赖库
check_dependencies() {
    local python_cmd="$1"
    
    echo -e "${BLUE}🔍 检查依赖库...${NC}"
    
    if ! $python_cmd -c "import macnotesapp, rich, markdownify, requests" 2>/dev/null; then
        echo -e "${RED}❌ 缺少依赖库${NC}"
        echo -e "${YELLOW}🔧 正在运行自动安装脚本...${NC}"
        
        if [[ -f "./scripts/setup-dependencies.sh" ]]; then
            ./scripts/setup-dependencies.sh
        else
            echo -e "${RED}❌ 未找到安装脚本，请手动安装依赖库:${NC}"
            echo "   $python_cmd -m pip install -r requirements.txt"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ 依赖库检查通过${NC}"
    fi
}

# 主函数
main() {
    echo -e "${BLUE}🚀 备忘录同步脚本启动器${NC}"
    echo "=================================="
    
    # 检测Python环境
    PYTHON_CMD=$(detect_python)
    
    # 检查依赖库
    check_dependencies "$PYTHON_CMD"
    
    # 运行同步脚本
    echo -e "${BLUE}📝 运行同步脚本...${NC}"
    echo "命令: $PYTHON_CMD sync_multi_tag_notes.py $@"
    echo ""
    
    exec "$PYTHON_CMD" sync_multi_tag_notes.py "$@"
}

# 运行主函数
main "$@"
