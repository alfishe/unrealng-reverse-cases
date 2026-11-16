#!/usr/bin/env python3
"""Disassemble a range of a 64K memory dump with SkoolKit's sna2skool (the venv in $SKOOLKIT_VENV):

    python3 tools/z80dis.py DUMP.bin START END      # hex addresses, END exclusive

Prints the instructions only (address, operation; hex operands)."""
import os
import subprocess
import sys

dump, start, end = sys.argv[1], int(sys.argv[2], 16), int(sys.argv[3], 16)
venv = os.environ.get('SKOOLKIT_VENV', '')
exe = os.path.join(venv, 'bin', 'sna2skool.py')
res = subprocess.run([os.path.join(venv, 'bin', 'python'), '-I', exe, '-o', '0', '-H', '-s', str(start), '-e',
                      str(end), dump], capture_output=True, text=True)
if res.returncode:
    sys.exit(res.stderr)
for line in res.stdout.splitlines():
    if len(line) > 6 and line[1:2] == '$' and line[:1] in 'c *':
        print(line[1:])
