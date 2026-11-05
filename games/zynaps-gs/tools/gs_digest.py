#!/usr/bin/env python3
"""Digest a host-side GS port history (zxbus.1.ports JSONL, one record per access) into the GS conversation.

  gs_digest.py PORTS.jsonl [--from F] [--to F] [--out FILE] [--names]

Port $BB written = a command, $B3 written = a data byte, $B3 read = the card's answer, $BB read = the status poll
(bit 7: the data latch still full, bit 0: the command not yet taken).

Prints one line per command with the data written since the previous command, the answer read after it, the PC, and
whether the host saw the previous command taken (a status read with bit 0 clear) before writing this one, and the
previous data byte taken (bit 7 clear) before writing the next. A run of data bytes with no command between them (a
stream after #D1) is one line: its length, the frames, and how many bytes were written without a bit-7 clear seen
first ("unchecked").
"""
import argparse
import json
import sys

NAMES = {
    0x23: 'pages?', 0x2A: 'module volume', 0x2B: 'FX volume', 0x2E: 'select FX', 0x30: 'load module',
    0x31: 'play module', 0x32: 'stop module', 0x33: 'continue module', 0x38: 'load FX', 0x39: 'play FX',
    0x3A: 'stop FX (channel mask)', 0x3E: 'load FX (sign)', 0x40: 'FX note', 0x41: 'FX volume (current)',
    0x45: 'FX default volume?', 0x48: 'FX loop start (3 bytes)', 0x49: 'FX loop end (3 bytes)',
    0xD1: 'open stream', 0xD2: 'close stream', 0xF3: 'warm reset', 0xF4: 'cold reset',
}


def name(c):
    if 0x80 <= c <= 0x9F:
        return f'play FX in channel {c & 3}'
    return NAMES.get(c, '?')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('jsonl')
    ap.add_argument('--from', dest='lo', type=int, default=0)
    ap.add_argument('--to', dest='hi', type=int, default=1 << 40)
    ap.add_argument('--out')
    a = ap.parse_args()
    out = open(a.out, 'w') if a.out else sys.stdout
    cmd_taken = True       # the host saw the last command taken
    data_taken = True      # the host saw the last data byte taken
    pending = []           # data written since the last command
    unchecked_cmd = unchecked_data = 0
    stream = None          # [first frame, last frame, count, unchecked, pc]
    commands = 0
    answers = []

    def flush_stream():
        nonlocal stream
        if stream:
            out.write(f'{stream[0]:6d}-{stream[1]:<6d} data stream {stream[2]} bytes (pc ${stream[4]:04X}), '
                      f'{stream[3]} written before the previous was seen taken\n')
            stream = None

    last_cmd = None
    last_frame = 0
    for line in open(a.jsonl):
        try:
            r = json.loads(line)
        except ValueError:  # the last line of a stream still being written
            continue
        f = r['frame']
        if f < last_frame:
            flush_stream()
            out.write(f'--- the frame counter went back {last_frame} -> {f} (a snapshot load): a new segment\n')
        last_frame = f
        if f < a.lo or f > a.hi:
            continue
        port, v, d = r['port'] & 0xFF, r.get('value', 0), r['dir']
        if d == 'in' and port == 0xBB:
            if not v & 1:
                cmd_taken = True
            if not v & 0x80:
                data_taken = True
        elif d == 'in' and port == 0xB3:
            answers.append(v)
            if last_cmd is not None:
                out.write(f'{"":13s} answer {v} (${v:02X})\n')
        elif d == 'out' and port == 0xB3:
            unchecked = not data_taken
            data_taken = False
            if last_cmd == 0xD1 or stream:
                if stream is None:
                    stream = [f, f, 0, 0, r['pc']]
                stream[1] = f
                stream[2] += 1
                stream[3] += unchecked
                unchecked_data += unchecked
                last_cmd = None
                continue
            pending.append(v)
        elif d == 'out' and port == 0xBB:
            flush_stream()
            commands += 1
            flag = '' if cmd_taken else '  [previous command not seen taken]'
            unchecked_cmd += not cmd_taken
            cmd_taken = False
            data = ' '.join(f'${x:02X}' for x in pending)
            out.write(f'{f:6d} pc ${r["pc"]:04X} cmd ${v:02X} {name(v):24s} data {data or "-"}{flag}\n')
            pending = []
            last_cmd = v
    flush_stream()
    out.write(f'# {commands} commands; {unchecked_cmd} written before the previous one was seen taken; '
              f'{unchecked_data} stream bytes written before the previous was seen taken\n')


if __name__ == '__main__':
    main()
