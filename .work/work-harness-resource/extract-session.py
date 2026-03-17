#!/usr/bin/env python3
"""Extract human-readable conversation from a Claude Code JSONL session file.

Outputs: session metadata, user messages, assistant text responses, tool usage summary.
Strips tool results and system messages for readability.
"""
import json
import sys
from datetime import datetime
from collections import Counter

def extract_text(content):
    """Extract text from message content (string or list of blocks)."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        texts = []
        for block in content:
            if isinstance(block, dict):
                if block.get('type') == 'text':
                    texts.append(block.get('text', ''))
        return '\n'.join(texts)
    return ''

def extract_tool_uses(content):
    """Extract tool_use blocks from assistant content."""
    if not isinstance(content, list):
        return []
    tools = []
    for block in content:
        if isinstance(block, dict) and block.get('type') == 'tool_use':
            tools.append(block.get('name', '?'))
    return tools

def main(filepath):
    messages = []
    user_msgs = []
    assistant_msgs = []
    tool_counts = Counter()
    first_ts = None
    last_ts = None
    compactions = 0

    with open(filepath) as f:
        for line in f:
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            ts = obj.get('timestamp')
            if ts:
                if not first_ts:
                    first_ts = ts
                last_ts = ts

            msg_type = obj.get('type', '')

            if msg_type == 'summary':
                compactions += 1
                continue

            if msg_type == 'user':
                msg = obj.get('message', {})
                text = extract_text(msg.get('content', ''))
                # Strip system-reminder tags for readability
                import re
                text = re.sub(r'<system-reminder>.*?</system-reminder>', '', text, flags=re.DOTALL).strip()
                text = re.sub(r'<command-name>.*?</command-name>', '', text, flags=re.DOTALL).strip()
                text = re.sub(r'<command-message>.*?</command-message>', '', text, flags=re.DOTALL).strip()
                text = re.sub(r'<command-args>.*?</command-args>', '', text, flags=re.DOTALL).strip()
                text = re.sub(r'<local-command-stdout>.*?</local-command-stdout>', '', text, flags=re.DOTALL).strip()
                if text:
                    user_msgs.append(text)
                    messages.append(('USER', text, ts))

            elif msg_type == 'assistant':
                msg = obj.get('message', {})
                content = msg.get('content', '')
                text = extract_text(content)
                tools = extract_tool_uses(content)
                for t in tools:
                    tool_counts[t] += 1
                if text.strip():
                    assistant_msgs.append(text.strip())
                    messages.append(('ASSISTANT', text.strip(), ts))

    # Output
    session_id = filepath.split('/')[-1].replace('.jsonl', '')
    print(f"# Session: {session_id}")
    print(f"**Period:** {first_ts} → {last_ts}")
    print(f"**User messages:** {len(user_msgs)}")
    print(f"**Assistant responses:** {len(assistant_msgs)}")
    print(f"**Compactions:** {compactions}")
    print(f"**Tool usage:** {dict(tool_counts.most_common(15))}")
    print()

    print("## Conversation Flow")
    print()
    for role, text, ts in messages:
        short_ts = ts[:19] if ts else '?'
        if role == 'USER':
            # Truncate very long user messages
            display = text[:500] + ('...' if len(text) > 500 else '')
            print(f"### [{short_ts}] USER")
            print(display)
            print()
        else:
            # Truncate long assistant responses
            display = text[:1000] + ('...' if len(text) > 1000 else '')
            print(f"### [{short_ts}] ASSISTANT")
            print(display)
            print()

if __name__ == '__main__':
    main(sys.argv[1])
