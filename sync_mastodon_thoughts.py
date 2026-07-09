#!/usr/bin/env python3
"""
Mastodon 嘟文同步到博客 Thoughts 的脚本
从 Mastodon 获取指定时间范围的原创嘟文，添加到 content/thoughts/index.md
"""

import os
import re
import json
import argparse
import requests
from datetime import datetime, timezone
from pathlib import Path
from html.parser import HTMLParser
from mastodon import Mastodon
from dotenv import load_dotenv
from urllib.parse import urlparse

# HTML 转纯文本的解析器
class HTMLTextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.text = []

    def handle_data(self, data):
        self.text.append(data)

    def get_text(self):
        return ''.join(self.text)

def html_to_text(html_content):
    """将 HTML 转换为纯文本"""
    parser = HTMLTextExtractor()
    parser.feed(html_content)
    text = parser.get_text()
    # 清理多余空行
    text = re.sub(r'\n\s*\n\s*\n+', '\n\n', text)
    return text.strip()

def load_sync_state():
    """加载同步状态"""
    state_file = Path('mastodon_sync_state.json')
    if state_file.exists():
        with open(state_file, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {'synced_ids': [], 'last_sync': None}

def save_sync_state(state):
    """保存同步状态"""
    state_file = Path('mastodon_sync_state.json')
    with open(state_file, 'w', encoding='utf-8') as f:
        json.dump(state, f, ensure_ascii=False, indent=2)

def contains_mention(content):
    """检查内容是否包含 @ 提及"""
    # 检查是否包含 @username 格式
    return bool(re.search(r'@\w+', content))

def download_image(image_url, image_dir, filename):
    """下载图片到本地"""
    try:
        image_dir.mkdir(parents=True, exist_ok=True)
        image_path = image_dir / filename

        # 如果已存在，跳过下载
        if image_path.exists():
            print(f"    图片已存在: {filename}")
            return image_path

        print(f"    下载图片: {filename}")
        response = requests.get(image_url, timeout=30)
        response.raise_for_status()

        with open(image_path, 'wb') as f:
            f.write(response.content)

        return image_path
    except Exception as e:
        print(f"    下载图片失败 {image_url}: {e}")
        return None

def format_thought_entry(content, date_str, images=None):
    """格式化为 thought 条目，支持图片"""
    lines = content.split('\n')
    formatted_lines = []

    for line in lines:
        if line.strip():
            formatted_lines.append(f"> {line}")
        else:
            formatted_lines.append('>')

    # 添加图片（如果有）
    if images:
        formatted_lines.append('>')
        for img_path in images:
            # 转换为相对于 content/thoughts 的路径
            # 图片在 static/images/mastodon/
            # 从 thoughts 引用需要使用 /images/mastodon/
            img_name = img_path.name
            formatted_lines.append(f"> ![image](/images/mastodon/{img_name})")

    formatted_lines.append('>')
    formatted_lines.append(f"> - {date_str}")

    return '\n'.join(formatted_lines)

def insert_thoughts_to_file(thoughts_by_date, thoughts_file):
    """将新的 thoughts 插入到文件中，按年份组织。

    若目标年份的 `## 年份` 标题已存在，则把新条目插入到该标题正下方
    （增量同步拉取的都是更新的内容，置于该年份区块顶部即保持日期倒序）；
    否则按年份倒序在正确位置新建标题。这样可避免出现重复的年份标题。
    """
    with open(thoughts_file, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.split('\n')

    # 找到 frontmatter 的结束位置
    frontmatter_end = 0
    dash_count = 0
    for i, line in enumerate(lines):
        if line.strip() == '---':
            dash_count += 1
            if dash_count == 2:
                frontmatter_end = i + 1
                break

    # 按年份组织新 thoughts（thoughts_by_date 已按日期倒序，年份内条目也随之倒序）
    thoughts_by_year = {}
    for date_key, thought_list in sorted(thoughts_by_date.items(), reverse=True):
        year = datetime.strptime(date_key, '%Y.%m.%d').year
        thoughts_by_year.setdefault(year, []).extend(thought_list)

    # 逐年插入（从最新年份开始）
    for year in sorted(thoughts_by_year.keys(), reverse=True):
        # 构建该年份的新条目块（每条后跟一个空行）
        block = []
        for thought in thoughts_by_year[year]:
            block.append(thought)
            block.append('')

        heading = f"## {year}"

        # 查找已存在的同年份标题
        existing_idx = None
        for i, line in enumerate(lines):
            if line.strip() == heading:
                existing_idx = i
                break

        if existing_idx is not None:
            # 已存在：插入到标题正下方（跳过标题后紧邻的一个空行）
            insert_at = existing_idx + 1
            if insert_at < len(lines) and lines[insert_at].strip() == '':
                insert_at += 1
            lines[insert_at:insert_at] = block
        else:
            # 不存在：在第一个更小年份标题之前新建（保持年份倒序）
            new_block = [heading, ''] + block
            target = None
            for i in range(frontmatter_end, len(lines)):
                m = re.match(r'^##\s+(\d{4})\s*$', lines[i])
                if m and int(m.group(1)) < year:
                    target = i
                    break
            if target is not None:
                lines[target:target] = new_block
            else:
                # 没有更小的年份，追加到文件末尾
                if lines and lines[-1].strip() != '':
                    lines.append('')
                lines.extend(new_block)

    # 写回文件
    with open(thoughts_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))

def main():
    # 解析命令行参数
    parser = argparse.ArgumentParser(description='同步 Mastodon 嘟文到博客 Thoughts')
    parser.add_argument('--start', type=str, help='开始日期 (YYYY-MM-DD)，默认: 2025-11-01')
    parser.add_argument('--end', type=str, help='结束日期 (YYYY-MM-DD)，默认: 2026-02-01')
    args = parser.parse_args()

    # 加载环境变量
    env_path = Path('.env')
    if env_path.exists():
        load_dotenv(env_path, override=True)
        print(f"[Mastodon 同步] 已加载 .env 文件: {env_path.absolute()}")
    else:
        print(f"[Mastodon 同步] 警告: .env 文件不存在: {env_path.absolute()}")

    api_base_url = os.getenv('MASTODON_API_BASE_URL')
    access_token = os.getenv('MASTODON_ACCESS_TOKEN')

    print(f"[Mastodon 同步] API Base URL: {api_base_url}")
    print(f"[Mastodon 同步] Access Token: {access_token[:20] if access_token else 'None'}...")

    if not api_base_url or not access_token:
        print("错误: 请在 .env 文件中配置 MASTODON_API_BASE_URL 和 MASTODON_ACCESS_TOKEN")
        return

    print(f"[Mastodon 同步] 连接到: {api_base_url}")

    # 创建 Mastodon 实例
    mastodon = Mastodon(
        access_token=access_token,
        api_base_url=api_base_url
    )

    # 验证凭据并获取用户信息
    print("[Mastodon 同步] 验证凭据...")
    try:
        account = mastodon.account_verify_credentials()
        print(f"[Mastodon 同步] 已登录为: @{account['username']}")
        user_id = account['id']
    except Exception as e:
        print(f"[Mastodon 同步] 认证失败: {e}")
        return

    # 加载同步状态
    sync_state = load_sync_state()
    synced_ids = set(sync_state.get('synced_ids', []))

    # 设置时间范围
    # 使用命令行参数或默认值
    if args.start:
        start_date_parts = [int(x) for x in args.start.split('-')]
        start_date = datetime(*start_date_parts, tzinfo=timezone.utc)
    else:
        start_date = datetime(2025, 11, 1, tzinfo=timezone.utc)

    if args.end:
        end_date_parts = [int(x) for x in args.end.split('-')]
        end_date = datetime(*end_date_parts, tzinfo=timezone.utc)
    else:
        end_date = datetime(2026, 2, 1, tzinfo=timezone.utc)

    print(f"[Mastodon 同步] 获取 {start_date.date()} 到 {end_date.date()} 的嘟文...")

    # 创建图片目录
    image_dir = Path('static/images/mastodon')
    print(f"[Mastodon 同步] 图片保存目录: {image_dir.absolute()}")

    # 获取嘟文
    all_statuses = []
    max_id = None

    while True:
        try:
            statuses = mastodon.account_statuses(
                user_id,
                max_id=max_id,
                limit=40,
                exclude_replies=True,  # 排除回复
                exclude_reblogs=True   # 排除转发
            )

            if not statuses:
                break

            for status in statuses:
                created_at = status['created_at']

                # 检查时间范围
                if created_at < start_date:
                    # 已经超出时间范围，停止获取
                    break

                if created_at >= end_date:
                    # 还没到时间范围，继续
                    max_id = status['id']
                    continue

                # 在时间范围内，检查是否已同步
                if str(status['id']) not in synced_ids:
                    all_statuses.append(status)

                max_id = status['id']

            # 如果最后一条嘟文早于开始日期，停止
            if statuses and statuses[-1]['created_at'] < start_date:
                break

            if len(statuses) < 40:
                break

        except Exception as e:
            print(f"[Mastodon 同步] 获取嘟文时出错: {e}")
            break

    print(f"[Mastodon 同步] 找到 {len(all_statuses)} 条新嘟文")

    if not all_statuses:
        print("[Mastodon 同步] 没有新内容需要同步")
        return

    # 按日期组织 thoughts
    thoughts_by_date = {}
    filtered_count = 0

    for status in all_statuses:
        # 转换内容
        content = html_to_text(status['content'])

        # 检查是否包含 @ 提及，如果包含则跳过
        if contains_mention(content):
            print(f"  ⊗ 跳过（包含@提及）: {content[:50]}...")
            filtered_count += 1
            # 仍然记录为已同步，避免下次重复处理
            synced_ids.add(str(status['id']))
            continue

        # 格式化日期
        created_at = status['created_at']
        date_key = created_at.strftime('%Y.%m.%d')  # 用于组织和排序
        date_display = created_at.strftime('%m.%d')  # 用于显示（不含年份）

        # 处理图片附件
        downloaded_images = []
        if status.get('media_attachments'):
            print(f"  - {date_display}: {content[:50]}... (包含 {len(status['media_attachments'])} 张图片)")
            for i, media in enumerate(status['media_attachments']):
                if media['type'] == 'image':
                    # 生成唯一文件名
                    url_path = urlparse(media['url']).path
                    ext = Path(url_path).suffix or '.jpg'
                    filename = f"{status['id']}_{i}{ext}"

                    # 下载图片
                    img_path = download_image(media['url'], image_dir, filename)
                    if img_path:
                        downloaded_images.append(img_path)
        else:
            print(f"  - {date_display}: {content[:50]}...")

        # 格式化为 thought 条目（使用简短日期显示）
        thought_entry = format_thought_entry(content, date_display, downloaded_images if downloaded_images else None)

        if date_key not in thoughts_by_date:
            thoughts_by_date[date_key] = []

        thoughts_by_date[date_key].append(thought_entry)

        # 记录已同步的 ID
        synced_ids.add(str(status['id']))

    if filtered_count > 0:
        print(f"\n[Mastodon 同步] 过滤了 {filtered_count} 条包含@提及的嘟文")

    # 插入到 thoughts 文件
    thoughts_file = Path('content/thoughts/index.md')
    if not thoughts_file.exists():
        print(f"[Mastodon 同步] 错误: {thoughts_file} 不存在")
        return

    print(f"[Mastodon 同步] 更新 {thoughts_file}...")
    insert_thoughts_to_file(thoughts_by_date, thoughts_file)

    # 更新同步状态
    sync_state['synced_ids'] = list(synced_ids)
    sync_state['last_sync'] = datetime.now().isoformat()
    save_sync_state(sync_state)

    print(f"[Mastodon 同步] 完成! 同步了 {len(all_statuses)} 条嘟文")
    print(f"[Mastodon 同步] 同步状态已保存到 mastodon_sync_state.json")

if __name__ == '__main__':
    main()
