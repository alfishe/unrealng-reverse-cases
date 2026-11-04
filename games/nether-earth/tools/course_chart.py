#!/usr/bin/env python3
"""The course of the bot's deep game (docs/10-gameplay-logic.md): each side's resources, robots and bases over the
game days, read with TTD memory_at from the instance that holds the recording (read only: no seek, no resume).

    python3 course_chart.py sample --work work/deep --out work/docC/course.json [--step 120]
    python3 course_chart.py chart work/docC/course.json docs/img/game-deep-course.png

`sample` reads $FD00-$FDFF (clock, resources, counts, the capture points) and the 48 robot records $DA00-$DCFF at
the start of every --step-th frame. `chart` draws three panels against the game day: the robots per side
($FD41 / $FD49), the bases per side (warbases + factories, $FD3A / $FD42), the resources per side (Resources
$FD22 / EnemyResources $FD4A: the general one and the sum of the six part resources), with the robots the player
built and lost marked.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402


def read(session, frame, offset, length):
    r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                                     'offset': offset, 'length': length}, ok=False)
    body = r.structured or {}
    if r.is_error or not body.get('exact', False):
        raise SystemExit(f'memory_at {frame}: {r.text}')
    return bytes.fromhex(body['hex'])


def sample(args):
    sys.path.insert(0, os.path.join(K.unreal_root(args.unreal), 'tools', 'verification', 'mcp'))
    import mcplib  # noqa: E402
    with open(os.path.join(args.work, 'session.json')) as f:
        state = json.load(f)
    # Reads only: no take_control, so the instance stays free for the others reading it
    session = mcplib.Session(f"http://127.0.0.1:{state['port_base'] + 200}/mcp", state['model'])
    last = args.last
    out = []
    for frame in range(args.first, last + 1, args.step):
        v = read(session, frame, 0xFD00, 0x100)
        robots = read(session, frame, 0xDA00, 0x300)
        out.append({'frame': frame, 'vars': v.hex(), 'robots': robots.hex()})
        print(frame, end=' ', flush=True)
    with open(args.out, 'w') as f:
        json.dump(out, f)
    print()


def decode(s):
    v = bytes.fromhex(s['vars'])
    r = bytes.fromhex(s['robots'])
    minutes, hours, days = v[0x35], v[0x36], v[0x37] | v[0x38] << 8
    live = [r[16 * i + 1] != 0 for i in range(48)]
    return {
        'frame': s['frame'],
        'day': days + (hours * 60 + minutes) / 1440,
        'ours': v[0x41], 'theirs': v[0x49],
        'our_bases': sum(v[0x3A:0x41]), 'their_bases': sum(v[0x42:0x49]),
        'our_factories': sum(v[0x3B:0x41]), 'their_factories': sum(v[0x43:0x49]),
        'our_general': v[0x22], 'their_general': v[0x4A],
        'our_parts': sum(v[0x23:0x29]), 'their_parts': sum(v[0x4B:0x51]),
        'neutral': sum(1 for k in range(4, 28) if v[0x73 + 5 * k] & 0xE0 == 0),
        'live': live,
    }


def chart(args):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams['text.usetex'] = False
    plt.rcParams['text.parse_math'] = False
    rows = [decode(s) for s in json.load(open(args.samples))]
    # play only: the play interrupt installed (Handler $FDFE = PlayInterrupt $D566); before it the menu's memory
    rows = [r for s, r in zip(json.load(open(args.samples)), rows) if bytes.fromhex(s['vars'])[0xFE:0x100] == b'\x66\xd5']
    day = [r['day'] for r in rows]
    fig, axes = plt.subplots(3, 1, figsize=(11, 7.6), dpi=110, sharex=True)
    ours, theirs = '#1080d0', '#d06010'
    ax = axes[0]
    ax.step(day, [r['ours'] for r in rows], where='post', color=ours, lw=2, label='our robots ($FD41)')
    ax.step(day, [r['theirs'] for r in rows], where='post', color=theirs, lw=2, label='enemy robots ($FD49)')
    for i in range(1, len(rows)):  # our slots born and freed between two samples
        for slot in range(24):
            was, now = rows[i - 1]['live'][slot], rows[i]['live'][slot]
            if now and not was:
                ax.plot(day[i], rows[i]['ours'], marker='^', color=ours, ms=6)
            if was and not now:
                ax.plot(day[i], rows[i]['ours'], marker='x', color='#c00000', ms=7, mew=2)
    ax.plot([], [], marker='^', color=ours, ls='', label='a robot built')
    ax.plot([], [], marker='x', color='#c00000', ls='', mew=2, label='a robot lost')
    ax.set_ylabel('robots')
    ax.legend(loc='upper left', fontsize=8, ncol=4)
    ax.grid(alpha=0.3)
    ax = axes[1]
    ax.step(day, [r['our_factories'] for r in rows], where='post', color=ours, lw=2, label='our factories ($FD3B-$FD40)')
    ax.step(day, [r['their_factories'] for r in rows], where='post', color=theirs, lw=2,
            label='enemy factories ($FD43-$FD48)')
    ax.step(day, [r['neutral'] for r in rows], where='post', color='#808080', lw=1.5, ls='--',
            label='neutral factories (capture points 4-27)')
    ax.set_ylabel('factories')
    ax.legend(loc='upper left', fontsize=8, ncol=3)
    ax.grid(alpha=0.3)
    ax = axes[2]
    ax.step(day, [r['our_general'] for r in rows], where='post', color=ours, lw=2, label='our general ($FD22)')
    ax.step(day, [r['their_general'] for r in rows], where='post', color=theirs, lw=2, label='enemy general ($FD4A)')
    ax.step(day, [r['our_parts'] for r in rows], where='post', color=ours, lw=1.2, ls=':',
            label='our part resources, sum ($FD23-$FD28)')
    ax.step(day, [r['their_parts'] for r in rows], where='post', color=theirs, lw=1.2, ls=':',
            label='enemy part resources, sum ($FD4B-$FD50)')
    ax.set_ylabel('resources')
    ax.set_xlabel(f"game day (clock $FD35-$FD38); work/deep frames {rows[0]['frame']}-{rows[-1]['frame']}")
    ax.legend(loc='upper left', fontsize=8, ncol=2)
    ax.grid(alpha=0.3)
    ax.set_xlim(0, day[-1])
    ax.set_xticks(range(0, int(day[-1]) + 1))
    last = rows[-1]
    fig.suptitle(f"The enemy outbuilds the bot: at day {day[-1]:.1f} it has {last['theirs']} robots to our "
                 f"{last['ours']} and {last['their_factories']} factories to our {last['our_factories']}\n"
                 '(its 3 warbases pay 15 general a day, our 1 pays 5)', fontsize=11)
    axes[0].set_title('robots alive per side', fontsize=9.5, loc='left')
    axes[1].set_title('factories owned: the neutral ones are captured one by one', fontsize=9.5, loc='left')
    axes[2].set_title('resources: the general one drops at each robot built, refills at midnight', fontsize=9.5,
                      loc='left')
    fig.tight_layout()
    fig.savefig(args.out)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = p.add_subparsers(dest='command', required=True)
    s = sub.add_parser('sample')
    s.add_argument('--work', required=True)
    s.add_argument('--out', required=True)
    s.add_argument('--first', type=int, default=0)
    s.add_argument('--last', type=int, default=36000)
    s.add_argument('--step', type=int, default=120)
    s.add_argument('--unreal')
    c = sub.add_parser('chart')
    c.add_argument('samples')
    c.add_argument('out')
    args = p.parse_args()
    sample(args) if args.command == 'sample' else chart(args)


if __name__ == '__main__':
    main()
