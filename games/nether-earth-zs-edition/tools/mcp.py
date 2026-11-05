#!/usr/bin/env python3
"""One MCP tool call on the instance a work folder holds (the control session taken first).

  mcp.py --work W TOOL '{"action": ...}' [--json OUT]
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNREAL = os.environ.get('UNREAL_NG', os.path.join(HERE, '..', '..', '..', 'unreal-ng'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
import mcplib  # noqa: E402


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--work', required=True)
    p.add_argument('tool')
    p.add_argument('args', nargs='?', default='{}')
    p.add_argument('--json')
    a = p.parse_args()
    state = json.load(open(os.path.join(a.work, 'session.json')))
    s = mcplib.Session(f"http://127.0.0.1:{state['port_base'] + 200}/mcp", state['model'])
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    r = s.call(a.tool, json.loads(a.args), ok=False)
    print(r.text)
    if a.json:
        json.dump(r.structured or {}, open(a.json, 'w'), indent=1)


if __name__ == '__main__':
    main()
