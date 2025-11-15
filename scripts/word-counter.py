#!/usr/bin/env python3
"""
Word counter and reading time estimator for Zola Markdown posts.

Features
- Counts Chinese characters and English words from Markdown content
- Strips Zola frontmatter (TOML +++ or YAML ---) before counting
- Handles mixed Chinese/English text
- Estimates reading time using language-appropriate speeds
- Pretty terminal output via `rich`

Usage
- Single file:  python3 scripts/word-counter.py <file_path>
- Directory:    python3 scripts/word-counter.py --dir <directory>

Reading speeds
- Chinese: 350 characters/minute
- English: 225 words/minute

Python: 3.7+
"""

from __future__ import annotations

import argparse
import math
import os
import re
import sys
from dataclasses import dataclass
from typing import Optional, Tuple

from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.text import Text


console = Console()


# --- Core logic ------------------------------------------------------------


CHINESE_CHAR_PATTERN = re.compile(r"[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]")
ENGLISH_WORD_PATTERN = re.compile(r"[A-Za-z]+(?:[-'][A-Za-z]+)*")


def _strip_frontmatter(text: str) -> str:
    """Remove Zola-style frontmatter from a Markdown document.

    Supports TOML frontmatter delimited by +++ and YAML delimited by --- at the
    very start of the file. If no valid closing delimiter is found, returns the
    original text unchanged (fail-safe).

    Parameters
    ----------
    text : str
        Full Markdown content including potential frontmatter.

    Returns
    -------
    str
        Markdown content with leading frontmatter removed.
    """
    if not text:
        return text

    # Normalize newlines for robust processing
    if text.startswith("+++\n"):
        end = text.find("\n+++\n", 4)
        if end != -1:
            return text[end + len("\n+++\n") :]
        return text  # no closing; keep as-is

    if text.startswith("---\n"):
        end = text.find("\n---\n", 4)
        if end != -1:
            return text[end + len("\n---\n") :]
        return text  # no closing; keep as-is

    return text


def _strip_markdown(text: str) -> str:
    """Lightweight Markdown-to-text cleanup for word counting.

    This intentionally avoids external dependencies. The goal is not
    perfect Markdown rendering but removing common syntax that would distort
    word counts:

    - Remove fenced code blocks (``` ... ``` and ~~~ ... ~~~)
    - Remove inline code backticks, keep inner text
    - Convert images ![alt](url) to alt text
    - Convert links [text](url) to text
    - Drop HTML tags
    - Remove heading markers (#), blockquotes (>), list markers (-, *, +, digits.)
    - Remove emphasis markers (*, _, ~)

    Parameters
    ----------
    text : str
        Markdown content without frontmatter.

    Returns
    -------
    str
        Simplified plain text suitable for tokenization.
    """
    if not text:
        return text

    # Remove fenced code blocks
    text = re.sub(r"```[\s\S]*?```", "\n", text)
    text = re.sub(r"~~~[\s\S]*?~~~", "\n", text)

    # Strip HTML tags
    text = re.sub(r"<[^>]+>", " ", text)

    # Images: keep alt text
    text = re.sub(r"!\[([^\]]*)\]\([^\)]*\)", r"\1", text)

    # Links: keep link text
    text = re.sub(r"\[([^\]]+)\]\([^\)]*\)", r"\1", text)

    # Inline code backticks
    text = text.replace("`", "")

    # Headers, blockquotes, list markers at line starts
    text = re.sub(r"^\s{0,3}#{1,6}\s*", "", text, flags=re.MULTILINE)
    text = re.sub(r"^\s{0,3}>\s?", "", text, flags=re.MULTILINE)
    text = re.sub(r"^\s{0,3}[-*+]\s+", "", text, flags=re.MULTILINE)
    text = re.sub(r"^\s*\d+\.\s+", "", text, flags=re.MULTILINE)

    # Emphasis markers
    text = text.replace("*", "").replace("_", "").replace("~", "")

    return text


def calculate_word_count(text: str) -> int:
    """Calculate total word count for mixed Chinese/English text.

    Logic
    - Chinese: count Han characters individually.
    - English: count word tokens (letters with optional hyphen/apostrophe groups).
    - Other scripts and numbers are ignored for counting purposes.

    Parameters
    ----------
    text : str
        Plain text (or Markdown; frontmatter should be stripped separately).

    Returns
    -------
    int
        Total count = Chinese characters + English words.
    """
    if not text:
        return 0

    chinese_chars = len(CHINESE_CHAR_PATTERN.findall(text))
    english_words = len(ENGLISH_WORD_PATTERN.findall(text))
    return chinese_chars + english_words


def _count_breakdown(text: str) -> Tuple[int, int, int]:
    """Count with breakdown: (total, chinese_chars, english_words)."""
    if not text:
        return 0, 0, 0
    c = len(CHINESE_CHAR_PATTERN.findall(text))
    e = len(ENGLISH_WORD_PATTERN.findall(text))
    return c + e, c, e


