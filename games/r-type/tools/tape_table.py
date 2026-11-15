#!/usr/bin/env python3
"""The R-Type tape as the markdown table of doc 3, section 3.1: every TZX block with the emulator's block index
(unreal-ng counts the data, tone and pulse blocks and the stops, not the group and text blocks), its kind, its
timings, its data length (flag and checksum included), its flag byte, where it loads (DEST below, from the code
and the recording c1) and its play time; the totals in seconds and 50 Hz frames, pauses not included.

    python3 tools/tape_table.py work/stage1/media/rtype.tzx
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402

T = 3500000.0
# where each data block goes (TZX index -> text); filled from the code and c1 (WALKTHROUGH 0 and 1)
DEST = {
    1: 'header: Program "R-TYPE", LINE 0, 4933 bytes',
    2: 'the BASIC at PROG `$5CCB-$700F`, code in it (entry `$5D06`)',
    7: 'Stage2Start `$FEE8-$FFCF` (232 bytes) and its check byte',
    13: '`$4000-$57FF`, the loading screen (frames 2675-4200)',
    15: '`$8000-$82FF`, then copied to `$5800` (frame 4400)',
    17: '`$9710-$C4AD`, encrypted (frames 4400-7075), decrypted in place at frame 11700',
    19: '`$FD7F`: the reader\'s own store key (2 bytes)',
    23: 'BlockTable2 over `$FF49` (55 bytes)',
    25: '`$7000-$970F`, encrypted (frames 7100-9450), decrypted in place at frame 11700',
    27: '`$C545-$E7CD` (frames 9475-11625), moved to `$DD18-$FFA0` at `$61BD`',
    29: 'Decipher `$FE40` and its leftover (115 bytes), run at 11 680',
    31: 'Stage2End over `$FEFC` (49 bytes)',
    33: 'the Tail `$61A8` (33 bytes), run at 11 697',
    35: '`$61C9`: the Tail\'s rest and the check byte (15 bytes)',
}
for k in (39, 43, 47, 51, 55, 59, 63, 67):
    DEST[k] = 'header to `$6000` (18 bytes: the level digit at `$600D`, the length at `$6010`)'
    DEST[k + 1] = 'the level at `$C4AE` (LoadLevel `$FE03`)'


def seconds(b):
    """play time of a block at its own timings, without its pause (T-states at 3.5 MHz)"""
    i, d = b['id'], b.get('data')
    if i in (0x10, 0x11):
        p = b.get('pilot', 2168)
        n = b.get('pilot_pulses', 8063 if d and d[0] < 128 else 3223)
        t = p * n + b.get('sync1', 667) + b.get('sync2', 735)
    else:
        t = 0
    if i == 0x12:
        return b['pulse'] * b['count'] / T
    if i == 0x13:
        return sum(b['pulses']) / T
    if d is not None:
        z, o = b.get('zero', 855), b.get('one', 1710)
        bits = 8 * (len(d) - 1) + b.get('last', 8)
        ones = sum(bin(x).count('1') for x in d)
        t += 2 * (z * (bits - ones) + o * ones)
    return t / T


def main():
    t = open(sys.argv[1], 'rb').read()
    blocks = tzxblocks.parse(t)
    print('| TZX | Emu | Kind | Timings (T) | Bytes | Flag | Loads to | Time (s) |')
    print('| ---: | ---: | --- | --- | ---: | --- | --- | ---: |')
    emu, total, data_total = 0, 0.0, 0.0
    for b in blocks:
        b.update(b.get('timing', {}))
        i = b['id']
        counted = i not in (0x21, 0x22, 0x30, 0x32)
        kind = {0x10: 'standard', 0x11: 'turbo', 0x12: 'pure tone', 0x13: 'pulses', 0x14: 'pure data',
                0x20: 'stop the tape' , 0x21: 'group start', 0x22: 'group end', 0x30: 'text', 0x32: 'archive info'}.get(i, hex(i))
        d = b.get('data')
        tim = ''
        if i == 0x11:
            tim = f"pilot {b['pilot']} x {b['pilot_pulses']}, sync {b['sync1']}/{b['sync2']}, bits {b['zero']}/{b['one']}"
        elif i == 0x14:
            tim = f"bits {b['zero']}/{b['one']}"
        elif i == 0x12:
            tim = f"tone {b['pulse']} x {b['count']}"
        elif i == 0x13:
            tim = f"{len(b['pulses'])} pulses"
        elif i == 0x10:
            tim = 'ROM'
        elif i in (0x21, 0x30):
            tim = repr(b.get('text', b.get('name', '')))
        s = seconds(b)
        total += s
        if d is not None:
            data_total += s
        print(f"| {b['index']} | {emu if counted else ''} | {kind} | {tim} | {len(d) if d is not None else ''} | "
              f"{'`$%02X`' % d[0] if d else ''} | {DEST.get(b['index'], '')} | {s:.2f} |")
        if counted:
            emu += 1
    print(f'\nTotal {total:.1f} s ({round(total * 50)} frames at 50 Hz), pauses not included.')


if __name__ == '__main__':
    main()
