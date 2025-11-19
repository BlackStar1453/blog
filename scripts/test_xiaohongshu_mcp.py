#!/usr/bin/env python3
import json
import sys
from urllib import request, error


ENDPOINT = "http://localhost:18060/mcp"


def rpc(method, params=None, rid=1):
    body = {
        "jsonrpc": "2.0",
        "id": rid,
        "method": method,
    }
    if params is not None:
        body["params"] = params

    data = json.dumps(body).encode("utf-8")
    req = request.Request(
        ENDPOINT,
        data=data,
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        method="POST",
    )

    try:
        with request.urlopen(req) as resp:
            status = resp.getcode()
            raw = resp.read()
            try:
                payload = json.loads(raw.decode("utf-8")) if raw else {}
            except Exception:
                payload = {"_raw": raw.decode("utf-8", "replace")}
            return status, payload, None
    except error.HTTPError as e:
        raw = e.read()
        try:
            payload = json.loads(raw.decode("utf-8")) if raw else {}
        except Exception:
            payload = {"_raw": raw.decode("utf-8", "replace")}
        return e.code, payload, e
    except Exception as e:
        return None, None, e


def pretty(obj):
    return json.dumps(obj, ensure_ascii=False, indent=2)


def print_header(title):
    print(f"\n=== {title} ===")


def ensure_initialized():
    print_header("Initialize")
    status, payload, err = rpc(
        "initialize",
        {
            "protocolVersion": "2024-11-05",
            "clientInfo": {"name": "xhs-mcp-tester", "version": "0.1.0"},
            "capabilities": {},
        },
        rid=1,
    )
    print(f"HTTP status: {status}")
    if status == 404:
        print("ERROR: 404 Not Found on initialize. The /mcp endpoint may be incorrect.")
        return False
    if status is None:
        print(f"ERROR: Failed to reach endpoint: {err}")
        return False
    if payload and "error" in payload:
        print("Initialize returned error:")
        print(pretty(payload["error"]))
        # Even if initialize returns an error, some servers still allow tools/list
    else:
        print("Initialize response OK")
    return True


def list_tools():
    print_header("List Tools")
    status, payload, err = rpc("tools/list", {}, rid=2)
    print(f"HTTP status: {status}")
    if status == 404:
        print("ERROR: 404 Not Found on tools/list.")
        return None
    if status is None:
        print(f"ERROR: Failed to reach endpoint: {err}")
        return None
    if not payload:
        print("ERROR: Empty response for tools/list")
        return None
    if "error" in payload:
        print("tools/list error:")
        print(pretty(payload["error"]))
        return None
    result = payload.get("result", {})
    tools = result.get("tools") or result.get("items") or []
    print(f"Tools count: {len(tools)}")
    for t in tools:
        name = t.get("name") or t.get("id")
        desc = t.get("description") or t.get("desc")
        print(f"- {name}: {desc}")
    return tools


def find_search_tool(tools):
    if not tools:
        return None
    # Prefer an exact name 'search' if present, else first tool with 'search' in the name
    by_name = {str((t.get("name") or t.get("id") or "")).lower(): t for t in tools}
    if "search" in by_name:
        return by_name["search"].get("name") or by_name["search"].get("id")
    for t in tools:
        name = str((t.get("name") or t.get("id") or "")).lower()
        if "search" in name or "sou" in name:  # loose match for Chinese pinyin
            return t.get("name") or t.get("id")
    # Fallback: return the first tool
    return (tools[0].get("name") or tools[0].get("id")) if tools else None


def call_search(tool_name, query):
    print_header(f"Call Tool: {tool_name}")
    status, payload, err = rpc(
        "tools/call",
        {
            "name": tool_name,
            "arguments": {"query": query},
        },
        rid=3,
    )
    print(f"HTTP status: {status}")
    if status == 404:
        print("ERROR: 404 Not Found on tools/call.")
        return None, True
    if status is None:
        print(f"ERROR: Failed to reach endpoint: {err}")
        return None, False
    if not payload:
        print("ERROR: Empty response for tools/call")
        return None, False
    if "error" in payload:
        print("tools/call error:")
        print(pretty(payload["error"]))
        return None, False
    return payload.get("result"), False


def extract_items_from_result(result_obj):
    if not result_obj:
        return []

    # MCP typical: result.content is a list of parts: {type: 'json'|'text', ...}
    content = result_obj.get("content")
    items = []
    if isinstance(content, list):
        for part in content:
            ptype = part.get("type")
            if ptype == "json":
                # may be {type:'json', json: <obj>} or {type:'json', data: <obj>}
                obj = part.get("json", part.get("data"))
                if isinstance(obj, dict):
                    if isinstance(obj.get("items"), list):
                        items.extend(obj["items"])
                    elif isinstance(obj.get("data"), list):
                        items.extend(obj["data"])
                    else:
                        # if the dict itself is a single item
                        items.append(obj)
                elif isinstance(obj, list):
                    items.extend(obj)
            elif ptype == "text":
                text = part.get("text") or ""
                try:
                    maybe = json.loads(text)
                    if isinstance(maybe, list):
                        items.extend(maybe)
                    elif isinstance(maybe, dict):
                        if isinstance(maybe.get("items"), list):
                            items.extend(maybe["items"])
                        else:
                            items.append(maybe)
                except Exception:
                    # non-JSON text, ignore
                    pass

    # Other shapes: result.items / result.data
    if not items:
        if isinstance(result_obj.get("items"), list):
            items = result_obj["items"]
        elif isinstance(result_obj.get("data"), list):
            items = result_obj["data"]

    # Normalize to list of dicts
    norm = []
    for it in items:
        if isinstance(it, dict):
            norm.append(it)
        else:
            norm.append({"_": it})
    return norm


def print_top5(items):
    print_header("Top 5 Results")
    top = items[:5]
    if not top:
        print("No items returned.")
        return
    for i, it in enumerate(top, 1):
        title = it.get("title") or it.get("name") or it.get("desc") or it.get("description") or it.get("_", "")
        url = it.get("url") or it.get("link") or it.get("note_url") or it.get("noteId")
        author = it.get("author") or it.get("user") or it.get("nickname")
        likes = it.get("likes") or it.get("likedCount") or it.get("collects") or it.get("comments")
        print(f"#{i} \n  Title: {title}\n  URL: {url}\n  Author: {author}\n  Metrics: {likes}")


def main():
    print("Testing xiaohongshu-mcp at", ENDPOINT)

    if not ensure_initialized():
        sys.exit(2)

    tools = list_tools()
    if tools is None:
        # Try re-initialize once and retry tools/list
        print("Retry: Re-initialize and list tools again...")
        if not ensure_initialized():
            sys.exit(2)
        tools = list_tools()
        if tools is None:
            print("FATAL: Could not list tools.")
            sys.exit(3)

    search_tool = find_search_tool(tools)
    print(f"Selected search tool: {search_tool}")

    result, got_404 = call_search(search_tool, "Claude Code")
    if got_404:
        print("Detected 404 during tools/call. Please check server routing.")
        sys.exit(4)
    if not result:
        print("Search returned no result payload.")
        sys.exit(5)

    items = extract_items_from_result(result)
    print_top5(items)


if __name__ == "__main__":
    main()

