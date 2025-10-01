#!/usr/bin/env python3
"""
Mastodon 发布脚本
负责将内容发布到 Mastodon

作者: AI Assistant
版本: 1.0.0
"""

import os
import sys
import urllib.request
import urllib.parse
import json
import logging
from typing import Optional
from pathlib import Path

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def load_env_file(env_path: str = '.env'):
    """加载 .env 文件中的环境变量"""
    if os.path.exists(env_path):
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key.strip()] = value.strip()


# 加载环境变量
load_env_file()


class MastodonPoster:
    """Mastodon 发布器"""
    
    def __init__(self):
        self.access_token = os.getenv('MASTODON_ACCESS_TOKEN')
        self.instance_url = os.getenv('MASTODON_INSTANCE_URL')
        
    def _instance_origin(self) -> Optional[str]:
        """获取 Mastodon 实例的 origin"""
        if not self.instance_url:
            return None
        
        # 移除尾部斜杠
        url = self.instance_url.rstrip('/')
        
        # 如果没有协议,添加 https://
        if not url.startswith(('http://', 'https://')):
            url = f'https://{url}'
        
        return url
    
    def post_status(self, text: str, visibility: str = "public") -> bool:
        """
        发布状态到 Mastodon
        
        Args:
            text: 要发布的文本内容
            visibility: 可见性 (public, unlisted, private, direct)
            
        Returns:
            发布成功返回 True,失败返回 False
        """
        if not self.access_token or not self.instance_url:
            logger.error("Mastodon 配置不完整,请检查 .env 文件")
            return False
        
        origin = self._instance_origin()
        if not origin:
            logger.error("无效的 Mastodon 实例 URL")
            return False
        
        api_url = f"{origin}/api/v1/statuses"
        
        data = {
            'status': text,
            'visibility': visibility
        }
        
        try:
            req = urllib.request.Request(
                api_url,
                data=urllib.parse.urlencode(data).encode('utf-8'),
                headers={
                    'Authorization': f'Bearer {self.access_token}',
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                method='POST'
            )
            
            with urllib.request.urlopen(req, timeout=30) as response:
                if response.status == 200:
                    logger.info("✅ 成功发布到 Mastodon")
                    return True
                else:
                    logger.error(f"发布失败,状态码: {response.status}")
                    return False
                    
        except Exception as e:
            logger.error(f"发布到 Mastodon 时出错: {e}")
            return False
    
    def build_article_status(self, title: str, content: str, url: Optional[str] = None, max_length: int = 400) -> str:
        """
        构建文章状态文本
        
        Args:
            title: 文章标题
            content: 文章内容
            url: 文章链接
            max_length: 内容最大长度
            
        Returns:
            格式化的状态文本
        """
        # 清理内容
        content = content.strip()
        
        # 如果内容太长,截断并添加省略号
        if len(content) > max_length:
            content = content[:max_length] + "..."
        
        # 构建状态文本
        if url:
            status = f"📝 {title}\n\n{content}\n\n🔗 {url}"
        else:
            status = f"📝 {title}\n\n{content}"
        
        return status
    
    def is_configured(self) -> bool:
        """检查 Mastodon 是否已配置"""
        return bool(self.access_token and self.instance_url)


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="发布内容到 Mastodon")
    parser.add_argument("text", nargs="?", help="要发布的文本内容")
    parser.add_argument("--title", help="文章标题")
    parser.add_argument("--content", help="文章内容")
    parser.add_argument("--url", help="文章链接")
    parser.add_argument("--visibility", default="public",
                       choices=["public", "unlisted", "private", "direct"],
                       help="可见性设置")
    parser.add_argument("--check", action="store_true",
                       help="检查配置是否正确")
    
    args = parser.parse_args()
    
    poster = MastodonPoster()
    
    if args.check:
        if poster.is_configured():
            print("✅ Mastodon 配置正确")
            print(f"实例: {poster.instance_url}")
            sys.exit(0)
        else:
            print("❌ Mastodon 配置不完整")
            print("请在 .env 文件中设置:")
            print("  MASTODON_ACCESS_TOKEN=your_token")
            print("  MASTODON_INSTANCE_URL=your_instance")
            sys.exit(1)
    
    # 构建状态文本
    if args.title and args.content:
        text = poster.build_article_status(args.title, args.content, args.url)
    elif args.text:
        text = args.text
    else:
        # 从 stdin 读取
        text = sys.stdin.read().strip()
        if not text:
            print("错误: 请提供要发布的文本内容")
            sys.exit(1)
    
    # 发布
    if poster.post_status(text, args.visibility):
        print("✅ 发布成功")
        sys.exit(0)
    else:
        print("❌ 发布失败")
        sys.exit(1)


if __name__ == "__main__":
    main()

