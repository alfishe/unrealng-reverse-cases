#!/usr/bin/env python3
"""Elite's random generators: each model checked call by call against the access traces, then run for its
period, its distribution and its pairs (docs/runtime-analysis.md, section 6).

    python3 tools/fig_rt_prng.py [--check-only]

The generators (src/game):
- StarRandom `$7E86` (stardust.asm), seed in HL (StarSeed `$7105`): A = 2 H + carry, B = A, H = A + L + carry,
  L = B. The same step as Random, on the caller's HL.
- Random `$B799` (combat.asm), seed RandomSeed `$B7AA`: the same step on its own word.
- TextRandom `$D5E1` (textprint.asm), four bytes TextSeeds `$DECC`: L shifted left, the two words added with that carry,
  A the sum's high byte, the words moved along.
- Twist `$E063` (galaxy.asm): s0, s1, s2 = s1, s2, s0 + s1 + s2 on SystemSeeds `$DEC0` (tools/galaxy.py).

The check reads every call in the traces of the scenes (tools/rtscenes.py and the screen windows below): the seed
read, the carry at the entry, the bytes written and A at the RET, and compares them with the model. The figures:
docs/img/runtime/prng-*.png.
"""
import argparse
import os
import sys
from collections import Counter, defaultdict

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import eprof  # noqa: E402
import galaxy as G  # noqa: E402
import rtplot as P  # noqa: E402
import rtscenes as S  # noqa: E402

ENTRY = {'StarRandom': 0x7E86, 'Random': 0xB799, 'TextRandom': 0xD5E1, 'Twist': 0xE063}
SEEDS = {'Random': (0xB7AA, 2), 'TextRandom': (0xDECC, 4), 'Twist': (0xDEC0, 6)}
TRACES = [('w1', '3470:0-3620:0'), ('w1', '4280:0-4380:0'), ('f1', '2400:0-2500:0'), ('f1', '1500:0-1600:0'),
          ('d1', '1225:0-1250:0'), ('d1', '1250:0-1350:0'), ('d1', '1445:0-1470:0'), ('d1', '1665:0-1690:0'),
          ('f1', '960:0-1060:0'), ('w1', '2100:0-2200:0')]


def step16(h, l, c):
    """StarRandom / Random: (A, H, L, carry out)"""
    a = 2 * h + c
    c1, a = a >> 8, a & 0xFF
    s = a + l + c1
    return s & 0xFF, s & 0xFF, a, s >> 8


def text_step(s):
    """TextRandom on the four bytes [s0, s1, s2, s3]: (A, new bytes)"""
    lo = (s[0] << 1) & 0xFF
    c = s[0] >> 7
    de = s[1] << 8 | lo
    hl = (s[2] | s[3] << 8) + de + c
    hl &= 0xFFFF
    return hl >> 8, [hl & 0xFF, hl >> 8, de & 0xFF, de >> 8]


def calls_in(trace, name):
    """[(entry instruction, [instructions of the call])]: from the entry PC to its RET back to the caller"""
    ins = trace.instructions
    entry = ENTRY[name]
    out = []
    i = 0
    n = len(ins)
    while i < n:
        if ins[i].pc == entry and not ins[i].interrupted:
            j = i
            body = []
            while j < n:
                x = ins[j]
                if entry <= x.pc < entry + 40:
                    body.append(x)
                    op = eprof.opcode(x)
                    if op and op[0] == 0xC9:
                        break
                j += 1
            out.append(body)
            i = j + 1
        else:
            i += 1
    return out


