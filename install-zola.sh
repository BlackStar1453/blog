#!/bin/bash

# Cloudflare Pages 环境中安装 Zola
set -e

echo "Installing Zola..."

# 下载并安装 Zola
ZOLA_VERSION="0.18.0"
ZOLA_URL="https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

# 创建临时目录
mkdir -p /tmp/zola
cd /tmp/zola

# 下载 Zola
curl -sL "$ZOLA_URL" | tar xz

# 移动到 PATH 中的位置
mkdir -p "$HOME/bin"
mv zola "$HOME/bin/"
export PATH="$HOME/bin:$PATH"

# 验证安装
zola --version

echo "Zola installed successfully!"
