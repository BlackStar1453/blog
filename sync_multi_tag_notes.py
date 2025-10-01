#!/usr/bin/env python3
"""
多标签备忘录同步脚本
支持识别多种标签并路由到不同的处理脚本

作者: AI Assistant
版本: 2.0.0
"""

import os
import re
import json
import subprocess
import logging
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional, Set, Tuple
from dataclasses import dataclass

import urllib.request
import urllib.parse

# 加载 .env 文件
def load_env_file(env_path: str = '.env'):
    """加载 .env 文件中的环境变量"""
    if os.path.exists(env_path):
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key.strip()] = value.strip()

# 在导入时加载环境变量
load_env_file()

def check_and_install_dependencies():
    """检查并提示安装依赖库"""
    import sys
    import subprocess

    missing_deps = []

    try:
        import macnotesapp
    except ImportError:
        missing_deps.append("macnotesapp")

    try:
        import rich
    except ImportError:
        missing_deps.append("rich")

    try:
        import markdownify
    except ImportError:
        missing_deps.append("markdownify")

    if missing_deps:
        print(f"❌ 缺少必要的依赖库: {', '.join(missing_deps)}")
        print(f"📍 当前Python路径: {sys.executable}")
        print(f"📍 当前Python版本: {sys.version}")
        print()
        print("🔧 解决方案:")
        print("1. 运行自动安装脚本:")
        print("   ./scripts/setup-dependencies.sh")
        print()
        print("2. 手动安装:")
        print(f"   {sys.executable} -m pip install macnotesapp rich markdownify")
        print()
        print("3. 如果使用Homebrew Python:")
        print("   /opt/homebrew/bin/python3 -m pip install macnotesapp rich markdownify")
        print("   /opt/homebrew/bin/python3 sync_multi_tag_notes.py")
        exit(1)

# 检查依赖
check_and_install_dependencies()

try:
    from macnotesapp import NotesApp
    from rich.console import Console
    from rich.progress import Progress
    from rich.table import Table
    from rich import print as rprint