def check_call(name, body):
    """(ok, sample) for one call"""
    first, last = body[0], body[-1]
    carry = first.af & 1
    if name == 'StarRandom':
        h, l = first.hl >> 8, first.hl & 0xFF
        a, h2, l2, _c = step16(h, l, carry)
        got = (last.af >> 8, last.hl >> 8, last.hl & 0xFF)
        return got == (a, h2, l2), (h << 8 | l, carry, a)
    lo, size = SEEDS[name]
    reads, writes = [], []
    for x in body:
        for c in x.cycles:
            if lo <= c.address < lo + size:
                if c.tag == 'R':
                    reads.append((c.address, c.value))
                elif c.tag == 'W':
                    writes.append((c.address, c.value))
    if name == 'Random':
        old = dict(reads)
        h, l = old[lo + 1], old[lo]
        a, h2, l2, _c = step16(h, l, carry)
        new = dict(writes)
        got = (last.af >> 8, new.get(lo + 1), new.get(lo))
        return got == (a, h2, l2), (h << 8 | l, carry, a)
    if name == 'TextRandom':
        old = {}
        for ad, v in reads:
            old.setdefault(ad, v)
        s = [old[lo + k] for k in range(4)]
        a, new = text_step(s)
        w = dict(writes)
        return (last.af >> 8, [w.get(lo + k) for k in range(4)]) == (a, new), (s, a)
    if name == 'Twist':
        old = {}
        for ad, v in reads:
            old.setdefault(ad, v)
        s = [old[lo] | old[lo + 1] << 8, old[lo + 2] | old[lo + 3] << 8, old[lo + 4] | old[lo + 5] << 8]
        w = dict(writes)
        got = [w[lo] | w[lo + 1] << 8, w[lo + 2] | w[lo + 3] << 8, w[lo + 4] | w[lo + 5] << 8]
        return got == G.twist(s), s
    raise KeyError(name)


def check(verbose=True):
    """{name: (calls, matched, carry-in Counter, [samples])}"""
    res = defaultdict(lambda: [0, 0, Counter(), []])
    for rec, window in TRACES:
        path = os.path.join(S.work(rec), 'traces', window.replace(':', '_') + '.uatr')
        if not os.path.isfile(path):
            continue
        t = eprof.load(S.work(rec), window)
        for name in ENTRY:
            for body in calls_in(t, name):
                ok, sample = check_call(name, body)
                r = res[name]
                r[0] += 1
                r[1] += ok
                r[2][body[0].af & 1] += 1
                if len(r[3]) < 20000:
                    r[3].append(sample)
    if verbose:
        for name in ENTRY:
            r = res[name]
            print('%-11s %6d calls, %6d match the model, carry in: %s' % (name, r[0], r[1], dict(r[2])))
    return res


# --- the long runs ---

def run16(seed, carry_mode, n):
    """n outputs of the 16-bit step from seed: carry_mode 0 / 1 a fixed carry in, 'chain' the carry out fed back"""
    h, l = seed >> 8, seed & 0xFF
    c = 0
    out = np.empty(n, dtype=np.uint8)
    for i in range(n):
        cin = c if carry_mode == 'chain' else carry_mode
        a, h, l, c = step16(h, l, cin)
        out[i] = a
    return out


def cycles16(carry):
    """the functional graph of the 16-bit step with a fixed carry: {cycle length: states on cycles of it}, and the
    map (for the tail of a given seed)"""
    nxt = np.empty(65536, dtype=np.int64)
    for s in range(65536):
        _a, h, l, _c = step16(s >> 8, s & 0xFF, carry)
        nxt[s] = h << 8 | l
    colour = np.zeros(65536, dtype=np.int64)  # 0 new, else the walk id
    on_cycle = {}
    walk = 0
    for s in range(65536):
        if colour[s]:
            continue
        walk += 1
        path = []
        x = s
        while not colour[x]:
            colour[x] = walk
            path.append(x)
            x = int(nxt[x])
        if colour[x] == walk:  # a new cycle closed inside this walk
            k = path.index(x)
            length = len(path) - k
            for y in path[k:]:
                on_cycle[y] = length
    lengths = Counter(on_cycle.values())
    return {L: c for L, c in lengths.items()}, nxt, on_cycle


def seed_orbit(nxt, on_cycle, seed):
    """(tail length, cycle length) of a seed"""
    x, tail = seed, 0
    while x not in on_cycle:
        x = int(nxt[x])
        tail += 1
    return tail, on_cycle[x]


def run_text(seed4, n):
    s = list(seed4)
    out = np.empty(n, dtype=np.uint8)
    for i in range(n):
        a, s = text_step(s)
        out[i] = a
    return out


