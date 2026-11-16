#!/usr/bin/env python3
"""The tape as a markdown table for doc 3, 3.1: every data block of a TZX with its kind, length, flag, bit timing,
play time at signal speed and the time from the tape's start; the runs of tone and pulse blocks between data blocks
are summed into the next data block's lead-in.

    python3 tools/tape_table.py "work/media/Enduro Racer.tzx"
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402


def main():
    t = open(sys.argv[1], 'rb').read()
    print('| # | TZX blocks | Kind | Bytes (flag + data + check) | Flag | Bit 0 / 1 (T) | Lead-in (s) | Data (s) | Pause (ms) | Ends at (s) |')
    print('| ---: | --- | --- | ---: | --- | --- | ---: | ---: | ---: | ---: |')
    clock, lead, first, n = 0.0, 0.0, None, 0
    for b in tzxblocks.parse(t):
        s = tzxblocks.seconds(b)
        if 'data' not in b:
            lead += s + b.get('pause', 0) / 1000
            clock += s + b.get('pause', 0) / 1000
            if first is None and b['kind'] in ('pure tone', 'pulses'):
                first = b['index']
            continue
        d = b['data']
        tm = b['timing']
        if b['kind'] == 'standard':
            kind = 'ROM header' if d[0] == 0 else 'ROM data'
            lead_s = tm['pilot'] * tm['pilot_pulses'] / 3.5e6 + lead
            data_s = s - tm['pilot'] * tm['pilot_pulses'] / 3.5e6
        else:
            kind = 'pure data'
            lead_s, data_s = lead, s
        clock += s
        end = clock
        clock += b.get('pause', 0) / 1000
        rng = f'{first}-{b["index"]}' if first is not None else f'{b["index"]}'
        n += 1
        desc = tzxblocks.describe(d)
        name = desc.split('header ')[1].split(',')[0] if 'header' in desc else ''
        print(f'| {n} | {rng} | {kind}{" " + name if name else ""} | {len(d)} | `{d[0]:02X}` | {tm["zero"]} / {tm["one"]} | '
              f'{lead_s:.2f} | {data_s:.2f} | {b.get("pause", 0)} | {end:.2f} |')
        lead, first = 0.0, None
    print(f'\nThe tape plays {clock:.1f} s with its pauses ({clock * 50:.0f} frames at 50 Hz).')


if __name__ == '__main__':
    main()
