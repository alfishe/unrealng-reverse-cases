#!/usr/bin/env python3
"""Detokenise a BASIC program (its first LEN bytes): uses nether-earth-editor's zxbasic.detok_line, read-only."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../nether-earth-editor/tools'))
import zxbasic
d = open(sys.argv[1], 'rb').read()
L = int(sys.argv[2]) if len(sys.argv) > 2 else len(d)
for num, body in [(int.from_bytes(d[p:p+2], 'big'), None) for p in []]:
    pass
p = 0
while p + 4 <= L:
    num = int.from_bytes(d[p:p + 2], 'big'); ln = int.from_bytes(d[p + 2:p + 4], 'little')
    body = d[p + 4:p + 4 + ln]
    print(num, zxbasic.detok_line(body))
    p += 4 + ln
print(f'# program {p} bytes; file {len(d)} bytes; after the program: {len(d) - p}')
