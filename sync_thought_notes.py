#!/usr/bin/env python3
"""
备忘录 #thought 标签同步脚本
从macOS备忘录中获取带有#thought标签的内容，并同步到thoughts/index.md

作者: AI Assistant
版本: 1.0.0
"""

import os
import re
import json
import subprocess
import logging
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional, Set
from dataclasses import dataclass

try:
    from macnotesapp import NotesApp
    from rich.console import Console
    from rich.progress import Progress
    from rich import print as rprint
except ImportError as e:
    print(f"缺少必要的依赖库: {e}")
    print("请运行: python3 -m pip install macnotesapp rich")
    exit(1)

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('thought_sync.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class ThoughtNote:
    """Thought备忘录数据结构"""
    id: str
    title: str
    content: str
    creation_date: Optional[datetime]
    modification_date: Optional[datetime]
    account: str
    folder: str

class ThoughtSyncer:
    """Thought标签同步器"""
    
    def __init__(self, script_dir: str = "scripts"):
        self.console = Console()
        self.script_dir = Path(script_dir)
        self.add_thought_script = self.script_dir / "add-thought.sh"
        self.state_file = Path("thought_sync_state.json")
        self.processed_notes: Set[str] = set()
        self.notes_app = None
        
        # 加载已处理的备忘录状态
        self.load_state()
        
    def load_state(self) -> None:
        """加载已处理的备忘录状态"""
        if self.state_file.exists():
            try:
                with open(self.state_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    self.processed_notes = set(data.get('processed_notes', []))
                logger.info(f"加载状态: 已处理 {len(self.processed_notes)} 个备忘录")
            except Exception as e:
                logger.warning(f"加载状态文件失败: {e}")
                self.processed_notes = set()
    
    def save_state(self) -> None:
        """保存已处理的备忘录状态"""
        try:
            data = {
                'processed_notes': list(self.processed_notes),
                'last_sync': datetime.now().isoformat()
            }
            with open(self.state_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            logger.debug("状态已保存")
        except Exception as e:
            logger.error(f"保存状态失败: {e}")
    
    def connect_to_notes(self) -> bool:
        """连接到备忘录应用"""
        try:
            self.notes_app = NotesApp()
            logger.info("成功连接到备忘录应用")
            return True
        except Exception as e:
            logger.error(f"连接备忘录应用失败: {e}")
            return False
    
    def extract_thought_content(self, note) -> Optional[ThoughtNote]:
        """提取带有#thought标签的备忘录内容"""
        try:
            # 获取备忘录的纯文本内容
            content = getattr(note, 'plaintext', '') or getattr(note, 'body', '')
            if not content:
                return None
            
            # 检查是否包含#thought标签
            if '#thought' not in content.lower():
                return None
            
            # 提取备忘录信息
            thought_note = ThoughtNote(
                id=getattr(note, 'id', 'unknown'),
                title=getattr(note, 'name', '无标题'),
                content=content,
                creation_date=getattr(note, 'creation_date', None),
                modification_date=getattr(note, 'modification_date', None),
                account=getattr(note, 'account', '未知账户'),
                folder=getattr(note, 'folder', '未知文件夹')
            )
            
            return thought_note
            
        except Exception as e:
            logger.warning(f"提取备忘录内容失败: {e}")
            return None
    
    def clean_thought_content(self, content: str) -> str:
        """清理thought内容，移除标签并格式化"""
        # 移除#thought标签
        content = re.sub(r'#thought\s*', '', content, flags=re.IGNORECASE)
        
        # 清理多余的空行
        content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)
        content = content.strip()
        
        # 如果内容为空，返回None
        if not content:
            return None
        
        return content
    
    def format_date_for_script(self, date: Optional[datetime]) -> Optional[str]:
        """格式化日期为脚本可接受的格式"""
        if not date:
            return None
        
        # 格式化为 YYYY-MM-DD HH:MM
        return date.strftime("%Y-%m-%d %H:%M")
    
    def call_add_thought_script(self, content: str, date_str: Optional[str] = None) -> bool:
        """调用add-thought.sh脚本"""
        try:
            # 检查脚本是否存在
            if not self.add_thought_script.exists():
                logger.error(f"add-thought.sh脚本不存在: {self.add_thought_script}")
                return False
            
            # 构建命令
            cmd = [str(self.add_thought_script), content]
            if date_str:
                cmd.append(date_str)
            
            # 执行脚本
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                encoding='utf-8'
            )
            
            if result.returncode == 0:
                logger.info(f"成功添加thought: {content[:50]}...")
                return True
            else:
                logger.error(f"添加thought失败: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"调用add-thought.sh脚本失败: {e}")
            return False
    
    def get_thought_notes(self) -> List[ThoughtNote]:
        """获取所有带有#thought标签的备忘录"""
        if not self.notes_app:
            raise RuntimeError("未连接到备忘录应用")
        
        thought_notes = []
        
        try:
            all_notes = self.notes_app.notes()
            logger.info(f"扫描 {len(all_notes)} 个备忘录...")
            
            for note in all_notes:
                thought_note = self.extract_thought_content(note)
                if thought_note:
                    thought_notes.append(thought_note)
            
            logger.info(f"找到 {len(thought_notes)} 个带有#thought标签的备忘录")
            return thought_notes
            
        except Exception as e:
            logger.error(f"获取thought备忘录失败: {e}")
            return []
    
    def sync_thoughts(self, force: bool = False) -> Dict[str, int]:
        """同步thought备忘录到thoughts/index.md"""
        results = {'success': 0, 'skipped': 0, 'failed': 0}
        
        # 获取thought备忘录
        thought_notes = self.get_thought_notes()
        
        if not thought_notes:
            self.console.print("❌ 没有找到带有#thought标签的备忘录", style="yellow")
            return results
        
        # 处理每个thought备忘录
        with Progress() as progress:
            task = progress.add_task("同步中...", total=len(thought_notes))
            
            for thought_note in thought_notes:
                progress.update(task, advance=1)
                
                # 检查是否已经处理过
                if not force and thought_note.id in self.processed_notes:
                    logger.debug(f"跳过已处理的备忘录: {thought_note.title}")
                    results['skipped'] += 1
                    continue
                
                # 清理内容
                cleaned_content = self.clean_thought_content(thought_note.content)
                if not cleaned_content:
                    logger.warning(f"备忘录内容为空: {thought_note.title}")
                    results['skipped'] += 1
                    continue
                
                # 格式化日期
                date_str = self.format_date_for_script(
                    thought_note.modification_date or thought_note.creation_date
                )
                
                # 调用add-thought.sh脚本
                if self.call_add_thought_script(cleaned_content, date_str):
                    self.processed_notes.add(thought_note.id)
                    results['success'] += 1
                    
                    # 显示成功信息
                    self.console.print(
                        f"✅ 已同步: {thought_note.title[:30]}...", 
                        style="green"
                    )
                else:
                    results['failed'] += 1
                    self.console.print(
                        f"❌ 同步失败: {thought_note.title[:30]}...", 
                        style="red"
                    )
        
        # 保存状态
        self.save_state()
        
        return results
    
    def list_thought_notes(self) -> None:
        """列出所有带有#thought标签的备忘录"""
        thought_notes = self.get_thought_notes()
        
        if not thought_notes:
            self.console.print("❌ 没有找到带有#thought标签的备忘录", style="yellow")
            return
        
        self.console.print(f"\n📋 找到 {len(thought_notes)} 个带有#thought标签的备忘录:\n", style="bold blue")
        
        for i, note in enumerate(thought_notes, 1):
            status = "✅ 已处理" if note.id in self.processed_notes else "⏳ 待处理"
            
            self.console.print(f"{i}. {note.title}")
            self.console.print(f"   账户: {note.account} | 文件夹: {note.folder}")
            self.console.print(f"   状态: {status}")
            
            if note.modification_date:
                self.console.print(f"   修改时间: {note.modification_date.strftime('%Y-%m-%d %H:%M')}")
            
            # 显示内容预览
            cleaned_content = self.clean_thought_content(note.content)
            if cleaned_content:
                preview = cleaned_content[:100] + "..." if len(cleaned_content) > 100 else cleaned_content
                self.console.print(f"   内容预览: {preview}", style="dim")
            
            self.console.print()
    
    def reset_state(self) -> None:
        """重置处理状态"""
        self.processed_notes.clear()
        if self.state_file.exists():
            self.state_file.unlink()
        self.console.print("✅ 已重置处理状态", style="green")


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="同步macOS备忘录中带有#thought标签的内容到thoughts/index.md",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 同步新的thought备忘录
  python3 sync_thought_notes.py
  
  # 列出所有thought备忘录
  python3 sync_thought_notes.py --list
  
  # 强制重新同步所有备忘录
  python3 sync_thought_notes.py --force
  
  # 重置处理状态
  python3 sync_thought_notes.py --reset
        """
    )
    
    parser.add_argument(
        '--list', '-l',
        action='store_true',
        help='列出所有带有#thought标签的备忘录'
    )
    
    parser.add_argument(
        '--force', '-f',
        action='store_true',
        help='强制重新同步所有备忘录（忽略已处理状态）'
    )
    
    parser.add_argument(
        '--reset', '-r',
        action='store_true',
        help='重置处理状态'
    )
    
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='详细输出'
    )
    
    args = parser.parse_args()
    
    # 设置日志级别
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    console = Console()
    
    try:
        # 初始化同步器
        syncer = ThoughtSyncer()
        
        # 重置状态
        if args.reset:
            syncer.reset_state()
            return 0
        
        # 连接到备忘录应用
        console.print("🔗 连接到备忘录应用...", style="blue")
        if not syncer.connect_to_notes():
            console.print("❌ 连接失败", style="red")
            return 1
        
        # 列出备忘录
        if args.list:
            syncer.list_thought_notes()
            return 0
        
        # 同步备忘录
        console.print("🔄 开始同步thought备忘录...", style="bold green")
        results = syncer.sync_thoughts(force=args.force)
        
        # 显示结果
        console.print("\n✅ 同步完成!", style="bold green")
        console.print(f"   成功: {results['success']} 个", style="green")
        console.print(f"   跳过: {results['skipped']} 个", style="yellow")
        console.print(f"   失败: {results['failed']} 个", style="red")
        
        return 0
        
    except KeyboardInterrupt:
        console.print("\n❌ 用户中断", style="red")
        return 1
    except Exception as e:
        console.print(f"\n❌ 发生错误: {e}", style="red")
        logger.exception("程序执行出错")
        return 1


if __name__ == "__main__":
    exit(main())
