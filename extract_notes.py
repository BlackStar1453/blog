#!/usr/bin/env python3
"""
Apple Notes 数据提取脚本
负责运行 Apple Cloud Notes Parser 并提取备忘录数据到 JSON

作者: AI Assistant
版本: 1.0.0
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from typing import Optional
import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class NotesExtractor:
    """Apple Notes 数据提取器"""
    
    def __init__(self, parser_dir: str = "apple_cloud_notes_parser"):
        self.parser_dir = Path(parser_dir)
        self.output_dir = self.parser_dir / "output/notes_rip"
        
    def check_parser_exists(self) -> bool:
        """检查 Apple Cloud Notes Parser 是否存在"""
        parser_script = self.parser_dir / "notes_cloud_ripper.rb"
        if not parser_script.exists():
            logger.error(f"找不到 Apple Cloud Notes Parser: {parser_script}")
            logger.error("请先克隆仓库: git clone https://github.com/threeplanetssoftware/apple_cloud_notes_parser.git")
            return False
        return True
    
    def run_parser(self) -> Optional[str]:
        """
        运行 Apple Cloud Notes Parser 提取备忘录数据
        
        Returns:
            提取的 JSON 文件路径,失败返回 None
        """
        if not self.check_parser_exists():
            return None
            
        logger.info("🔍 正在运行 Apple Cloud Notes Parser 提取备忘录数据...")
        
        try:
            # 设置 Ruby 环境
            env = os.environ.copy()
            env['PATH'] = f"/opt/homebrew/opt/ruby/bin:{env.get('PATH', '')}"
            
            # 运行解析器
            parser_script = "notes_cloud_ripper.rb"
            notes_db = Path.home() / "Library/Group Containers/group.com.apple.notes"

            result = subprocess.run(
                ["ruby", parser_script, "--mac", str(notes_db), "--one-output-folder"],
                cwd=str(self.parser_dir.absolute()),
                env=env,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode != 0:
                logger.error(f"Apple Cloud Notes Parser 运行失败: {result.stderr}")
                return None
            
            # 查找生成的 JSON 文件
            json_dir = self.output_dir / "json"
            if not json_dir.exists():
                logger.error(f"JSON 输出目录不存在: {json_dir}")
                return None
            
            # 按修改时间排序,使用最新的文件
            json_files = sorted(
                json_dir.glob("all_notes_*.json"),
                key=lambda p: p.stat().st_mtime,
                reverse=True
            )
            
            if not json_files:
                logger.error(f"未找到 JSON 文件: {json_dir}/all_notes_*.json")
                return None
            
            json_file = json_files[0]
            logger.info(f"✅ 成功提取备忘录数据: {json_file}")
            return str(json_file)
            
        except subprocess.TimeoutExpired:
            logger.error("Apple Cloud Notes Parser 运行超时")
            return None
        except Exception as e:
            logger.error(f"运行 Apple Cloud Notes Parser 时出错: {e}")
            return None
    
    def load_notes_json(self, json_path: Optional[str] = None) -> Optional[dict]:
        """
        加载备忘录 JSON 数据
        
        Args:
            json_path: JSON 文件路径,如果为 None 则使用最新的
            
        Returns:
            备忘录数据字典,失败返回 None
        """
        if json_path is None:
            # 查找最新的 JSON 文件
            json_dir = self.output_dir / "json"
            if not json_dir.exists():
                logger.error(f"JSON 输出目录不存在: {json_dir}")
                return None
            
            json_files = sorted(
                json_dir.glob("all_notes_*.json"),
                key=lambda p: p.stat().st_mtime,
                reverse=True
            )
            
            if not json_files:
                logger.error(f"未找到 JSON 文件")
                return None
            
            json_path = str(json_files[0])
        
        try:
            with open(json_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            logger.info(f"✅ 成功加载备忘录数据: {json_path}")
            return data
        except Exception as e:
            logger.error(f"加载 JSON 文件失败: {e}")
            return None
    
    def get_latest_json_path(self) -> Optional[str]:
        """获取最新的 JSON 文件路径"""
        json_dir = self.output_dir / "json"
        if not json_dir.exists():
            return None
        
        json_files = sorted(
            json_dir.glob("all_notes_*.json"),
            key=lambda p: p.stat().st_mtime,
            reverse=True
        )
        
        return str(json_files[0]) if json_files else None


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="提取 Apple Notes 数据到 JSON")
    parser.add_argument("--parser-dir", default="apple_cloud_notes_parser",
                       help="Apple Cloud Notes Parser 目录路径")
    parser.add_argument("--extract", action="store_true",
                       help="运行提取操作")
    parser.add_argument("--load", action="store_true",
                       help="加载最新的 JSON 数据")
    parser.add_argument("--json-path", help="指定 JSON 文件路径")
    
    args = parser.parse_args()
    
    extractor = NotesExtractor(args.parser_dir)
    
    if args.extract:
        json_path = extractor.run_parser()
        if json_path:
            print(f"✅ 提取成功: {json_path}")
            sys.exit(0)
        else:
            print("❌ 提取失败")
            sys.exit(1)
    
    if args.load:
        data = extractor.load_notes_json(args.json_path)
        if data:
            print(f"✅ 加载成功,共 {len(data)} 条备忘录")
            sys.exit(0)
        else:
            print("❌ 加载失败")
            sys.exit(1)
    
    # 默认显示最新的 JSON 文件路径
    json_path = extractor.get_latest_json_path()
    if json_path:
        print(f"最新 JSON 文件: {json_path}")
    else:
        print("未找到 JSON 文件")
        sys.exit(1)


if __name__ == "__main__":
    main()

