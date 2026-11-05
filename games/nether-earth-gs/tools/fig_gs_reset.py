#!/usr/bin/env python3
"""Doc 03 figure: why the disk loader loses the module (docs/img/load/gs-reset.png).

    python3 tools/fig_gs_reset.py [--events work/stage1/x3/gs-events.jsonl] [--out docs/img/load/gs-reset.png]

The events are stage 1's run x3 (the SCL on a Pentagon 128 + GS 512 KB, the zxbus.1 history in capture mode: every
port access of the host on the card's ports and of the card's own CPU on its ports, with the frame and the card's
clock). Top: frames 545-700 of the run, one lane per kind of port access, the host's above, the card's below. Bottom:
the 0.4 microseconds of frame 555 in which the host writes #F4, #30 and #D1 and the card reacts, on the card's clock
(12 MHz; the host's T-states are 7/24 of it).

The card's ports (GS ROM sources, __MAIN.a80): 0 PAGE (write), 1 COMRG (read the command), 2 DATRG (read the data),
3 OUTRG (write the reply), 4 FLAGS (read the status), 5 RSCOM (write: clear the command flag). The host's: $BB the
command (write) and the status (read), $B3 the data.
"""
import argparse
import json
import os
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
BG, PANEL, FG, DIM = '#15161b', '#1c1d24', '#e6e6e6', '#b8bcc8'
F0, F1 = 545, 700

LANES = [  # key, label, colour
    ('host-cmd', 'host OUT ($BB): a command', '#e5534b'),
    ('host-stat', 'host IN ($BB): the status', '#ff9f80'),
    ('host-data', 'host OUT ($B3): module bytes', '#d9a441'),
    ('gs-comrg', 'card IN (1) COMRG: take the command', '#4caf50'),
    ('gs-rscom', 'card OUT (5) RSCOM: clear the command flag', '#c77ddb'),
    ('gs-page', 'card OUT (0) PAGE: the RAM test walks 64 pages', '#5c8fd6'),
    ('gs-flags', 'card IN (4) FLAGS: the idle loop polls', '#8a8f9e'),
    ('gs-datrg', 'card IN (2) DATRG: read a data byte', '#40c4c4'),
]