def estimate_reading_time(word_count: int, language: str = "zh") -> str:
    """Estimate reading time string for a given word count.

    Parameters
    ----------
    word_count : int
        Total word count to estimate.
    language : str, optional
        'zh' for Chinese speed (350/min), 'en' for English speed (225/min).
        Default is 'zh'. Any other value falls back to 'zh'.

    Returns
    -------
    str
        Human-friendly Chinese string like "3分钟" or "1小时5分钟".
    """
    speed = 350 if language == "zh" else 225
    if word_count <= 0:
        return "0分钟"
    minutes = max(1, math.ceil(word_count / speed))
    if minutes < 60:
        return f"{minutes}分钟"
    hours = minutes // 60
    rem = minutes % 60
    if rem == 0:
        return f"{hours}小时"
    return f"{hours}小时{rem}分钟"


@dataclass
class AnalysisResult:
    file: str
    word_count: int
    chinese_chars: int
    english_words: int
    language: str  # 'zh' or 'en'
    reading_time: str


def analyze_markdown_file(file_path: str) -> AnalysisResult:
    """Analyze a Markdown file and return word stats and reading time.

    Steps
    - Read UTF-8 file content (gracefully handle BOM and empty files)
    - Strip Zola frontmatter (TOML or YAML)
    - Remove common Markdown syntax to get plain text
    - Count Chinese chars and English words
    - Choose language by majority for reading-time estimation

    Parameters
    ----------
    file_path : str
        Path to a Markdown file.

    Returns
    -------
    AnalysisResult
        Structured statistics for the file.
    """
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            raw = f.read()
    except UnicodeDecodeError:
        # Fallback with replacement to avoid crashing on odd encodings
        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            raw = f.read()

    body = _strip_frontmatter(raw)
    body = _strip_markdown(body)

    total, c, e = _count_breakdown(body)
    lang = "zh" if c >= e else "en"
    rt = estimate_reading_time(total, lang)
    return AnalysisResult(
        file=file_path,
        word_count=total,
        chinese_chars=c,
        english_words=e,
        language=lang,
        reading_time=rt,
    )


# --- CLI -------------------------------------------------------------------


def _print_single(result: AnalysisResult) -> None:
    table = Table(show_header=True, header_style="bold cyan")
    table.add_column("字段")
    table.add_column("值")
    table.add_row("文件", result.file)
    table.add_row("总字数", str(result.word_count))
    table.add_row("中文字符", str(result.chinese_chars))
    table.add_row("英文词数", str(result.english_words))
    table.add_row("估算语言", "中文" if result.language == "zh" else "英文")
    table.add_row("阅读时长", result.reading_time)
    console.print(Panel(table, title="Word Count", expand=False))


def _print_directory(results: list[AnalysisResult], root: str) -> None:
    table = Table(show_header=True, header_style="bold cyan")
    table.add_column("文件")
    table.add_column("总字数", justify="right")
    table.add_column("中文", justify="right")
    table.add_column("英文", justify="right")
    table.add_column("阅读时长", justify="left")

    total_words = 0
    total_c = 0
    total_e = 0

    for r in results:
        rel = os.path.relpath(r.file, root)
        table.add_row(rel, str(r.word_count), str(r.chinese_chars), str(r.english_words), r.reading_time)
        total_words += r.word_count
        total_c += r.chinese_chars
        total_e += r.english_words

    # Summary row
    summary_rt = estimate_reading_time(total_words, "zh" if total_c >= total_e else "en")
    table.add_row("— 合计 —", str(total_words), str(total_c), str(total_e), summary_rt, end_section=True)

    console.print(Panel(table, title=f"目录统计: {root}", expand=False))


def _iter_markdown_files(root: str):
    exts = {".md", ".markdown"}
    for dirpath, _, filenames in os.walk(root):
        for name in filenames:
            if os.path.splitext(name)[1].lower() in exts:
                yield os.path.join(dirpath, name)


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Word count and reading time for Markdown posts (Zola)")
    p.add_argument("file", nargs="?", help="Markdown file to analyze")
    p.add_argument("--dir", dest="directory", help="Directory to scan recursively for Markdown files")
    return p


def main(argv: Optional[list[str]] = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)

    if bool(args.file) == bool(args.directory):
        console.print("[red]请指定单个文件或目录其一：[/]\n"
                      "  单文件: python3 scripts/word-counter.py path/to/file.md\n"
                      "  目录:   python3 scripts/word-counter.py --dir content/")
        return 2

    if args.file:
        if not os.path.isfile(args.file):
            console.print(f"[red]文件不存在:[/] {args.file}")
            return 1
        res = analyze_markdown_file(args.file)
        _print_single(res)
        return 0

    # Directory mode
    root = args.directory
    if not os.path.isdir(root):
        console.print(f"[red]目录不存在:[/] {root}")
        return 1

    results: list[AnalysisResult] = []
    for path in _iter_markdown_files(root):
        try:
            results.append(analyze_markdown_file(path))
        except Exception as exc:  # pylint: disable=broad-except
            console.print(f"[yellow]跳过文件（读取/解析失败）:[/] {path} ({exc})")

    if not results:
        console.print(f"[yellow]未找到 Markdown 文件于目录:[/] {root}")
        return 0

    # Stable order
    results.sort(key=lambda r: r.file)
    _print_directory(results, root)
    return 0


if __name__ == "__main__":
    sys.exit(main())

