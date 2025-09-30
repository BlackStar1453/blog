#!/bin/bash

# 依赖库安装脚本
# 确保在正确的Python环境中安装所需的依赖库

set -e

echo "🔧 Python环境和依赖库安装脚本"
echo "=================================="

# 检测Python版本和路径
echo "📍 检测Python环境..."
PYTHON_CMD=""

# 优先使用Homebrew Python（如果存在）
if command -v /opt/homebrew/bin/python3 &> /dev/null; then
    PYTHON_CMD="/opt/homebrew/bin/python3"
    echo "✅ 使用Homebrew Python: $PYTHON_CMD"
elif command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
    echo "✅ 使用系统Python: $PYTHON_CMD"
else
    echo "❌ 未找到Python3，请先安装Python"
    exit 1
fi

# 显示Python信息
echo "📋 Python信息:"
$PYTHON_CMD --version
echo "   路径: $(which $PYTHON_CMD)"

# 检查pip
echo ""
echo "📦 检查pip..."
if ! $PYTHON_CMD -m pip --version &> /dev/null; then
    echo "❌ pip未安装，正在安装..."
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    $PYTHON_CMD get-pip.py
    rm get-pip.py
fi

echo "✅ pip版本: $($PYTHON_CMD -m pip --version)"

# 升级pip（处理外部管理环境）
echo ""
echo "⬆️  升级pip..."
if $PYTHON_CMD -m pip install --upgrade pip 2>/dev/null; then
    echo "✅ pip升级成功"
else
    echo "ℹ️  pip升级跳过（外部管理环境）"
fi

# 安装依赖库
echo ""
echo "📚 安装依赖库..."
DEPENDENCIES=(
    "macnotesapp>=0.7.0"
    "rich>=12.0.0"
    "markdownify>=0.11.0"
    "requests>=2.25.0"
)

# 检测是否需要特殊参数
PIP_ARGS=""
if [[ "$PYTHON_CMD" == *"homebrew"* ]]; then
    echo "ℹ️  检测到Homebrew Python，使用--break-system-packages参数"
    PIP_ARGS="--break-system-packages"
fi

for dep in "${DEPENDENCIES[@]}"; do
    echo "   安装: $dep"
    if ! $PYTHON_CMD -m pip install $PIP_ARGS "$dep"; then
        echo "   ⚠️  尝试使用--user参数安装..."
        $PYTHON_CMD -m pip install --user "$dep"
    fi
done

# 验证安装
echo ""
echo "🔍 验证安装..."
$PYTHON_CMD -c "
import sys
print(f'Python版本: {sys.version}')
print(f'Python路径: {sys.executable}')
print()

try:
    import macnotesapp
    print('✅ macnotesapp 安装成功')
    print(f'   版本: {macnotesapp.__version__}')
except ImportError as e:
    print(f'❌ macnotesapp 安装失败: {e}')

try:
    import rich
    print('✅ rich 安装成功')
    try:
        print(f'   版本: {rich.__version__}')
    except AttributeError:
        print('   版本: 已安装（版本信息不可用）')
except ImportError as e:
    print(f'❌ rich 安装失败: {e}')

try:
    import markdownify
    print('✅ markdownify 安装成功')
except ImportError as e:
    print(f'❌ markdownify 安装失败: {e}')

try:
    import requests
    print('✅ requests 安装成功')
    print(f'   版本: {requests.__version__}')
except ImportError as e:
    print(f'❌ requests 安装失败: {e}')
"

# 创建Python别名配置
echo ""
echo "🔗 配置Python别名..."

# 检测shell类型
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
    # 如果.bashrc不存在，使用.bash_profile
    if [[ ! -f "$SHELL_RC" ]]; then
        SHELL_RC="$HOME/.bash_profile"
    fi
else
    SHELL_RC="$HOME/.profile"
fi

echo "   Shell配置文件: $SHELL_RC"

# 添加Python别名（如果不存在）
ALIAS_LINE="alias python3-blog='$PYTHON_CMD'"
if [[ -f "$SHELL_RC" ]] && ! grep -q "python3-blog" "$SHELL_RC"; then
    echo "" >> "$SHELL_RC"
    echo "# Blog Python环境别名" >> "$SHELL_RC"
    echo "$ALIAS_LINE" >> "$SHELL_RC"
    echo "✅ 已添加别名到 $SHELL_RC"
    echo "   使用 'python3-blog' 命令来运行脚本"
else
    echo "ℹ️  别名已存在或无法添加到 $SHELL_RC"
fi

echo ""
echo "🎉 依赖库安装完成！"
echo ""
echo "📝 使用说明:"
echo "   1. 重新加载shell配置: source $SHELL_RC"
echo "   2. 使用别名运行脚本: python3-blog sync_multi_tag_notes.py"
echo "   3. 或直接使用完整路径: $PYTHON_CMD sync_multi_tag_notes.py"
echo ""
echo "🔧 如果仍有问题，请运行:"
echo "   $PYTHON_CMD -c \"import macnotesapp, rich, markdownify; print('所有依赖库正常')\""