def kind(e):
    side, port, out = e['side'], e['port'], e.get('out')
    if side == 'host':
        if port == 0xBB:
            return 'host-cmd' if out else 'host-stat'
        if port == 0xB3 and out:
            return 'host-data'
    if side == 'gs':
        return {(1, False): 'gs-comrg', (5, True): 'gs-rscom', (0, True): 'gs-page', (4, False): 'gs-flags',
                (2, False): 'gs-datrg'}.get((port, bool(out)))
    return None


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--events', default=os.path.join(CASE, 'work', 'stage1', 'x3', 'gs-events.jsonl'))
    p.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'load', 'gs-reset.png'))
    a = p.parse_args()
    per = {k: {} for k, _, _ in LANES}     # lane -> frame -> count
    zoom = []                               # frame 555-556 events near the commands
    host_cmds = []
    for line in open(a.events):
        e = json.loads(line)
        f = e['frame']
        if f < F0:
            continue
        if f > F1:
            break
        k = kind(e)
        if k is None:
            continue
        per[k][f] = per[k].get(f, 0) + 1
        if k == 'host-cmd':
            host_cmds.append((f, e['value'], e['timestamp']))
        if 555 <= f <= 556 and k != 'gs-flags':
            zoom.append((e['timestamp'], k, e))
    t_cmd = next(t for f, v, t in host_cmds if v == 0xF4)
    zoom = [z for z in zoom if -200 <= z[0] - t_cmd <= 300]

    fig = plt.figure(figsize=(13, 8.4), dpi=110)
    gs = fig.add_gridspec(2, 1, height_ratios=[3.1, 1.25], hspace=0.42)
    ax, bx = fig.add_subplot(gs[0]), fig.add_subplot(gs[1])
    fig.patch.set_facecolor(BG)
    for x in (ax, bx):
        x.set_facecolor(PANEL)
        x.tick_params(colors=DIM, labelsize=9)
        for s in x.spines.values():
            s.set_color('#444')
    n = len(LANES)
    for i, (k, label, colour) in enumerate(LANES):
        y = n - 1 - i
        frames = sorted(per[k])
        if k in ('host-data', 'gs-flags'):
            # dense lanes: one bar a frame, its height the count against the lane's busiest frame
            top = max(per[k].values()) if per[k] else 1
            for f in frames:
                h = 0.7 * per[k][f] / top
                ax.bar(f, h, bottom=y - 0.35, width=1.0, color=colour, linewidth=0)
        else:
            ax.scatter(frames, [y] * len(frames), s=[18 + 6 * min(per[k][f], 6) for f in frames], color=colour,
                       linewidths=0, zorder=3)
        ax.text(F0 - 1.5, y, label, color=colour, fontsize=9, ha='right', va='center')
    ax.set_yticks([])
    ax.set_xlim(F0 - 0.5, F1 + 0.5)
    ax.set_ylim(-0.8, n - 0.2)
    ax.axhline(n - 3.5, color='#555', lw=0.8)
    ax.text(F1 + 1, n - 2, 'the Spectrum', color=DIM, fontsize=9, rotation=90, va='center')
    ax.text(F1 + 1, (n - 4) / 2, 'the GS card', color=DIM, fontsize=9, rotation=90, va='center')
    page = [f for f in sorted(per['gs-page'])]
    test0, test1 = 556, max(page)
    ax.axvspan(test0, test1, color='#5c8fd6', alpha=0.10, lw=0)
    ax.annotate(f'frames {test0}-{test1}: the card restarts (JP 0): ROM sum, RAM test,\n'
                'no IN (1), no IN (4): no command can be taken', xy=((test0 + test1) / 2, 2.0),
                xytext=(575, 3.05), color='#9ec0ff', fontsize=9.5,
                arrowprops=dict(arrowstyle='->', color='#9ec0ff', lw=0.8))
    ax.annotate('frame 555: #F4, #30, #D1\nback to back (enlarged below)', xy=(555, n - 1), xytext=(566, n - 1.25),
                color='#e5534b', fontsize=9.5, arrowprops=dict(arrowstyle='->', color='#e5534b', lw=0.8))
    stat = sorted(per['host-stat'])
    if stat:
        ax.annotate(f'frame {stat[0]}: the loader\'s WaitGs reads $FE: bit 0 clear ("taken"), so it streams',
                    xy=(stat[0], n - 2), xytext=(568, n - 1.55), color='#ff9f80', fontsize=9,
                    arrowprops=dict(arrowstyle='->', color='#ff9f80', lw=0.8))
    data = sorted(per['host-data'])
    if data:
        ax.annotate(f'from frame {data[0]}: ~535 module bytes a frame into the data latch; no LOAD loop reads them',
                    xy=(data[0] + 3, n - 3.0), xytext=(560, n - 3.42), color='#d9a441', fontsize=9,
                    arrowprops=dict(arrowstyle='->', color='#d9a441', lw=0.8))
    dat = sorted(per['gs-datrg'])
    if dat:
        ax.annotate(f'frame {dat[0]}: the test is over; one DATRG read,\nthen the idle loop polls FLAGS: '
                    'bit 0 (a command) never set again', xy=(dat[0], 0), xytext=(dat[0] - 112, 0.35), color='#40c4c4',
                    fontsize=9, arrowprops=dict(arrowstyle='->', color='#40c4c4', lw=0.8))
    ax.set_xlabel('frame of run x3 (the SCL booted at frame ~150; Pentagon 128 + GS 512 KB)', color=DIM, fontsize=9)
    ax.set_title('#F4 restarts the card cold: #30 and #D1 arrive while it starts, and its RSCOM wipes them; the module '
                 'streams into nothing', color=FG, fontsize=12, loc='left')

    # the zoom: frame 555's microseconds, on the card's clock
    rows = {'host-cmd': 1, 'gs-comrg': 0.5, 'gs-rscom': 0, 'gs-page': 0}
    names = {0xF4: '#F4', 0x30: '#30', 0xD1: '#D1'}
    for t, k, e in zoom:
        dt = t - t_cmd
        y = rows.get(k)
        if y is None:
            continue
        colour = dict((kk, c) for kk, _, c in LANES)[k]
        bx.scatter([dt], [y], s=40, color=colour, zorder=3)
        if k == 'host-cmd':
            txt = names.get(e['value'], hex(e['value']))
            bx.text(dt, y + 0.12, txt, color=colour, fontsize=10, ha='center', va='bottom')
        elif k == 'gs-comrg':
            bx.text(dt + 4, y - 0.05, 'card IN (1):\nit takes #F4', color=colour, fontsize=8.5, va='top')
        elif k == 'gs-rscom':
            bx.text(dt, y - 0.12, 'OUT (5)', color=colour, fontsize=8.5, ha='center', va='top')
    rs = [t - t_cmd for t, k, _ in zoom if k == 'gs-rscom']
    if rs:
        bx.annotate('COMF4 and INIT each clear the command flag\n(OUT (RSCOM),A): #D1, which had replaced #30\n'
                    'in the latch, is dropped before anyone reads it', xy=(rs[0], 0), xytext=(rs[0] + 25, 0.55),
                    color='#c77ddb', fontsize=9, arrowprops=dict(arrowstyle='->', color='#c77ddb', lw=0.8))
    bx.text(-28, 1.3, 'host OUT ($BB):', color='#e5534b', fontsize=9, va='center')
    bx.set_yticks([])
    bx.set_ylim(-0.45, 1.45)
    bx.set_xlim(-30, 330)
    bx.set_xlabel('card clock ticks from the host\'s OUT ($BB),#F4 (12 MHz: 100 ticks = 29 host T-states)', color=DIM,
                  fontsize=9)
    bx.set_title('Frame 555 enlarged: the three commands come about 18 host T-states apart (LD A,n; OUT ($BB),A); the card '
                 'reads only the first', color=FG, fontsize=11, loc='left')
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    fig.savefig(a.out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print(a.out)
    for f, v, t in host_cmds[:4]:
        print('host command', f, hex(v), t - t_cmd)
    for t, k, e in zoom:
        print(k, t - t_cmd, e.get('pc'), e.get('value'))
    print('RAM test', test0, test1, 'first status read', stat[:1], 'first data', data[:1], 'datrg', dat[:1])


if __name__ == '__main__':
    sys.exit(main())
