#!/bin/bash

# Cloudflare Pages 构建脚本
set -e

echo "=== Cloudflare Pages Build Script ==="

# 1. 安装 Zola
echo "Step 1: Installing Zola..."
bash install-zola.sh

# 2. 添加 Zola 到 PATH
export PATH="$HOME/bin:$PATH"

# 3. 生成特殊日期页面（如果脚本存在）
if [ -f "scripts/generate_special_dates_pages.py" ]; then
    echo "Step 2: Generating special date pages..."
    python3 scripts/generate_special_dates_pages.py || echo "Warning: Failed to generate special date pages"
fi

# 4. 构建站点
echo "Step 3: Building site with Zola..."
zola build

echo "=== Build completed successfully! ==="
