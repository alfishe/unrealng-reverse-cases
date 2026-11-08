#!/usr/bin/env python3
"""Where the time goes per scene (docs/runtime-analysis.md, sections 2 and 3), from the profiles of tools/rtscenes.py.

    python3 tools/fig_rt_scenes.py

Figures (docs/img/runtime/):
- scenes-modules.png: one stacked bar a scene, the T-states of the window by module (self time), HALT apart;
- scenes-top.png: the top routines of six scenes, a bar chart each;
- scenes-rate.png: the frames a 3D update takes per scene against the ships in flight, and the HALT share;
- combat-routines.png: the 28 heaviest routines of the fight, self and inclusive T a frame.
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rtplot as P  # noqa: E402
import rtscenes as S  # noqa: E402



def by_module(p):
    out = {}
    for n, v in p['routines'].items():
        m = P.module(v['module'])
        if m.startswith('data:'):
            m = 'other'
        out[m] = out.get(m, 0) + v['self']
    return out


def main():
    profs = [(sc, S.profile(sc)) for sc in S.SCENES]
    # module order by the total share
    tot = {}
    for _sc, p in profs:
        for m, t in by_module(p).items():
            tot[m] = tot.get(m, 0) + t / p['total_t']
    order = [m for m, _ in sorted(tot.items(), key=lambda kv: -kv[1]) if m != 'halt']
    major = order[:13]
    cols = P.colours(major, {'halt': P.OTHER})
    cols['other'] = (0.45, 0.45, 0.5)

    # 1. stacked by module
    fig, ax = P.figure(13, 6.4)
    labels = [sc[1] for sc, _p in profs]
    left = np.zeros(len(profs))
    for m in major + ['other', 'halt']:
        vals = []
        for _sc, p in profs:
            bm = by_module(p)
            if m == 'other':
                v = sum(t for k, t in bm.items() if k not in major and k != 'halt')
            else:
                v = bm.get(m, 0)
            vals.append(100 * v / p['total_t'])
        vals = np.array(vals)
        ax.barh(range(len(profs)), vals, left=left, color=cols[m], label=P.module_label(m),
                edgecolor=P.BACKGROUND, lw=0.5)
        for i, v in enumerate(vals):
            if v >= 4.5:
                ax.text(left[i] + v / 2, i, '%.0f' % v, ha='center', va='center', fontsize=8, color='black')
        left += vals
    ax.set_yticks(range(len(profs)))
    ax.set_yticklabels(['%s\n%s %s' % (sc[1], sc[2], sc[3].replace(':0', '')) for sc, _p in profs], fontsize=8)
    ax.invert_yaxis()
    ax.set_xlim(0, 100)
    ax.set_xlabel('% of the window\'s T-states (self time, the number in a block is its %)')
    ax.legend(ncol=1, fontsize=8, loc='center left', bbox_to_anchor=(1.01, 0.5))
    ax.set_title('Where the time goes per scene: the back buffer copy is a fifth to a quarter of every flight frame; '
                 'docked the loop spins on the keys;\nthe launch, the tunnel and the death are half sound, played '
                 'with the CPU held', fontsize=11)
    fig.tight_layout()
    P.save(fig, 'docs/img/runtime/scenes-modules.png')

    # 2. the top routines of six scenes, small multiples of bars (the same routine the same colour everywhere)
    keys = ['title', 'galaxy', 'station', 'deep', 'combat', 'death']
    fig, axes = P.figure(9, 11, nrows=3, ncols=2)
    allnames = []
    for k in keys:
        p = S.profile(S.scene(k))
        allnames += [n for n, _v in sorted(p['routines'].items(), key=lambda kv: -kv[1]['self'])[:7]]
    rcols = P.colours(dict.fromkeys(allnames), {'HALT': P.OTHER})
    for ax, k in zip(axes.flat, keys):
        sc = S.scene(k)
        p = S.profile(sc)
        rs = sorted(p['routines'].items(), key=lambda kv: -kv[1]['self'])
        top = rs[:7]
        rest = p['total_t'] - sum(v['self'] for _n, v in top)
        vals = [100 * v['self'] / p['total_t'] for _n, v in top] + [100 * rest / p['total_t']]
        names = [n for n, _v in top] + ['the rest (%d)' % (len(rs) - 7)]
        cl = [rcols[n] for n, _v in top] + [(0.3, 0.3, 0.36)]
        ys = range(len(vals))
        ax.barh(ys, vals, color=cl, height=0.7)
        for y, v in zip(ys, vals):
            ax.text(v + 1, y, '%.1f' % v, va='center', fontsize=8.5, color=P.TEXT)
        ax.set_yticks(list(ys))
        ax.set_yticklabels(names, fontsize=8.5)
        ax.invert_yaxis()
        ax.set_xlim(0, 75)
        ax.tick_params(axis='x', labelsize=8)
        ax.set_title('%s (%s %s)' % (sc[1], sc[2], sc[3].replace(':0', '')), fontsize=9.5, loc='left')
    for ax in axes[-1]:
        ax.set_xlabel('% of the window\'s T-states (self)', fontsize=9)
    fig.suptitle('The seven heaviest routines of six scenes (self T): CopyThird leads every\n3D scene, '
                 'SoundPulses the death, CopyRates the docked spin', fontsize=11)
    fig.tight_layout()
    P.save(fig, 'docs/img/runtime/scenes-top.png')

    # 3. frames an update against ships
    fig, axes = P.figure(13, 4.6, nrows=1, ncols=2)
    ax = axes[0]
    pts = []
    for sc, p in profs:
        m = S.summary(p)
        if not m['updates']:
            continue
        sh = S.ships(sc[2], sc[3]) or 0
        pts.append((sc[1], sh, m['frames_per_update'], m['halt']))
    for i, (lab, sh, fpu, _h) in enumerate(pts):
        ax.scatter(sh, fpu, s=60, color=P.PALETTE[i % len(P.PALETTE)], zorder=3)
        ax.annotate('%s %.2f' % (lab, fpu), (sh, fpu), textcoords='offset points', xytext=(6, -3), fontsize=8)
    ax.set_xlabel('occupied ship slots (mean over the window; the station and the planet\'s slot count)')
    ax.set_ylabel('TV frames a 3D update (frames / ClearView calls)')
    ax.set_ylim(0, 18)
    ax.set_xlim(-0.3, 6.5)
    ax.grid(True, lw=0.4)
    ax.set_title('Frames a 3D update: 5 in empty space, 6.5 with four Thargoids;\nthe sound effects stretch it '
                 '(the death 16.7: SoundPulses runs with the interrupts off)', fontsize=10)
    ax = axes[1]
    labs = [sc[1] for sc, _p in profs]
    halts = [100 * S.summary(p)['halt'] for _sc, p in profs]
    ax.barh(range(len(labs)), halts, color=P.OTHER, edgecolor=P.DIM)
    for i, h in enumerate(halts):
        ax.text(h, i, ' %.1f %%' % h, va='center', fontsize=8)
    ax.set_yticks(range(len(labs)))
    ax.set_yticklabels(labs, fontsize=8)
    ax.invert_yaxis()
    ax.set_xlabel('% of the window spent in HALT')
    ax.set_xlim(0, 12)
    ax.set_title('The idle share: at most 9 %, all of it in CloakKey\'s HALT (every second pass);\n'
                 'docked and on the charts there is no HALT at all', fontsize=10)
    fig.tight_layout()
    P.save(fig, 'docs/img/runtime/scenes-rate.png')

    # 4. the fight's routines, self and inclusive
    sc = S.scene('combat')
    p = S.profile(sc)
    frames = p['frames'][1] - p['frames'][0]
    rs = sorted(((n, v) for n, v in p['routines'].items() if n not in ('IM2Handler',)),
                key=lambda kv: -kv[1]['self'])[:28]
    fig, ax = P.figure(12, 8.5)
    y = np.arange(len(rs))
    mcols = P.colours(major, {'halt': P.OTHER})
    ax.barh(y, [v['incl'] / frames for _n, v in rs], color=(0.3, 0.3, 0.38), label='inclusive (with its callees '
            'and any interrupt inside)')
    ax.barh(y, [v['self'] / frames for _n, v in rs], color=[mcols.get(P.module(v['module']), (0.5, 0.5, 0.55)) for _n, v in rs],
            label='self, coloured by module')
    for i, (n, v) in enumerate(rs):
        ax.text(v['incl'] / frames, i, ' %d / %d T, %d calls' % (v['self'] / frames, v['incl'] / frames,
                                                                 v['calls']), va='center', fontsize=7.5)
    ax.set_yticks(y)
    ax.set_yticklabels([n for n, _v in rs], fontsize=8)
    ax.invert_yaxis()
    ax.axvline(S.FRAME_T, color=P.WRITE, lw=0.8, ls='--')
    ax.text(S.FRAME_T, len(rs) - 1, ' one frame, 69888 T', color=P.WRITE, fontsize=8, va='bottom')
    ax.set_xscale('log')
    ax.set_xlim(300, 300000)
    ax.set_xlabel('T-states a TV frame (log), averaged over %d frames' % frames)
    ax.legend(fontsize=8, loc='lower right')
    ax.set_title('The fight with four Thargoids (w1 3470-3620): the 28 heaviest routines; the laser\'s sweep '
                 '(SoundSweep) and Divide16 cost more than the line drawing', fontsize=11)
    fig.tight_layout()
    P.save(fig, 'docs/img/runtime/combat-routines.png')


if __name__ == '__main__':
    main()