def text_period(seed4, limit):
    """Brent's cycle finding on the 32-bit state, up to limit steps: (tail, period) or None"""
    def f(x):
        s = [x & 0xFF, x >> 8 & 0xFF, x >> 16 & 0xFF, x >> 24]
        _a, t = text_step(s)
        return t[0] | t[1] << 8 | t[2] << 16 | t[3] << 24
    x0 = seed4[0] | seed4[1] << 8 | seed4[2] << 16 | seed4[3] << 24
    power = lam = 1
    tortoise, hare = x0, f(x0)
    steps = 1
    while tortoise != hare:
        if power == lam:
            tortoise = hare
            power *= 2
            lam = 0
        hare = f(hare)
        lam += 1
        steps += 1
        if steps > limit:
            return None
    mu = 0
    tortoise = hare = x0
    for _ in range(lam):
        hare = f(hare)
    while tortoise != hare:
        tortoise, hare = f(tortoise), f(hare)
        mu += 1
    return mu, lam


def twist_period(seeds, limit):
    s0 = list(seeds)
    s = G.twist(s0)
    for n in range(1, limit):
        if s == s0:
            return n
        s = G.twist(s)
    return None


def chi2(values):
    h = np.bincount(values, minlength=256)
    e = len(values) / 256
    return float(((h - e) ** 2 / e).sum()), h


