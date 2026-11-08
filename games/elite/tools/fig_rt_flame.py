#!/usr/bin/env python3
"""Flame graphs per scene and the call graph weighted by time (docs/runtime-analysis.md, section 9).

    python3 tools/fig_rt_flame.py [--scenes combat,station,title,tunnel] [--mermaid combat [--threshold 0.015]]

A flame graph: the call stacks of the window (eprof's `folded`: the stack of each instruction, its T summed), the
root at the bottom, each box a routine called from the box under it, its width its inclusive T. An interrupt is a
box "IM2Handler" on top of whatever it cut. --mermaid prints the call graph of a scene as mermaid: the edges
heavier than 0.5 % of the window, labelled with the T spent in the callee a frame.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import matplotlib.patches as patches  # noqa: E402
import rtplot as P  # noqa: E402
import rtscenes as S  # noqa: E402


def tree(folded):
    root = {'t': 0, 'kids': {}}
    for stack, t in folded.items():
        node = root
        node['t'] += t
        for name in stack.split(';'):
            node = node['kids'].setdefault(name, {'t': 0, 'kids': {}})
            node['t'] += t
    return root


FIG_W = 10.0          # inches; at 100 dpi 1000 px, so a 9 pt label is about 11 px at 900 px
MIN_W = 0.004         # a box narrower than 0.4 % of the window is not drawn (a sliver says nothing)


def fits(label, w, size):
    """whether a label of `size` pt fits a box w wide (a share of the axis, FIG_W * 0.9 inches)"""
    return len(label) * size * 0.62 / 72 < w * FIG_W * 0.9 - 0.04


def draw(ax, node, x, depth, total, cols, out_depth):
    for name, kid in sorted(node['kids'].items(), key=lambda kv: -kv[1]['t']):
        w = kid['t'] / total
        if w < MIN_W:
            x += w
            continue
        ax.add_patch(patches.Rectangle((x, depth), w, 0.92, facecolor=cols(name), edgecolor=P.BACKGROUND, lw=0.4))
        room = int((w * FIG_W * 0.9 - 0.04) * 72 / (9 * 0.62))
        short = name[:room - 1] + '.' if room >= 10 else None       # a long name cut to its box
        for label in ('%s %.1f%%' % (name, 100 * w), name, short):
            if label and fits(label, w, 9):
                ax.text(x + w / 2, depth + 0.46, label, ha='center', va='center', fontsize=9, color='black')
                break
        out_depth[0] = max(out_depth[0], depth + 1)
        draw(ax, kid, x, depth + 1, total, cols, out_depth)
        x += w


def flame(scene_key):
    sc = S.scene(scene_key)
    p = S.profile(sc)
    root = tree(p['folded'])
    mods = {n: P.module(v['module']) for n, v in p['routines'].items()}
    weight = {}
    for n, v in p['routines'].items():
        weight[P.module(v['module'])] = weight.get(P.module(v['module']), 0) + v['self']
    order = [m for m in sorted(weight, key=lambda m: -weight[m]) if not m.startswith('data:')][:9]
    mcol = P.colours(order, {'halt': P.OTHER})
    other = (0.55, 0.55, 0.58)

    def cols(name):
        if name == 'IM2Handler':
            return (0.97, 0.97, 0.97)
        return mcol.get(mods.get(name, ''), other)

    depth = [0]
    fig, ax = P.figure(FIG_W, 4.6)
    draw(ax, root, 0.0, 0, root['t'], cols, depth)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, depth[0])
    ax.set_yticks([d + 0.46 for d in range(depth[0])])
    ax.set_yticklabels([str(d) for d in range(depth[0])], fontsize=9)
    ax.set_xticks([0, 0.25, 0.5, 0.75, 1])
    ax.set_xticklabels(['0', '25 %', '50 %', '75 %', '100 %'], fontsize=9)
    ax.set_xlabel('share of the T-states of %d frames (width = inclusive T)' % (p['frames'][1] - p['frames'][0]),
                  fontsize=9)
    ax.set_ylabel('call depth', fontsize=9)
    top = sorted(root['kids'].items(), key=lambda kv: -kv[1]['t'])[:3]
    ax.set_title('%s (%s %s): %s' % (sc[1], sc[2], sc[3].replace(':0', ''), ', '.join(
        '%s %.0f %%' % (n, 100 * k['t'] / root['t']) for n, k in top)), fontsize=10.5)
    handles = [patches.Patch(color=mcol[m], label=P.module_label(m, small=False)) for m in order]
    handles += [patches.Patch(color=other, label='other modules'),
                patches.Patch(color=(0.97, 0.97, 0.97), label='the interrupt (IM2Handler)')]
    ax.legend(handles=handles, ncol=4, fontsize=8.5, loc='upper center', bbox_to_anchor=(0.5, -0.17),
              frameon=False)
    P.save(fig, 'docs/img/runtime/flame-%s.png' % scene_key)


def mermaid(scene_key, threshold=0.005):
    sc = S.scene(scene_key)
    p = S.profile(sc)
    frames = p['frames'][1] - p['frames'][0]
    total = p['total_t']
    edges = [(k.split('>'), t) for k, t in p['edges'].items() if t / total >= threshold]
    # the window starts inside FlightLoop, so its calls are the stacks' roots: an edge from FlightLoop to each
    roots = {}
    for stack, t in p['folded'].items():
        r = stack.split(';')[0]
        if r not in ('FlightLoop', 'HALT', 'IM2Handler') and not r.startswith('data:'):
            roots[r] = roots.get(r, 0) + t
    edges += [(['FlightLoop', r], t) for r, t in roots.items() if t / total >= threshold]
    print('```mermaid')
    print('graph LR')
    for (a, b), t in sorted(edges, key=lambda e: -e[1]):
        print('    %s -->|%d T| %s' % (a, t // frames, b))
    print('```')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--scenes', default='combat,station,title,tunnel')
    ap.add_argument('--mermaid')
    ap.add_argument('--threshold', type=float, default=0.005, help='the smallest edge, a share of the window')
    a = ap.parse_args()
    if a.mermaid:
        mermaid(a.mermaid, a.threshold)
        return
    for k in a.scenes.split(','):
        flame(k)


if __name__ == '__main__':
    main()