except ImportError as e:
    print(f"❌ 导入失败: {e}")
    print("请运行依赖安装脚本: ./scripts/setup-dependencies.sh")
    exit(1)

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('multi_tag_sync.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class MastodonPoster:
    """Mastodon 发帖工具（使用标准库实现）"""
    def __init__(self):
        self.raw_base = os.getenv("MASTODON_BASE_URL", "")
        self.token = os.getenv("MASTODON_ACCESS_TOKEN", "")
        self.visibility = os.getenv("MASTODON_VISIBILITY", "direct")

    def _instance_origin(self) -> Optional[str]:
        try:
            if not self.raw_base:
                return None
            # 取协议+域名部分；如果传来带 /home 之类路径，自动截断
            p = urllib.parse.urlparse(self.raw_base)
            if p.scheme and p.netloc:
                return f"{p.scheme}://{p.netloc}"
            # 如果直接是域名或裸路径，做一次兜底
            if self.raw_base.startswith("http"):
                return self.raw_base.rstrip("/")
            return f"https://{self.raw_base.strip('/')}"
        except Exception:
            return None

    def post_status(self, text: str) -> bool:
        origin = self._instance_origin()
        if not origin or not self.token:
            return False
        try:
            endpoint = f"{origin}/api/v1/statuses"
            data = urllib.parse.urlencode({
                "status": text,
                "visibility": self.visibility or "public",
                "language": "zh"
            }).encode("utf-8")
            req = urllib.request.Request(endpoint, data=data, method="POST")
            req.add_header("Authorization", f"Bearer {self.token}")
            req.add_header("Content-Type", "application/x-www-form-urlencoded; charset=utf-8")
            with urllib.request.urlopen(req, timeout=10) as resp:
                return 200 <= resp.status < 300
        except Exception as e:
            logger.warning(f"Mastodon API 调用失败: {e}")
            return False

@dataclass
class TaggedNote:
    """带标签的备忘录数据结构"""
    id: str
    title: str
    content: str
    tags: List[str]
    primary_tag: str
    creation_date: Optional[datetime]
    modification_date: Optional[datetime]
    account: str
    folder: str

@dataclass
class TagHandler:
    """标签处理器配置"""
    type: str
    script: str
    target_path: Optional[str] = None
    target_file: Optional[str] = None
    template: Optional[str] = None
    description: str = ""
    aliases: List[str] = None

class MultiTagSyncer:
    """多标签同步器"""

    def __init__(self, config_file: str = "multi_tag_config.json", no_mastodon: bool = False, hashtags_json_path: Optional[str] = None, delete_original: bool = False, auto_extract: bool = True):
        self.console = Console()
        self.config_file = Path(config_file)
        self.state_file = Path("multi_tag_sync_state.json")
        self.processed_notes: Set[str] = set()
        self.notes_app = None
        self.config = {}
        self.tag_handlers = {}
        self.no_mastodon = no_mastodon
        self.hashtags_json_path = hashtags_json_path
        self.hashtags_map: Dict[str, List[str]] = {}
        self.delete_original = delete_original
        self.auto_extract = auto_extract

        # 加载配置
        self.load_config()

        # 加载已处理的备忘录状态
        self.load_state()

        # 如果启用自动提取且没有提供 hashtags JSON 路径，运行 apple_cloud_notes_parser
        if self.auto_extract and not self.hashtags_json_path:
            self.hashtags_json_path = self._run_apple_cloud_notes_parser()

        # 加载 hashtags 映射（可选）
        if self.hashtags_json_path:
            self._load_hashtags_map()

    def _run_apple_cloud_notes_parser(self) -> Optional[str]:
        """运行 apple_cloud_notes_parser 提取备忘录数据"""
        try:
            import subprocess
            import os
            from pathlib import Path

            parser_dir = Path("apple_cloud_notes_parser")
            if not parser_dir.exists():
                logger.warning("apple_cloud_notes_parser 目录不存在，跳过自动提取")
                return None

            self.console.print("🔍 正在运行 Apple Cloud Notes Parser 提取备忘录数据...", style="blue")

            # 备忘录数据路径
            notes_path = Path.home() / "Library/Group Containers/group.com.apple.notes"
            if not notes_path.exists():
                logger.warning(f"备忘录数据路径不存在: {notes_path}")
                return None

            # 保存原始工作目录
            original_cwd = os.getcwd()

            # 获取绝对路径
            parser_dir_abs = parser_dir.resolve()

            try:
                # 设置 Ruby 路径（如果使用 Homebrew）
                env = os.environ.copy()
                if Path("/opt/homebrew/opt/ruby/bin").exists():
                    env["PATH"] = f"/opt/homebrew/opt/ruby/bin:{env.get('PATH', '')}"

                # 运行 notes_cloud_ripper.rb（在parser目录中）
                cmd = [
                    "ruby",
                    str(parser_dir_abs / "notes_cloud_ripper.rb"),
                    "--mac", str(notes_path),
                    "--one-output-folder"
                ]

                result = subprocess.run(
                    cmd,
                    env=env,
                    capture_output=True,
                    text=True,
                    timeout=300,  # 5分钟超时
                    cwd=str(parser_dir_abs)  # 在parser目录中执行
                )

                if result.returncode != 0:
                    logger.error(f"apple_cloud_notes_parser 执行失败: {result.stderr}")
                    return None

                # 查找生成的 JSON 文件（使用绝对路径）
                json_dir = parser_dir_abs / "output/notes_rip/json"
                if json_dir.exists():
                    json_files = list(json_dir.glob("all_notes_*.json"))
                    if json_files:
                        # 按修改时间排序,使用最新的文件
                        json_file = sorted(json_files, key=lambda p: p.stat().st_mtime, reverse=True)[0]
                        self.console.print(f"✅ 成功提取备忘录数据: {json_file}", style="green")
                        return str(json_file)

                logger.warning("未找到生成的 JSON 文件")
                return None

            except Exception as e:
                logger.error(f"执行过程中出错: {e}")
                return None

        except subprocess.TimeoutExpired:
            logger.error("apple_cloud_notes_parser 执行超时")
            return None
        except Exception as e:
            logger.error(f"运行 apple_cloud_notes_parser 失败: {e}")
            return None

    def load_config(self) -> None:
        """加载配置文件"""
        if not self.config_file.exists():
            logger.error(f"配置文件不存在: {self.config_file}")
            raise FileNotFoundError(f"配置文件不存在: {self.config_file}")

        try:
            with open(self.config_file, 'r', encoding='utf-8') as f:
                self.config = json.load(f)

            # 解析标签处理器
            for tag, handler_config in self.config.get('tag_handlers', {}).items():
                self.tag_handlers[tag.lower()] = TagHandler(
                    type=handler_config.get('type'),
                    script=handler_config.get('script'),
                    target_path=handler_config.get('target_path'),
                    target_file=handler_config.get('target_file'),
                    template=handler_config.get('template'),
                    description=handler_config.get('description', ''),
                    aliases=[alias.lower() for alias in handler_config.get('aliases', [])]
                )

            logger.info(f"配置加载成功，支持 {len(self.tag_handlers)} 种标签类型")

        except Exception as e:
            logger.error(f"加载配置文件失败: {e}")
            raise

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

    def clean_state(self, current_note_ids: Set[str]) -> None:
        """清理状态文件中已不存在的备忘录 ID"""
        try:
            removed = self.processed_notes - current_note_ids
            if removed:
                logger.info(f"清理 {len(removed)} 个已删除备忘录的状态")
                self.processed_notes = self.processed_notes & current_note_ids
                self.save_state()
        except Exception as e:
            logger.error(f"清理状态失败: {e}")

    def _load_hashtags_map(self) -> None:
        """从 apple_cloud_notes_parser 的 all_notes_*.json 读取 hashtags 映射"""
        try:
            p = Path(self.hashtags_json_path)
            if not p.exists():
                logger.warning(f"hashtags JSON 不存在: {p}")
                return
            with p.open('r', encoding='utf-8') as f:
                data = json.load(f)
            notes = data.get('notes') or {}
            count = 0
            skipped_deleted = 0
            for key, note_obj in notes.items():
                # 跳过已删除或在废纸篓中的备忘录
                if note_obj.get('trashed') or note_obj.get('deleted'):
                    skipped_deleted += 1
                    continue

                hashtags = note_obj.get('hashtags') or []
                if not hashtags:
                    continue
                norm = [f"#{str(t).strip().lstrip('#').lower()}" for t in hashtags if str(t).strip()]
                keys = set()
                keys.add(str(key))
                for k in ('note_id', 'uuid', 'identifier', 'ZIDENTIFIER'):
                    v = note_obj.get(k)
                    if v:
                        keys.add(str(v))
                for k in keys:
                    self.hashtags_map[k] = norm
                count += 1
            logger.info(f"加载 JSON hashtags 映射完成：{count} 条 (跳过已删除: {skipped_deleted})")
        except Exception as e:
            logger.warning(f"加载 JSON hashtags 失败: {e}")

    def _read_site_base_url(self) -> str:
        """从 config.toml 读取 base_url，用于构造文章链接"""
        try:
            cfg = Path("config.toml")
            if not cfg.exists():
                return ""
            text = cfg.read_text(encoding="utf-8", errors="ignore")
            m = re.search(r'^base_url\s*=\s*"([^"]+)"', text, flags=re.MULTILINE)
            return m.group(1).rstrip('/') if m else ""
        except Exception:
            return ""

    def _convert_content_path_to_url(self, created_file_path: Optional[str]) -> Optional[str]:
        """将 content 下生成的 .md 文件路径转换为站点 URL"""
        if not created_file_path:
            return None
        try:
            norm = os.path.normpath(created_file_path)
            parts = norm.split(os.sep)
            if "content" not in parts:
                return None
            idx = parts.index("content")
            rel_parts = parts[idx + 1:]
            rel = "/".join(rel_parts)
            if rel.lower().endswith(".md"):
                rel = rel[:-3]
            if rel.endswith("/index"):
                rel = rel[:-len("/index")]
            rel = rel.strip("/")
            url_path = f"/{rel}/" if rel else "/"
            base = getattr(self, "site_base_url", "")
            return f"{base}{url_path}" if base else url_path
        except Exception:
            return None

    def _should_post_to_mastodon(self, tags: List[str]) -> bool:
        """仅当包含 #cmx 标签时才允许推送 Mastodon"""
        try:
            # 直接检查原始标签格式 #cmx
            return any((t or '').strip().lower() == '#cmx' for t in (tags or []))
        except Exception:
            return False

    def _has_tag(self, tags: List[str], name: str) -> bool:
        try:
            target = name.strip().lower()
            if not target.startswith('#'):
                target = f"#{target}"
            return any((t or '').strip().lower() == target for t in (tags or []))
        except Exception:
            return False

    def _ensure_markdown_draft(self, file_path: Optional[str]) -> None:
        """在生成的 Markdown 文件 frontmatter 中标记 draft（支持 YAML '---' 与 TOML '+++')."""
        if not file_path:
            return
        p = Path(file_path)
        if not p.exists() or p.suffix.lower() != '.md':
            return
        try:
            text = p.read_text(encoding='utf-8', errors='replace')
            if text.startswith('---'):
                # YAML
                end = text.find('\n---', 3)
                if end != -1:
                    head = text[0:end+4]
                    body = text[end+4:]
                    if re.search(r'^\s*draft\s*:', head, flags=re.IGNORECASE | re.MULTILINE):
                        head = re.sub(r'^(\s*draft\s*:\s*).*$', r'\1true', head, flags=re.IGNORECASE | re.MULTILINE)
                    else:
                        head = head[:-4] + "\ndraft: true\n---"
                    p.write_text(head + body, encoding='utf-8')
                    return
            if text.startswith('+++'):
                # TOML
                end = text.find('\n+++', 3)
                if end != -1:
                    head = text[0:end+4]
                    body = text[end+4:]
                    if re.search(r'^\s*draft\s*=\s*', head, flags=re.IGNORECASE | re.MULTILINE):
                        head = re.sub(r'^(\s*draft\s*=\s*).*$', r'\1true', head, flags=re.IGNORECASE | re.MULTILINE)
                    else:
                        head = head[:-4] + "\ndraft = true\n+++"
                    p.write_text(head + body, encoding='utf-8')
                    return
            # 若没有 frontmatter，则补充 YAML 简单头
            fm = "---\ndraft: true\n---\n\n"
            p.write_text(fm + text, encoding='utf-8')
        except Exception as e:
            logger.warning(f"为 Markdown 标记 draft 失败: {e}")

    def _build_article_status_text(self, title: str, content: str, url: Optional[str]) -> str:
        excerpt = re.sub(r"\s+", " ", content).strip()[:100]
        suffix = f"\n{url}" if url else ""
        text = f"{title}\n\n{excerpt}{'…' if len(content) > 100 else ''}{suffix}"
        # 限制长度，留余量
        return text[:480]

    def _post_to_mastodon(self, note_type: str, title: str, content: str, created_file_path: Optional[str]) -> None:
        """根据类型发帖到 Mastodon。thought 直接发内容，其他类型发 摘要+URL"""
        try:
            if not hasattr(self, "mastodon_poster"):
                self.mastodon_poster = MastodonPoster()
            if note_type == "thought":
                text = re.sub(r"\s+", " ", content).strip()[:480]
                if not text:
                    return
                ok = self.mastodon_poster.post_status(text)
                logger.info("Mastodon: 已发布 thought 帖子" if ok else "Mastodon: thought 发布失败")
            else:
                if not hasattr(self, "site_base_url"):
                    self.site_base_url = self._read_site_base_url()
                url = self._convert_content_path_to_url(created_file_path)
                text = self._build_article_status_text(title, content, url)
                if not text:
                    return
                ok = self.mastodon_poster.post_status(text)
                logger.info("Mastodon: 已发布文章摘要" if ok else "Mastodon: 文章摘要发布失败")
        except Exception as e:
            logger.warning(f"Mastodon 推送异常: {e}")

    def connect_to_notes(self) -> bool:
        """连接到备忘录应用"""
        try:
            self.notes_app = NotesApp()
            logger.info("成功连接到备忘录应用")
            return True
        except Exception as e:
            logger.error(f"连接备忘录应用失败: {e}")
            return False

    def _delete_note_by_id(self, note_id: str) -> bool:
        """通过 AppleScript 按 id 删除备忘录（移动到废纸篓）。"""
        if not note_id:
            return False
        try:
            script = f'''tell application "Notes"
try
    set theNote to first note whose id is "{note_id}"
    delete theNote
    return "OK"
on error errMsg
    return "ERR:" & errMsg
end try
end tell'''
            result = subprocess.run([
                "osascript", "-e", script
            ], capture_output=True, text=True, encoding='utf-8')
            out = (result.stdout or "").strip()
            if result.returncode == 0 and out == "OK":
                logger.info(f"已删除备忘录: {note_id}")
                return True
            logger.warning(f"删除备忘录失败: {note_id} out={out} err={result.stderr}")
            return False
        except Exception as e:
            logger.warning(f"删除备忘录异常: {e}")
            return False

    # 已移除 extract_tags_from_content 方法
    # 根据设计要求，标签只应从备忘录元数据字段中提取，不从正文内容解析

    def extract_tags_from_note(self, note) -> List[str]:
        """
        从备忘录的元数据字段中提取标签。

        设计说明：
        1. 优先使用 Apple Cloud Notes Parser 提供的 JSON hashtags 数据
        2. 如果没有 JSON 数据，则尝试从备忘录对象的元数据字段中提取
        3. 不从正文内容中解析标签 - 如果元数据中没有标签，说明该备忘录不需要处理

        返回：标签列表，如果没有找到标签则返回空列表
        """
        # 如提供 JSON 映射，则仅按映射取值
        if getattr(self, 'hashtags_map', None):
            try:
                candidate_keys: List[str] = []
                for attr in ('id', 'uuid', 'identifier', 'ZIDENTIFIER', 'guid'):
                    v = getattr(note, attr, None)
                    if v:
                        s = str(v)
                        candidate_keys.append(s)
                        m = re.search(r'/ICNote/p(\d+)$', s)
                        if m:
                            candidate_keys.append(m.group(1))
                d = getattr(note, 'asdict', None)
                if callable(d):
                    data = note.asdict() or {}
                    for k in ('note_id', 'uuid', 'identifier', 'ZIDENTIFIER'):
                        v = data.get(k)
                        if v:
                            candidate_keys.append(str(v))
                for k in candidate_keys:
                    if k in self.hashtags_map and self.hashtags_map[k]:
                        tags = [str(t).strip() for t in self.hashtags_map[k] if str(t).strip()]
                        if tags:
                            logger.debug("已从 JSON hashtags 获取标签")
                            return tags
                return []
            except Exception as e:
                logger.debug(f"读取 JSON hashtags 异常：{e}")
                return []

        # 未提供 JSON：仅尝试元数据字段（不再回退正文）
        tags: List[str] = []
        try:
            d = getattr(note, 'asdict', None)
            if callable(d):
                data = note.asdict() or {}
                for key in ("tags", "hashtags", "note_tags", "labels"):
                    v = data.get(key)
                    if isinstance(v, (list, tuple)):
                        tags = [f"#{str(t).strip().lstrip('#').lower()}" for t in v if str(t).strip()]
                        if tags:
                            break
            if not tags:
                for attr in ("tags", "hashtags", "note_tags", "labels"):
                    if hasattr(note, attr):
                        v = getattr(note, attr)
                        if isinstance(v, (list, tuple)):
                            tags = [f"#{str(t).strip().lstrip('#').lower()}" for t in v if str(t).strip()]
                            if tags:
                                break
        except Exception as e:
            logger.debug(f"从元数据提取标签异常：{e}")
        return tags

    def resolve_tag_handler(self, tag: str) -> Optional[TagHandler]:
        """解析标签对应的处理器"""
        tag_lower = tag.lower()

        # 直接匹配
        if tag_lower in self.tag_handlers:
            return self.tag_handlers[tag_lower]

        # 别名匹配
        for handler_tag, handler in self.tag_handlers.items():
            if handler.aliases and tag_lower in handler.aliases:
                return handler

        return None

    def get_primary_tag(self, tags: List[str]) -> str:
        """根据优先级获取主要标签"""
        priority_order = self.config.get('processing_options', {}).get('priority_order', [])

        # 按优先级排序
        for priority_tag in priority_order:
            for tag in tags:
                if tag.lower() == priority_tag.lower():
                    return tag

                # 检查别名
                handler = self.resolve_tag_handler(tag)
                if handler and priority_tag.lower() in [handler_tag.lower() for handler_tag in self.tag_handlers.keys()]:
                    return tag

        # 如果没有匹配优先级，返回第一个标签
        return tags[0] if tags else ""

    def extract_tagged_note(self, note) -> Optional[TaggedNote]:
        """提取带标签的备忘录内容"""
        try:
            # 获取备忘录的纯文本内容
            content = getattr(note, 'plaintext', '') or getattr(note, 'body', '')
            if not content:
                return None

            # 提取标签（优先使用备忘录元数据中的 tag 字段，回退到正文 #tag 解析）
            tags = self.extract_tags_from_note(note)
            if not tags:
                return None

            # 获取主要标签
            primary_tag = self.get_primary_tag(tags)

            # 创建标签备忘录对象
            tagged_note = TaggedNote(
                id=getattr(note, 'id', 'unknown'),
                title=getattr(note, 'name', '无标题'),
                content=content,
                tags=tags,
                primary_tag=primary_tag,
                creation_date=getattr(note, 'creation_date', None),
                modification_date=getattr(note, 'modification_date', None),
                account=getattr(note, 'account', '未知账户'),
                folder=getattr(note, 'folder', '未知文件夹')
            )

            return tagged_note

        except Exception as e:
            logger.warning(f"提取备忘录内容失败: {e}")
            return None

    def clean_content(self, content: str, tags: List[str]) -> str:
        """清理内容，移除标签并格式化"""
        cleaned_content = content

        # 移除标签
        if self.config.get('processing_options', {}).get('content_processing', {}).get('remove_tags', True):
            for tag in tags:
                # 移除标签（不区分大小写）
                pattern = re.escape(tag)
                cleaned_content = re.sub(pattern, '', cleaned_content, flags=re.IGNORECASE)

        # 清理多余的空行
        if self.config.get('processing_options', {}).get('content_processing', {}).get('clean_whitespace', True):
            cleaned_content = re.sub(r'\n\s*\n\s*\n', '\n\n', cleaned_content)
            cleaned_content = cleaned_content.strip()
        return cleaned_content

    def _slugify(self, text: str) -> str:
        s = (text or "").strip().lower()
        s = re.sub(r"\s+", "-", s)
        # 保留中文、字母数字、连字符和下划线
        s = re.sub(r"[^a-z0-9\-_\u4e00-\u9fff]", "", s)
        return s[:60] or "post"

    def format_date_for_script(self, date: Optional[datetime]) -> Optional[str]:
        """格式化日期为脚本可接受的格式"""
        if not date:
            return None
        return date.strftime("%Y-%m-%d %H:%M")

    def call_handler_script(self, handler: TagHandler, content: str, tagged_note: TaggedNote) -> Tuple[bool, Optional[str]]:
        """调用标签处理脚本，返回 (是否成功, 生成的content文件路径[如果可解析])"""
        try:
            script_path = Path(handler.script)
            if not script_path.exists():
                logger.error(f"处理脚本不存在: {script_path}")
                return False, None

            # 构建命令参数
            cmd = [str(script_path)]

            # 根据处理器类型添加不同的参数
            if handler.type == "thought":
                # thought类型：内容 + 时间
                cmd.append(content)
                date_str = self.format_date_for_script(
                    tagged_note.modification_date or tagged_note.creation_date
                )
                if date_str:
                    cmd.append(date_str)
            else:
                # 其他类型：标题 + 内容（通过stdin传递）
                cmd.append(tagged_note.title)

            # 执行脚本
            if handler.type == "thought":
                result = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    encoding='utf-8',
                    errors='replace',
                    cwd=Path.cwd()
                )
            else:
                result = subprocess.run(
                    cmd,
                    input=content,
                    capture_output=True,
                    text=True,
                    encoding='utf-8',
                    errors='replace',
                    cwd=Path.cwd()
                )

            created_path = None
            if result.stdout:
                m = re.search(r'(content/[^\s]+?\.md)', result.stdout)
                if m:
                    created_path = os.path.normpath(m.group(1))

            if result.returncode == 0:
                logger.info(f"成功处理 {handler.type}: {tagged_note.title[:50]}...")
                return True, created_path
            else:
                logger.error(f"处理 {handler.type} 失败: {result.stderr}")
                return False, None

        except Exception as e:
            logger.error(f"调用处理脚本失败: {e}")
            return False, None

    def process_default_handler(self, content: str, tagged_note: TaggedNote) -> Tuple[bool, Optional[str]]:
        """未知标签：生成一篇 blog 文章（categories: 文章；tags: 包含原始标签）"""
        try:
            title = tagged_note.title or "无标题"
            date = tagged_note.modification_date or tagged_note.creation_date or datetime.now()
            # 使用完整的 ISO 8601 格式
            date_str = date.strftime("%Y-%m-%dT%H:%M:%S+08:00")
            updated_str = date.strftime("%Y-%m-%d")
            slug = self._slugify(title) or date.strftime("%Y%m%d%H%M")
            out_dir = Path("content/blog")
            out_dir.mkdir(parents=True, exist_ok=True)
            filename = f"{date.strftime('%Y-%m-%d')}-{slug}.md"
            out_path = out_dir / filename

            tags = []
            for t in (tagged_note.tags or []):
                tnorm = str(t).strip()
                if not tnorm:
                    continue
                tnorm = tnorm.lstrip('#')
                if tnorm not in tags:
                    tags.append(tnorm)
            if "文章" not in tags:
                tags.insert(0, "文章")

            draft_line = "draft: true\n" if self._has_tag(tagged_note.tags, '#draft') else ""
            fm = (
                "---\n"
                f"title: \"{title}\"\n"
                f"date: {date_str}\n"
                f"updated: {updated_str}\n"
                f"{draft_line}"
                "taxonomies:\n"
                "  categories:\n"
                "    - 文章\n"
                "  tags:\n" +
                "".join([f"    - {t}\n" for t in tags]) +
                "---\n\n"
            )
            body = fm + content.strip() + "\n"
            out_path.write_text(body, encoding='utf-8')
            logger.info(f"默认处理：已生成 blog 文章 {out_path}")
            return True, str(out_path)
        except Exception as e:
            logger.error(f"默认处理失败: {e}")
            return False, None

    def get_tagged_notes(self) -> List[TaggedNote]:
        """获取所有带标签的备忘录"""
        if not self.notes_app:
            raise RuntimeError("未连接到备忘录应用")

        tagged_notes = []

        try:
            all_notes = self.notes_app.notes()
            logger.info(f"扫描 {len(all_notes)} 个备忘录...")

            for note in all_notes:
                tagged_note = self.extract_tagged_note(note)
                if tagged_note:
                    tagged_notes.append(tagged_note)

            logger.info(f"找到 {len(tagged_notes)} 个带标签的备忘录")
            return tagged_notes

        except Exception as e:
            logger.error(f"获取带标签备忘录失败: {e}")
            return []

    def sync_notes(self, force: bool = False) -> Dict[str, int]:
        """同步带标签的备忘录"""
        results = {'success': 0, 'skipped': 0, 'failed': 0, 'unknown_tags': 0}

        # 获取带标签的备忘录
        tagged_notes = self.get_tagged_notes()

        if not tagged_notes:
            self.console.print("❌ 没有找到带标签的备忘录", style="yellow")
            return results

        # 清理状态文件中已删除的备忘录
        current_note_ids = {note.id for note in tagged_notes}
        self.clean_state(current_note_ids)

        # 处理每个带标签的备忘录
        with Progress() as progress:
            task = progress.add_task("同步中...", total=len(tagged_notes))

            for tagged_note in tagged_notes:
                progress.update(task, advance=1)

                # 检查是否已经处理过
                if not force and tagged_note.id in self.processed_notes:
                    logger.debug(f"跳过已处理的备忘录: {tagged_note.title}")
                    results['skipped'] += 1
                    continue

                # 清理内容
                cleaned_content = self.clean_content(tagged_note.content, tagged_note.tags)
                if not cleaned_content:
                    logger.warning(f"备忘录内容为空: {tagged_note.title}")
                    results['skipped'] += 1
                    continue

                # 获取主要标签的处理器
                handler = self.resolve_tag_handler(tagged_note.primary_tag)

                success, created_path = False, None
                note_type = None
                if handler:
                    # 使用对应的处理器
                    success, created_path = self.call_handler_script(handler, cleaned_content, tagged_note)
                    note_type = handler.type
                    if success:
                        self.console.print(
                            f"✅ 已同步 [{handler.type}]: {tagged_note.title[:30]}...",
                            style="green"
                        )
                else:
                    # 使用默认处理器
                    success, created_path = self.process_default_handler(cleaned_content, tagged_note)
                    note_type = 'thought'
                    if success:
                        results['unknown_tags'] += 1
                        self.console.print(
                            f"⚠️  未知标签，使用默认处理: {tagged_note.title[:30]}...",
                            style="yellow"
                        )

                if success:
                    # 若标记为草稿，则给生成的 Markdown 标记 draft: true
                    if created_path and self._has_tag(tagged_note.tags, '#draft'):
                        self._ensure_markdown_draft(created_path)

                    # 成功后尝试推送到 Mastodon（失败不影响流程）
                    if not self.no_mastodon and self._should_post_to_mastodon(tagged_note.tags):
                        try:
                            self._post_to_mastodon(note_type or 'thought', tagged_note.title, cleaned_content, created_path)
                        except Exception as e:
                            logger.warning(f"Mastodon 推送失败（忽略）：{e}")
                    else:
                        logger.info("跳过 Mastodon 发布（未包含 #cmx 或 --no-mastodon 已启用）")

                    self.processed_notes.add(tagged_note.id)
                    results['success'] += 1

                    # 成功后删除源备忘录（受 --delete-original 控制）
                    if self.delete_original:
                        try:
                            if self._delete_note_by_id(tagged_note.id):
                                logger.info(f"已清理源备忘录: {tagged_note.title[:50]}")
                            else:
                                logger.warning(f"未能删除源备忘录（将保留）: {tagged_note.title[:50]}")
                        except Exception as e:
                            logger.warning(f"删除源备忘录异常: {e}")
                    else:
                        logger.debug("未开启 --delete-original，保留源备忘录")
                else:
                    results['failed'] += 1
                    self.console.print(
                        f"❌ 同步失败: {tagged_note.title[:30]}...",
                        style="red"
                    )

        # 保存状态
        self.save_state()

        return results

    def list_tagged_notes(self) -> None:
        """列出所有带标签的备忘录"""
        tagged_notes = self.get_tagged_notes()

        if not tagged_notes:
            self.console.print("❌ 没有找到带标签的备忘录", style="yellow")
            return

        # 按标签类型分组
        notes_by_type = {}
        for note in tagged_notes:
            handler = self.resolve_tag_handler(note.primary_tag)
            note_type = handler.type if handler else "unknown"

            if note_type not in notes_by_type:
                notes_by_type[note_type] = []
            notes_by_type[note_type].append(note)

        self.console.print(f"\n📋 找到 {len(tagged_notes)} 个带标签的备忘录:\n", style="bold blue")

        for note_type, notes in notes_by_type.items():
            # 创建表格
            table = Table(title=f"{note_type.upper()} ({len(notes)} 个)")
            table.add_column("标题", style="cyan", no_wrap=False)
            table.add_column("标签", style="magenta")
            table.add_column("状态", style="green")
            table.add_column("修改时间", style="dim")

            for note in notes:
                status = "✅ 已处理" if note.id in self.processed_notes else "⏳ 待处理"
                mod_time = note.modification_date.strftime('%Y-%m-%d %H:%M') if note.modification_date else "未知"

                table.add_row(
                    note.title[:40] + "..." if len(note.title) > 40 else note.title,
                    ", ".join(note.tags),
                    status,
                    mod_time
                )

            self.console.print(table)
            self.console.print()

    def list_supported_tags(self) -> None:
        """列出支持的标签类型"""
        self.console.print("\n🏷️  支持的标签类型:\n", style="bold blue")

        table = Table()
        table.add_column("标签", style="cyan")
        table.add_column("类型", style="magenta")
        table.add_column("描述", style="white")
        table.add_column("别名", style="dim")

        for tag, handler in self.tag_handlers.items():
            aliases = ", ".join(handler.aliases) if handler.aliases else "无"
            table.add_row(
                tag,
                handler.type,
                handler.description,
                aliases
            )

        self.console.print(table)

        # 显示默认处理器
        default_config = self.config.get('default_handler', {})
        if default_config:
            self.console.print(f"\n🔧 默认处理器: {default_config.get('description', '未知')}", style="yellow")

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
        description="同步macOS备忘录中带标签的内容到对应的笔记类型",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 同步新的带标签备忘录
  python3 sync_multi_tag_notes.py

  # 列出所有带标签的备忘录
  python3 sync_multi_tag_notes.py --list

  # 列出支持的标签类型
  python3 sync_multi_tag_notes.py --tags

  # 强制重新同步所有备忘录
  python3 sync_multi_tag_notes.py --force

  # 重置处理状态
  python3 sync_multi_tag_notes.py --reset
        """
    )

    parser.add_argument(
        '--list', '-l',
        action='store_true',
        help='列出所有带标签的备忘录'
    )

    parser.add_argument(
        '--tags', '-t',
        action='store_true',
        help='列出支持的标签类型'
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
        '--config', '-c',
        default='multi_tag_config.json',
        help='配置文件路径'
    )

    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='详细输出'
    )

    parser.add_argument(
        '--no-mastodon',
        action='store_true',
        help='跳过 Mastodon 发布'
    )
    parser.add_argument(
        '--hashtags-json',
        default=None,
        help='apple_cloud_notes_parser 导出的 all_notes_*.json 路径，用于优先读取 hashtags'
    )

    parser.add_argument(
        '--no-auto-extract',
        action='store_true',
        help='禁用自动运行 apple_cloud_notes_parser 提取备忘录数据'
    )

    # 删除开关：默认不删除；--delete-original 开启删除；--no-delete-original 关闭
    delete_group = parser.add_mutually_exclusive_group()
    delete_group.add_argument('--delete-original', dest='delete_original', action='store_true', help='成功处理后删除原始备忘录（移入废纸篓）')
    delete_group.add_argument('--no-delete-original', dest='delete_original', action='store_false', help='成功处理后保留原始备忘录（默认）')
    parser.set_defaults(delete_original=False)

    args = parser.parse_args()

    # 设置日志级别
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    console = Console()

    try:
        # 初始化同步器
        syncer = MultiTagSyncer(
            config_file=args.config,
            no_mastodon=args.no_mastodon,
            hashtags_json_path=args.hashtags_json,
            delete_original=args.delete_original,
            auto_extract=not args.no_auto_extract
        )

        # 重置状态
        if args.reset:
            syncer.reset_state()
            return 0

        # 列出支持的标签
        if args.tags:
            syncer.list_supported_tags()
            return 0

        # 连接到备忘录应用
        console.print("🔗 连接到备忘录应用...", style="blue")
        if not syncer.connect_to_notes():
            console.print("❌ 连接失败", style="red")
            return 1

        # 列出备忘录
        if args.list:
            syncer.list_tagged_notes()
            return 0

        # 同步备忘录
        console.print("🔄 开始同步带标签的备忘录...", style="bold green")
        results = syncer.sync_notes(force=args.force)

        # 显示结果
        console.print("\n✅ 同步完成!", style="bold green")
        console.print(f"   成功: {results['success']} 个", style="green")
        console.print(f"   跳过: {results['skipped']} 个", style="yellow")
        console.print(f"   失败: {results['failed']} 个", style="red")
        if results['unknown_tags'] > 0:
            console.print(f"   未知标签: {results['unknown_tags']} 个", style="cyan")

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