def caller_counts(trace_list, name):
    """{caller routine: calls} from the traces: the routine of the instruction before the entry"""
    own = eprof.Owners()
    out = Counter()
    for rec, window in trace_list:
        path = os.path.join(S.work(rec), 'traces', window.replace(':', '_') + '.uatr')
        if not os.path.isfile(path):
            continue
        t = eprof.load(S.work(rec), window)
        ins = t.instructions
        for i in range(1, len(ins)):
            if ins[i].pc == ENTRY[name] and not ins[i].interrupted:
                k = i - 1  # the instruction that came here: a CALL, a jump or a fall-through
                op = eprof.opcode(ins[k])
                if op[:2] in ([0xED, 0x4D], [0xED, 0x45]) or own(ins[k].pc) == 'IM2Handler':  # an interrupt returned just before
                    while k > 0 and not ins[k].interrupted:
                        k -= 1
                    k -= 1
                out[own(ins[k].pc)] += 1
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check-only', action='store_true')
    a = ap.parse_args()
    res = check()
    for name in ENTRY:
        r = res[name]
        assert r[0] and r[0] == r[1], '%s: %d of %d calls match' % (name, r[1], r[0])
    if a.check_only:
        return
    out = 'docs/img/runtime/'
    N = 1 << 16

    # the seeds the game starts from
    star_seed = res['StarRandom'][3][0][0]
    rnd_seed = 0xF562  # RandomSeed's value in the image
    # DataScreenDescription: TextSeeds = SelectedSeeds+2..+5, the system's s1 and s2
    lave = [s for s in G.systems(1) if s['name'] == 'Lave'][0]['seeds']
    text_seed = [lave[1] & 0xFF, lave[1] >> 8, lave[2] & 0xFF, lave[2] >> 8]

    streams = {
        'StarRandom (carry 0, as StarRespawn calls it)': run16(star_seed, 0, N),
        'Random (carry 0, as 38 of 45 traced calls)': run16(rnd_seed, 0, N),
        'TextRandom (from Lave\'s seeds)': run_text(text_seed, N),
        'Twist (s2 high byte, galaxy 1 walk)': None,
    }
    s = G.galaxy_seeds()
    tw = np.empty(N, dtype=np.uint8)
    for i in range(N):
        s = G.twist(s)
        tw[i] = s[2] >> 8
    streams['Twist (s2 high byte, galaxy 1 walk)'] = tw

    # the periods
    cyc0, nxt0, on0 = cycles16(0)
    cyc1, nxt1, on1 = cycles16(1)
    tail0, per0 = seed_orbit(nxt0, on0, star_seed)
    tailr, perr = seed_orbit(nxt0, on0, rnd_seed)
    tp = text_period(text_seed, 1 << 22)
    twp = twist_period(G.galaxy_seeds(), 1 << 20)
    print('16-bit step, carry 0: cycles', sorted(cyc0.items(), key=lambda kv: -kv[0])[:8])
    print('16-bit step, carry 1: cycles', sorted(cyc1.items(), key=lambda kv: -kv[0])[:8])
    print('StarSeed %04X: tail %d, cycle %d (carry 0)' % (star_seed, tail0, per0))
    print('RandomSeed %04X: tail %d, cycle %d (carry 0)' % (rnd_seed, tailr, perr))
    # the chained carry: a 17-bit state
    st = (rnd_seed, 0)
    seen = {}
    k = 0
    while st not in seen:
        seen[st] = k
        h, l = st[0] >> 8, st[0] & 0xFF
        _a, h, l, c = step16(h, l, st[1])
        st = (h << 8 | l, c)
        k += 1
    print('Random chained from %04X: tail %d, period %d' % (rnd_seed, seen[st], k - seen[st]))
    chained = (seen[st], k - seen[st])
    print('TextRandom from Lave:', tp)
    print('Twist from galaxy 1 seeds: period', twp)

    # 1. histograms
    fig, axes = P.figure(13, 7.5, nrows=2, ncols=2)
    for ax, (label, v) in zip(axes.flat, streams.items()):
        c2, h = chi2(v)
        ax.bar(range(256), h, width=1.0, color=P.READ, edgecolor='none')
        ax.axhline(len(v) / 256, color=P.WRITE, lw=1, ls='--')
        ax.set_xlim(0, 256)
        ax.set_title('%s\nchi-square %.0f (255 degrees: 255 +- 23 is uniform)' % (label, c2), fontsize=10)
        ax.set_xlabel('the byte (A)')
        ax.set_ylabel('count in %d' % len(v))
        ax.grid(True, axis='y', lw=0.4)
    fig.suptitle('Four generators, 65536 bytes each: the 16-bit step is flatter than chance (its 31319-seed cycle '
                 'visits each seed once),\nTextRandom is as flat as chance, the twist\'s s2 high byte is lumpy',
                 fontsize=13)
    fig.tight_layout()
    P.save(fig, out + 'prng-histograms.png')

    # 2. pairs (x_n, x_n+1)
    fig, axes = P.figure(13, 13.6, nrows=2, ncols=2)
    for ax, (label, v) in zip(axes.flat, streams.items()):
        img = np.zeros((256, 256))
        np.add.at(img, (v[1:].astype(int), v[:-1].astype(int)), 1)
        filled = int((img > 0).sum())
        ax.imshow(np.log1p(img), origin='lower', cmap='magma', interpolation='nearest')
        ax.set_title('%s\n%d of 65536 pairs occur' % (label, filled), fontsize=10)
        ax.set_xlabel('byte n')
        ax.set_ylabel('byte n + 1')
    fig.suptitle('Successive pairs: the 16-bit step reaches 31319 of the 65536 pairs, in stripes; TextRandom and '
                 'the twist reach 41400,\nas many as random bytes would (65536 x (1 - 1/e) = 41427)', fontsize=13)
    fig.tight_layout()
    P.save(fig, out + 'prng-pairs.png')

    # 3. bitmaps: 4096 bytes as 256 x 128 pixels (each byte 8 pixels, 32 bytes a row)
    fig, axes = P.figure(13, 4.2, nrows=1, ncols=4)
    for ax, (label, v) in zip(axes.flat, streams.items()):
        bits = np.unpackbits(v[:32 * 256]).reshape(256, 256)
        ax.imshow(bits, cmap='gray', interpolation='nearest')
        ax.set_title(label.split(' (')[0] + '\nthe first 8192 bytes', fontsize=10)
        ax.set_xticks([])
        ax.set_yticks([])
    fig.suptitle('The sequences as bits, 32 bytes a row: no stripe or diagonal at this scale, the 16-bit step\'s '
                 'flaw shows only in the pairs', fontsize=12)
    fig.tight_layout()
    P.save(fig, out + 'prng-bits.png')

    # 4. the cycles of the 16-bit step (carry 1 gives the same lengths)
    assert cyc0 == cyc1
    fig, ax = P.figure(10, 4.6)
    items = sorted(cyc0.items())
    ax.bar(range(len(items)), [n for _, n in items], color=P.EXEC)
    ax.set_yscale('log')
    ax.set_xticks(range(len(items)))
    ax.set_xticklabels(['cycle of %d' % L for L, _ in items])
    for i, (L, n) in enumerate(items):
        ax.text(i, n, '%d state%s' % (n, '' if n == 1 else 's'), ha='center', va='bottom', fontsize=9)
    ax.set_ylabel('states on the cycle (log)')
    ax.set_ylim(0.5, 100000)
    ax.set_title('The 16-bit step (StarRandom, Random) with a fixed carry: 32768 of the 65536 seeds lie on six cycles, '
                 'the rest lead into them;\nStarSeed %04X and RandomSeed %04X both lie on the cycle of %d (carry 1 '
                 'gives the same six lengths)' % (star_seed, rnd_seed, per0), fontsize=11)
    fig.tight_layout()
    P.save(fig, out + 'prng-cycles.png')

    # 5. who calls them, how often
    calls = {n: caller_counts(TRACES, n) for n in ENTRY}
    fig, axes = P.figure(9.6, 6, nrows=1, ncols=2)
    ax = axes[0]
    names = list(ENTRY)
    cols = P.colours(names)
    width = 0.2
    labels = [sc[1] for sc in S.SCENES]
    for k, n in enumerate(names):
        vals = []
        for sc in S.SCENES:
            p = S.profile(sc)
            fr = p['frames'][1] - p['frames'][0]
            vals.append(p['routines'].get(n, {}).get('calls', 0) / fr)
        ax.barh(np.arange(len(labels)) + (k - 1.5) * width, vals, height=width, color=cols[n], label=n)
        for i, v in enumerate(vals):
            if v:
                ax.text(v, i + (k - 1.5) * width, ' %.1f' % v, va='center', fontsize=8.5)
    ax.set_yticks(range(len(labels)))
    ax.set_yticklabels(labels)
    ax.invert_yaxis()
    ax.set_xscale('symlog', linthresh=1)
    ax.set_xlabel('calls a frame (log above 1)')
    ax.legend(fontsize=8.5, loc='upper center', bbox_to_anchor=(0.45, -0.12), ncol=2, frameon=False)
    ax.set_title('Calls a frame per scene', fontsize=10)
    ax = axes[1]
    rows = []
    for n in names:
        for caller, c in calls[n].most_common(4):
            rows.append(('%s <- %s' % (n, caller), c, cols[n]))
    ax.barh(range(len(rows)), [r[1] for r in rows], color=[r[2] for r in rows])
    for i, r in enumerate(rows):
        ax.text(r[1], i, ' %d' % r[1], va='center', fontsize=8.5)
    ax.set_yticks(range(len(rows)))
    ax.set_yticklabels([r[0] for r in rows], fontsize=9)
    ax.invert_yaxis()
    ax.set_xscale('log')
    ax.set_xlabel('calls in the traced windows (log)')
    ax.set_title('The callers (the routine that came in: CALL, jump or fall-through)', fontsize=10)
    fig.suptitle('Who draws random numbers: StarRandom when a dust dot respawns, Random when a ship is made, hit or '
                 'aimed,\nTwist when a chart, a name or a jump walks the galaxy (1024 twists a walk of 256 systems)',
                 fontsize=12)
    fig.tight_layout()
    P.save(fig, out + 'prng-callers.png')

    # the summary for the doc
    print('| generator | calls checked | match | carry in 0 / 1 |')
    for n in names:
        r = res[n]
        print('| %s | %d | %d | %d / %d |' % (n, r[0], r[1], r[2][0], r[2][1]))
    for n in names:
        print(n, 'callers', calls[n].most_common(6))
    print('chained Random', chained)


if __name__ == '__main__':
    main()
