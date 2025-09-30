#!/usr/bin/env python3
"""
macOS Notes to Markdown Exporter
功能完整的备忘录导出脚本，支持筛选、分类和批量处理

作者: AI Assistant
版本: 1.0.0
"""

import os
import re
import json
import argparse
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict
import unicodedata

try:
    from macnotesapp import NotesApp
    from markdownify import markdownify as md
    from rich.console import Console
    from rich.progress import Progress, TaskID
    from rich.table import Table
    from rich import print as rprint
except ImportError as e:
    print(f"缺少必要的依赖库: {e}")
    print("请运行: python3 -m pip install macnotesapp markdownify rich")
    exit(1)

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('notes_export.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class NoteMetadata:
    """备忘录元数据"""
    id: str
    name: str
    account: str
    folder: str
    creation_date: Optional[datetime]
    modification_date: Optional[datetime]
    body_length: int
    plaintext_length: int
    password_protected: bool
    
class NotesProcessor:
    """备忘录处理器"""
    
    def __init__(self, output_dir: str = "exported_notes"):
        self.console = Console()
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.notes_app = None
        self.stats = {
            'total': 0,
            'exported': 0,
            'skipped': 0,
            'errors': 0
        }
        
    def connect_to_notes(self) -> bool:
        """连接到备忘录应用"""
        try:
            self.notes_app = NotesApp()
            logger.info("成功连接到备忘录应用")
            return True
        except Exception as e:
            logger.error(f"连接备忘录应用失败: {e}")
            return False
    
    def get_all_notes(self) -> List:
        """获取所有备忘录"""
        if not self.notes_app:
            raise RuntimeError("未连接到备忘录应用")
        
        try:
            notes = self.notes_app.notes()
            logger.info(f"获取到 {len(notes)} 个备忘录")
            return notes
        except Exception as e:
            logger.error(f"获取备忘录失败: {e}")
            return []
    
    def extract_metadata(self, note) -> NoteMetadata:
        """提取备忘录元数据"""
        try:
            return NoteMetadata(
                id=note.id,
                name=note.name or "无标题",
                account=note.account or "未知账户",
                folder=note.folder or "未知文件夹",
                creation_date=getattr(note, 'creation_date', None),
                modification_date=getattr(note, 'modification_date', None),
                body_length=len(note.body) if note.body else 0,
                plaintext_length=len(note.plaintext) if note.plaintext else 0,
                password_protected=getattr(note, 'password_protected', False)
            )
        except Exception as e:
            logger.warning(f"提取元数据失败: {e}")
            return NoteMetadata(
                id=getattr(note, 'id', 'unknown'),
                name=getattr(note, 'name', '无标题'),
                account="未知账户",
                folder="未知文件夹",
                creation_date=None,
                modification_date=None,
                body_length=0,
                plaintext_length=0,
                password_protected=False
            )
    
    def sanitize_filename(self, filename: str, max_length: int = 100) -> str:
        """清理文件名"""
        # 移除或替换非法字符
        filename = re.sub(r'[<>:"/\\|?*]', '_', filename)
        filename = re.sub(r'\s+', ' ', filename).strip()
        
        # 处理Unicode字符
        filename = unicodedata.normalize('NFKC', filename)
        
        # 限制长度
        if len(filename) > max_length:
            filename = filename[:max_length-3] + "..."
        
        # 确保不为空
        if not filename or filename.isspace():
            filename = "untitled"
            
        return filename
    
    def html_to_markdown(self, html_content: str) -> str:
        """将HTML转换为Markdown"""
        if not html_content:
            return ""
        
        try:
            # 使用markdownify转换
            markdown_content = md(
                html_content,
                heading_style="ATX",
                bullets="-",
                strip=['script', 'style']
            )
            
            # 清理多余的空行
            markdown_content = re.sub(r'\n\s*\n\s*\n', '\n\n', markdown_content)
            markdown_content = markdown_content.strip()
            
            return markdown_content
        except Exception as e:
            logger.warning(f"HTML转换失败: {e}")
            return html_content
    
    def create_note_content(self, note, metadata: NoteMetadata) -> str:
        """创建备忘录内容"""
        content_parts = []
        
        # 添加标题
        title = metadata.name
        content_parts.append(f"# {title}\n")
        
        # 添加元数据
        content_parts.append("## 元数据\n")
        content_parts.append(f"- **账户**: {metadata.account}")
        content_parts.append(f"- **文件夹**: {metadata.folder}")
        
        if metadata.creation_date:
            content_parts.append(f"- **创建时间**: {metadata.creation_date}")
        if metadata.modification_date:
            content_parts.append(f"- **修改时间**: {metadata.modification_date}")
            
        content_parts.append(f"- **字符数**: {metadata.plaintext_length}")
        content_parts.append(f"- **备忘录ID**: {metadata.id}")
        
        if metadata.password_protected:
            content_parts.append("- **状态**: 🔒 密码保护")
        
        content_parts.append("\n---\n")
        
        # 添加正文内容
        content_parts.append("## 内容\n")
        
        if metadata.password_protected:
            content_parts.append("*此备忘录受密码保护，无法导出内容*")
        else:
            try:
                if hasattr(note, 'body') and note.body:
                    markdown_content = self.html_to_markdown(note.body)
                    content_parts.append(markdown_content)
                elif hasattr(note, 'plaintext') and note.plaintext:
                    content_parts.append(note.plaintext)
                else:
                    content_parts.append("*空备忘录*")
            except Exception as e:
                logger.warning(f"获取备忘录内容失败: {e}")
                content_parts.append("*无法获取备忘录内容*")
        
        return "\n".join(content_parts)

    def filter_notes_by_date(self, notes: List, start_date: Optional[datetime] = None,
                           end_date: Optional[datetime] = None) -> List:
        """按日期筛选备忘录"""
        if not start_date and not end_date:
            return notes

        filtered = []
        for note in notes:
            metadata = self.extract_metadata(note)
            note_date = metadata.modification_date or metadata.creation_date

            if not note_date:
                continue

            if start_date and note_date < start_date:
                continue
            if end_date and note_date > end_date:
                continue

            filtered.append(note)

        return filtered

    def filter_notes_by_keywords(self, notes: List, keywords: List[str],
                                search_in_content: bool = True) -> List:
        """按关键词筛选备忘录"""
        if not keywords:
            return notes

        filtered = []
        for note in notes:
            metadata = self.extract_metadata(note)

            # 搜索标题
            title_match = any(keyword.lower() in metadata.name.lower() for keyword in keywords)

            # 搜索内容
            content_match = False
            if search_in_content and not metadata.password_protected:
                try:
                    content = getattr(note, 'plaintext', '') or getattr(note, 'body', '')
                    content_match = any(keyword.lower() in content.lower() for keyword in keywords)
                except:
                    pass

            if title_match or content_match:
                filtered.append(note)

        return filtered

    def filter_notes_by_account(self, notes: List, accounts: List[str]) -> List:
        """按账户筛选备忘录"""
        if not accounts:
            return notes

        return [note for note in notes
                if self.extract_metadata(note).account in accounts]

    def filter_notes_by_folder(self, notes: List, folders: List[str]) -> List:
        """按文件夹筛选备忘录"""
        if not folders:
            return notes

        return [note for note in notes
                if self.extract_metadata(note).folder in folders]

    def filter_notes_by_length(self, notes: List, min_length: int = 0,
                              max_length: int = float('inf')) -> List:
        """按长度筛选备忘录"""
        filtered = []
        for note in notes:
            metadata = self.extract_metadata(note)
            length = metadata.plaintext_length

            if min_length <= length <= max_length:
                filtered.append(note)

        return filtered

    def categorize_notes(self, notes: List, category_type: str = "date") -> Dict[str, List]:
        """对备忘录进行分类"""
        categories = {}

        for note in notes:
            metadata = self.extract_metadata(note)

            if category_type == "date":
                date = metadata.modification_date or metadata.creation_date
                if date:
                    key = date.strftime("%Y-%m")
                else:
                    key = "未知日期"
            elif category_type == "account":
                key = metadata.account
            elif category_type == "folder":
                key = metadata.folder
            elif category_type == "length":
                length = metadata.plaintext_length
                if length == 0:
                    key = "空备忘录"
                elif length < 100:
                    key = "短备忘录(<100字)"
                elif length < 1000:
                    key = "中等备忘录(100-1000字)"
                else:
                    key = "长备忘录(>1000字)"
            else:
                key = "其他"

            if key not in categories:
                categories[key] = []
            categories[key].append(note)

        return categories

    def export_note(self, note, output_path: Path, metadata: NoteMetadata) -> bool:
        """导出单个备忘录"""
        try:
            content = self.create_note_content(note, metadata)

            # 确保目录存在
            output_path.parent.mkdir(parents=True, exist_ok=True)

            # 写入文件
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(content)

            logger.debug(f"导出成功: {output_path}")
            return True

        except Exception as e:
            logger.error(f"导出失败 {metadata.name}: {e}")
            return False

    def batch_export(self, notes: List, organize_by: str = "flat",
                    progress_callback=None) -> Dict[str, int]:
        """批量导出备忘录"""
        results = {'success': 0, 'failed': 0, 'skipped': 0}

        if organize_by == "flat":
            # 平铺结构
            export_dir = self.output_dir
        else:
            # 分类结构
            categories = self.categorize_notes(notes, organize_by)

        for i, note in enumerate(notes):
            if progress_callback:
                progress_callback(i, len(notes))

            metadata = self.extract_metadata(note)

            # 跳过密码保护的备忘录（可选）
            if metadata.password_protected:
                logger.info(f"跳过密码保护的备忘录: {metadata.name}")
                results['skipped'] += 1
                continue

            # 生成文件名
            safe_name = self.sanitize_filename(metadata.name)
            filename = f"{safe_name}.md"

            # 确定输出路径
            if organize_by == "flat":
                output_path = self.output_dir / filename
            else:
                # 找到备忘录所属的分类
                category_key = None
                for key, category_notes in categories.items():
                    if note in category_notes:
                        category_key = key
                        break

                if category_key:
                    category_dir = self.output_dir / self.sanitize_filename(category_key)
                    output_path = category_dir / filename
                else:
                    output_path = self.output_dir / "未分类" / filename

            # 处理重名文件
            counter = 1
            original_path = output_path
            while output_path.exists():
                stem = original_path.stem
                suffix = original_path.suffix
                output_path = original_path.parent / f"{stem}_{counter}{suffix}"
                counter += 1

            # 导出备忘录
            if self.export_note(note, output_path, metadata):
                results['success'] += 1
            else:
                results['failed'] += 1

        return results

    def generate_index(self, notes: List, organize_by: str = "date") -> str:
        """生成索引文件内容"""
        index_content = ["# 备忘录导出索引\n"]
        index_content.append(f"导出时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        index_content.append(f"总计备忘录: {len(notes)}\n")

        # 按分类组织
        categories = self.categorize_notes(notes, organize_by)

        for category, category_notes in sorted(categories.items()):
            index_content.append(f"## {category} ({len(category_notes)}个)")

            for note in category_notes:
                metadata = self.extract_metadata(note)
                safe_name = self.sanitize_filename(metadata.name)
                filename = f"{safe_name}.md"

                # 创建相对路径
                if organize_by != "flat":
                    relative_path = f"{self.sanitize_filename(category)}/{filename}"
                else:
                    relative_path = filename

                # 添加链接和信息
                index_content.append(f"- [{metadata.name}]({relative_path})")
                index_content.append(f"  - 账户: {metadata.account}")
                index_content.append(f"  - 文件夹: {metadata.folder}")
                index_content.append(f"  - 字符数: {metadata.plaintext_length}")

                if metadata.modification_date:
                    index_content.append(f"  - 修改时间: {metadata.modification_date.strftime('%Y-%m-%d %H:%M')}")

                index_content.append("")

        return "\n".join(index_content)

    def save_metadata_json(self, notes: List) -> None:
        """保存元数据为JSON文件"""
        metadata_list = []

        for note in notes:
            metadata = self.extract_metadata(note)
            metadata_dict = asdict(metadata)

            # 转换日期为字符串
            for key, value in metadata_dict.items():
                if isinstance(value, datetime):
                    metadata_dict[key] = value.isoformat()

            metadata_list.append(metadata_dict)

        metadata_file = self.output_dir / "metadata.json"
        with open(metadata_file, 'w', encoding='utf-8') as f:
            json.dump(metadata_list, f, ensure_ascii=False, indent=2)

        logger.info(f"元数据已保存到: {metadata_file}")

    def print_statistics(self, notes: List) -> None:
        """打印统计信息"""
        table = Table(title="备忘录统计")
        table.add_column("项目", style="cyan")
        table.add_column("数量", style="magenta")

        # 基本统计
        table.add_row("总备忘录数", str(len(notes)))

        # 按账户统计
        accounts = {}
        folders = {}
        password_protected = 0
        total_chars = 0

        for note in notes:
            metadata = self.extract_metadata(note)

            accounts[metadata.account] = accounts.get(metadata.account, 0) + 1
            folders[metadata.folder] = folders.get(metadata.folder, 0) + 1

            if metadata.password_protected:
                password_protected += 1

            total_chars += metadata.plaintext_length

        table.add_row("密码保护", str(password_protected))
        table.add_row("总字符数", f"{total_chars:,}")
        table.add_row("平均字符数", f"{total_chars // len(notes) if notes else 0:,}")

        self.console.print(table)

        # 账户分布
        if len(accounts) > 1:
            account_table = Table(title="账户分布")
            account_table.add_column("账户", style="cyan")
            account_table.add_column("备忘录数", style="magenta")

            for account, count in sorted(accounts.items(), key=lambda x: x[1], reverse=True):
                account_table.add_row(account, str(count))

            self.console.print(account_table)


def parse_arguments():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(
        description="macOS备忘录导出工具 - 支持筛选、分类和批量处理",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 导出所有备忘录
  python3 notes_to_markdown.py

  # 导出最近30天的备忘录
  python3 notes_to_markdown.py --days 30

  # 按关键词搜索并导出
  python3 notes_to_markdown.py --keywords "工作" "项目"

  # 按账户筛选
  python3 notes_to_markdown.py --accounts "iCloud"

  # 按日期分类组织
  python3 notes_to_markdown.py --organize date

  # 导出到指定目录
  python3 notes_to_markdown.py --output /path/to/export
        """
    )

    # 基本选项
    parser.add_argument(
        '--output', '-o',
        default='exported_notes',
        help='输出目录 (默认: exported_notes)'
    )

    parser.add_argument(
        '--organize',
        choices=['flat', 'date', 'account', 'folder', 'length'],
        default='flat',
        help='组织方式 (默认: flat)'
    )

    # 筛选选项
    filter_group = parser.add_argument_group('筛选选项')

    filter_group.add_argument(
        '--keywords', '-k',
        nargs='+',
        help='按关键词筛选 (搜索标题和内容)'
    )

    filter_group.add_argument(
        '--accounts', '-a',
        nargs='+',
        help='按账户筛选'
    )

    filter_group.add_argument(
        '--folders', '-f',
        nargs='+',
        help='按文件夹筛选'
    )

    filter_group.add_argument(
        '--days', '-d',
        type=int,
        help='导出最近N天的备忘录'
    )

    filter_group.add_argument(
        '--start-date',
        help='开始日期 (格式: YYYY-MM-DD)'
    )

    filter_group.add_argument(
        '--end-date',
        help='结束日期 (格式: YYYY-MM-DD)'
    )

    filter_group.add_argument(
        '--min-length',
        type=int,
        default=0,
        help='最小字符数'
    )

    filter_group.add_argument(
        '--max-length',
        type=int,
        help='最大字符数'
    )

    # 输出选项
    output_group = parser.add_argument_group('输出选项')

    output_group.add_argument(
        '--no-index',
        action='store_true',
        help='不生成索引文件'
    )

    output_group.add_argument(
        '--no-metadata',
        action='store_true',
        help='不保存元数据JSON文件'
    )

    output_group.add_argument(
        '--include-protected',
        action='store_true',
        help='包含密码保护的备忘录'
    )

    # 其他选项
    parser.add_argument(
        '--list-only',
        action='store_true',
        help='仅列出符合条件的备忘录，不导出'
    )

    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='详细输出'
    )

    parser.add_argument(
        '--version',
        action='version',
        version='%(prog)s 1.0.0'
    )

    return parser.parse_args()


def parse_date(date_str: str) -> datetime:
    """解析日期字符串"""
    try:
        return datetime.strptime(date_str, '%Y-%m-%d')
    except ValueError:
        raise argparse.ArgumentTypeError(f"无效的日期格式: {date_str} (应为 YYYY-MM-DD)")


def main():
    """主函数"""
    args = parse_arguments()

    # 设置日志级别
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    console = Console()

    try:
        # 初始化处理器
        processor = NotesProcessor(args.output)

        # 连接到备忘录应用
        console.print("🔗 连接到备忘录应用...", style="blue")
        if not processor.connect_to_notes():
            console.print("❌ 连接失败", style="red")
            return 1

        # 获取所有备忘录
        console.print("📱 获取备忘录列表...", style="blue")
        all_notes = processor.get_all_notes()
        if not all_notes:
            console.print("❌ 未找到备忘录", style="red")
            return 1

        console.print(f"✅ 找到 {len(all_notes)} 个备忘录", style="green")

        # 应用筛选条件
        filtered_notes = all_notes

        # 日期筛选
        start_date = None
        end_date = None

        if args.days:
            start_date = datetime.now() - timedelta(days=args.days)

        if args.start_date:
            start_date = parse_date(args.start_date)

        if args.end_date:
            end_date = parse_date(args.end_date)

        if start_date or end_date:
            console.print("📅 按日期筛选...", style="blue")
            filtered_notes = processor.filter_notes_by_date(filtered_notes, start_date, end_date)
            console.print(f"   筛选后: {len(filtered_notes)} 个备忘录", style="yellow")

        # 关键词筛选
        if args.keywords:
            console.print(f"🔍 按关键词筛选: {', '.join(args.keywords)}", style="blue")
            filtered_notes = processor.filter_notes_by_keywords(filtered_notes, args.keywords)
            console.print(f"   筛选后: {len(filtered_notes)} 个备忘录", style="yellow")

        # 账户筛选
        if args.accounts:
            console.print(f"👤 按账户筛选: {', '.join(args.accounts)}", style="blue")
            filtered_notes = processor.filter_notes_by_account(filtered_notes, args.accounts)
            console.print(f"   筛选后: {len(filtered_notes)} 个备忘录", style="yellow")

        # 文件夹筛选
        if args.folders:
            console.print(f"📁 按文件夹筛选: {', '.join(args.folders)}", style="blue")
            filtered_notes = processor.filter_notes_by_folder(filtered_notes, args.folders)
            console.print(f"   筛选后: {len(filtered_notes)} 个备忘录", style="yellow")

        # 长度筛选
        max_length = args.max_length if args.max_length else float('inf')
        if args.min_length > 0 or args.max_length:
            console.print(f"📏 按长度筛选: {args.min_length}-{max_length if max_length != float('inf') else '∞'} 字符", style="blue")
            filtered_notes = processor.filter_notes_by_length(filtered_notes, args.min_length, max_length)
            console.print(f"   筛选后: {len(filtered_notes)} 个备忘录", style="yellow")

        if not filtered_notes:
            console.print("❌ 没有符合条件的备忘录", style="red")
            return 1

        # 显示统计信息
        processor.print_statistics(filtered_notes)

        # 如果只是列出，则退出
        if args.list_only:
            console.print("\n📋 符合条件的备忘录:", style="bold blue")
            for note in filtered_notes:
                metadata = processor.extract_metadata(note)
                console.print(f"  • {metadata.name} ({metadata.account}/{metadata.folder})")
            return 0

        # 开始导出
        console.print(f"\n📤 开始导出 {len(filtered_notes)} 个备忘录...", style="bold green")

        with Progress() as progress:
            task = progress.add_task("导出中...", total=len(filtered_notes))

            def progress_callback(current, total):
                progress.update(task, completed=current)

            results = processor.batch_export(
                filtered_notes,
                args.organize,
                progress_callback
            )

        # 生成索引文件
        if not args.no_index:
            console.print("📑 生成索引文件...", style="blue")
            index_content = processor.generate_index(filtered_notes, args.organize)
            index_file = processor.output_dir / "README.md"
            with open(index_file, 'w', encoding='utf-8') as f:
                f.write(index_content)
            console.print(f"   索引文件: {index_file}", style="yellow")

        # 保存元数据
        if not args.no_metadata:
            console.print("💾 保存元数据...", style="blue")
            processor.save_metadata_json(filtered_notes)

        # 显示结果
        console.print("\n✅ 导出完成!", style="bold green")
        console.print(f"   成功: {results['success']} 个", style="green")
        console.print(f"   失败: {results['failed']} 个", style="red")
        console.print(f"   跳过: {results['skipped']} 个", style="yellow")
        console.print(f"   输出目录: {processor.output_dir.absolute()}", style="cyan")

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
