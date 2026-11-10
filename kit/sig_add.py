#!/usr/bin/env python3
"""Add entries to the signature base (docs/signature-format.md) from a finished case.

    python3 kit/sig_add.py ann --case games/nether-earth --program "Nether Earth" --authors "Argus Press Software" \
        --year 1987 [--lst build/game.lst] [--bank N] [--modules a,b]
        [--part src/<part>/<name>.json [--segment N] --prefix PART]
    python3 kit/sig_add.py lst --case games/advanced-nether-earth --lst build/music/boot-music.lst \
        --start Pt3Init --end Pt3Module --id sound/ay-players/pro-tracker-3/nick-gdc-1.0 --meta META.json \
        --program "Advanced Nether Earth" [--nth N] [--image FILE --image-origin ADDR] [--bank N]
    python3 kit/sig_add.py sources [signatures/sources.json]     # every addition the file lists, in order

ann: one entry per module of the case's annotations (case.json's game.ann and image, or a part file's image and
.ann: --part, one segment of it with --segment), under programs/games/<case>/<module> (<prefix>-<module> with
--prefix, for the parts of a case whose module names repeat). The instruction starts come from the build's listing (--lst) when given, else from
the annotations' code entries decoded in a line; the mask from the 16-bit operands (inside the module rel16, the ROM
unmasked, the rest ext16, named by the annotations) and from the word entries that point inside the module.

lst: one entry from a sjasmplus listing, label --start to label --end; the metadata (kind, role, name, authors, year,
tags, summary, relocatable, entries by label, uses, docs, notes, variants) from --meta.

A piece that matches an entry already in the base (exact, or masked with its rel16 words consistent) becomes one
more found_in item of that entry, not a new entry. Run again, an addition rewrites its own entry and keeps the
found_in items other additions gave it.
"""
import argparse
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import siglib as S  # noqa: E402


def commit():
    r = subprocess.run(['git', '-C', S.REPO, 'rev-parse', '--short', 'HEAD'], capture_output=True, text=True)
    return r.stdout.strip() or None


def rel(path):
    return os.path.relpath(os.path.abspath(path), S.REPO).replace(os.sep, '/')


def find_existing(data, origin):
    """an entry of the same length that the piece matches: (path, sig, hit)"""
    for path in S.entry_dirs():
        sig, ref = S.load_entry(path)
        if ref is None or len(ref) != len(data):
            continue
        hit = S.match_at(sig, ref, data, 0, origin)
        if hit and hit['match'] in ('exact', 'masked'):
            return path, sig, hit
    return None


def store(sig, data, place, quiet=False):
    """write sig as a new entry, or add place to the found_in of an entry the bytes match"""
    if not S.anchors(data, sig):
        print(f'{sig["id"]}: skipped, no anchor (fills or zeros: nothing to find it by)')
        return None
    path = os.path.join(S.BASE, *sig['id'].split('/'))
    same = lambda f: f.get('case') == place.get('case') and f.get('address') == place.get('address') and \
        f.get('bank') == place.get('bank')
    if os.path.exists(os.path.join(path, 'sig.json')):
        old, _ = S.load_entry(path)
        if old['found_in'] and same(old['found_in'][0]):
            if old.get('bytes', {}).get('sha1') == sig['bytes']['sha1']:
                place = dict(place, commit=old['found_in'][0].get('commit'))  # the same bytes: keep where they came from
            sig['found_in'] = [place] + [f for f in old['found_in'][1:]]
            for k in ('variants',):
                if k in old and k not in sig:
                    sig[k] = old[k]
            S.save_entry(path, sig, data)
            if not quiet:
                print(f'{sig["id"]}: rewritten ({len(data)} bytes, {len(sig["mask"])} masked)')
            return sig['id']
    found = find_existing(data, S.addr(sig['origin']))
    if found:
        epath, esig, hit = found
        place = dict(place, delta=hit['delta'], match=hit['match'])
        kept = [f for f in esig['found_in'] if same(f)]
        if kept:
            place = dict(place, commit=kept[0].get('commit'))
        esig['found_in'] = [f for f in esig['found_in'] if not same(f)] + [place]
        S.save_entry(epath, esig)
        print(f'{sig["id"]}: the same piece as {esig["id"]} ({hit["match"]}, delta {hit["delta"]}): found_in added')
        return esig['id']
    if os.path.exists(os.path.join(path, 'sig.json')):
        old, _ = S.load_entry(path)
        sys.exit(f'{sig["id"]}: an entry from {old["found_in"][0].get("case")} {old["found_in"][0].get("address")}'
                 ' is there and the bytes differ: give this one another variant')
    S.save_entry(path, sig, data)
    print(f'{sig["id"]}: new ({len(data)} bytes, {len(sig["mask"])} masked)')
    return sig['id']


def finish(sig, data):
    sig['bytes'] = {'file': 'data.bin' if sig['kind'] == 'data' else 'code.bin', 'length': len(data),
                    'sha1': S.sha1(data), 'masked_sha1': S.sha1(S.masked_bytes(data, sig))}
    order = ['schema', 'id', 'kind', 'role', 'name', 'authors', 'year', 'tags', 'summary', 'bytes', 'origin',
             'relocatable', 'mask', 'entries', 'labels', 'uses', 'found_in', 'source', 'variants', 'docs', 'notes']
    return {k: sig[k] for k in order if k in sig}


# ---- ann

def kebab(name):
    return re.sub(r'(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])', '-', name).replace('_', '-').lower()


def module_segments(ann, hi):
    """[(module, title, start, end)]: as kit/mkgame.py cuts them, from each module's first entry to the next
    module's, in address order"""
    mods = sorted(ann.modules)
    return [(name, ann.module_info[name][0], start, mods[k + 1][0] if k + 1 < len(mods) else hi)
            for k, (start, name) in enumerate(mods)]


def add_ann(args):
    case = os.path.abspath(args.case)
    mk = S.kit_import('mkgame')
    if args.part:
        # a part file (docs/ann-format.md 5.2): its image at its address, its .ann (or one segment's) and range
        mk.ROOT = case
        part = json.load(open(os.path.join(case, args.part)))
        mem, data, at = mk.part_image(dict(part, image_always=False))
        segs = part.get('segments') or [{}]
        seg = segs[args.segment]
        if 'lines' in seg or mk.hexa(seg.get('run', seg.get('lo', '0'))) != mk.hexa(seg.get('lo', '0')):
            sys.exit(f'{args.part}: segment {args.segment} is not an annotated image at its run address')
        ann_path = seg.get('ann') or part['ann']
        lo = mk.hexa(seg.get('lo') or part.get('lo') or '%X' % at)
        hi = mk.hexa(seg.get('hi') or part.get('hi') or '%X' % (at + len(data)))
        mk.LO, mk.HI = lo, hi
        nested = part.get('segments') and part.get('subdir', True)  # the modules in a folder of their own
        top = None if nested else (part.get('top') or part.get('name') or 'game')
        ann = mk.Annotations(os.path.join(case, ann_path), piece=seg.get('piece'), top=top)
        args.ann = ann_path
        module_dir = part.get('dest') or os.path.dirname(ann_path)
        if part.get('segments') and part.get('subdir', True):
            module_dir += '/' + (part.get('top') or part.get('name'))
    else:
        module_dir = None
        config = json.load(open(os.path.join(case, args.config)))
        mk.LO, mk.HI = int(config['lo'], 16), int(config.get('hi', '10000'), 16)
        image_path = os.path.join(case, args.image or config['image'])
        if not os.path.exists(image_path):
            subprocess.run(config['image_cmd'], cwd=case, check=True)  # the command runs in the case, as mkgame's
        mem = open(image_path, 'rb').read()
        ann = mk.Annotations(os.path.join(case, args.ann), top='game')
    lo, hi = mk.LO, mk.HI
    rows = S.read_listing(os.path.join(case, args.lst)) if args.lst else None
    listed_starts = {r['address'] for r in rows if r['instruction'] and lo <= r['address'] < hi} if rows else None
    names = {a: ann.name(a) for a in list(ann.entries) + list(ann.inline) if ann.name(a)}
    names.update({a: n for a, (n, size, c) in ann.equ.items()})
    slug = os.path.basename(case)
    segs = module_segments(ann, hi)
    count = {}
    wanted = set(args.modules.split(',')) if args.modules else None
    for module, title, start, end in segs:
        count[module] = count.get(module, 0) + 1
        if wanted and module not in wanted:
            continue
        data = mem[start:end]
        addrs = sorted(a for a in ann.entries if start <= a < end)
        if all(ann.entries[a][0] == 's' for a in addrs) or len(data) < S.MIN_UNMASKED:
            print(f'{module} {S.hexaddr(start)}-{S.hexaddr(end - 1)}: skipped ({len(data)} bytes'
                  f'{", space only" if all(ann.entries[a][0] == "s" for a in addrs) else ""})')
            continue
        name = module if count[module] == 1 else f'{module}-{kebab(ann.entries[addrs[0]][1] or S.hexaddr(start)[1:])}'
        if args.prefix:
            name = f'{args.prefix}-{name}'
        starts, words = [], []
        for i, a in enumerate(addrs):
            kind, ename, width, etitle = ann.entries[a]
            stop = addrs[i + 1] if i + 1 < len(addrs) else end
            if kind == 'c':
                if listed_starts is not None:
                    starts += [x - start for x in range(a, stop) if x in listed_starts]
                else:
                    x = a
                    while x < stop:
                        starts.append(x - start)
                        n, targets, falls, call = mk.decode(mem, x)
                        x += n
                        fixed = [ann.inline_len[t] for t in targets if call and t in ann.inline_len]
                        if fixed:
                            x += fixed[0]  # a fixed count of data bytes after the CALL, then code again
                            continue
                        if call and any(t in ann.inline_data for t in targets):
                            break  # the bytes after a CALL to an inline-data routine are data
            elif kind == 'w':
                words += list(range(a - start, stop - start - 1, 2))
        mask = S.build_mask(data, start, starts, words, names)
        entries = [{'offset': a - start, 'name': ann.entries[a][1], 'in': None, 'out': None, 'clobbers': None,
                    'summary': ann.entries[a][3] or ''} for a in addrs if ann.entries[a][0] == 'c' and ann.entries[a][1]]
        labels = [{'offset': a - start, 'name': ann.entries[a][1] or '', 'comment': ann.entries[a][3] or ''}
                  for a in addrs if ann.entries[a][0] != 'c']
        labels += [{'offset': a - start, 'name': n or '', 'comment': c or ''}
                   for a, (n, c) in sorted(ann.inline.items()) if start <= a < end]
        labels.sort(key=lambda l: l['offset'])
        first = ann.entries[addrs[0]][1] if addrs else None
        kind = 'code' if any(ann.entries[a][0] == 'c' for a in addrs) else 'data'
        sig = {'schema': S.SCHEMA, 'id': f'programs/{args.family}/{slug}/{name}', 'kind': kind, 'role': 'game-module',
               'name': f'{args.program}: {module}' + ('' if count[module] == 1 else f', from {ann.entries[addrs[0]][1]}'),
               'authors': args.authors.split(',') if args.authors else [], 'year': args.year,
               'tags': [slug, 'game-module', module], 'summary': (title or module)[:1].upper() + (title or module)[1:] + '.',
               'origin': S.hexaddr(start), 'relocatable': False, 'mask': mask, 'entries': entries, 'labels': labels,
               'found_in': [{'program': args.program, 'case': rel(case), 'address': S.hexaddr(start),
                             'bank': args.bank, 'delta': '+$0000', 'match': 'exact', 'commit': commit()}],
               'source': {'case': rel(case),
                          'file': f'{module_dir or os.path.dirname(args.ann)}/{mk.module_file(module, ann.top)}.asm',
                          'label': first},
               'docs': [f'{rel(case)}/docs/README.md']}
        store(finish(sig, data), data, sig['found_in'][0])


# ---- lst

def add_lst(args):
    case = os.path.abspath(args.case)
    rows = S.read_listing(os.path.join(case, args.lst))
    image = open(os.path.join(case, args.image), 'rb').read() if args.image else None
    origin, data, starts, words, labels = S.listing_piece(
        rows, args.start, args.end, args.nth, image, S.addr(args.image_origin) if args.image else None)
    meta = args.meta if isinstance(args.meta, dict) else json.load(open(args.meta))
    names = {}
    by_label = {n: o for o, n, c in labels}
    local = lambda name: name[1:2].upper() + name[2:] if name.startswith('.') else name  # as listing_piece names them
    mask = S.build_mask(data, origin, starts, words if meta.get('mask_words', True) else (), names)
    for m in meta.get('extra_mask', []):
        o = by_label[local(m['label'])] + m.get('plus', 0) if 'label' in m else m['offset']
        mask = [x for x in mask if not (o <= x['offset'] < o + m['length'])]
        mask.append({k: v for k, v in dict(m, offset=o).items() if k in ('offset', 'length', 'kind', 'name')})
    mask.sort(key=lambda m: m['offset'])
    entries = []
    for e in meta.get('entries', [{'label': args.start}]):
        if local(e['label']) not in by_label:
            sys.exit(f'{args.id}: entry label {e["label"]} is not inside {args.start}-{args.end}')
        entries.append({'offset': by_label[local(e['label'])], 'name': e.get('name', local(e['label'])), 'in': e.get('in'),
                        'out': e.get('out'), 'clobbers': e.get('clobbers'), 'summary': e.get('summary', '')})
    sig = {'schema': S.SCHEMA, 'id': args.id, 'kind': meta.get('kind', 'code'), 'role': meta['role'],
           'name': meta['name'], 'authors': meta.get('authors', []), 'year': meta.get('year'),
           'tags': meta.get('tags', []), 'summary': meta['summary'], 'origin': S.hexaddr(origin),
           'relocatable': meta.get('relocatable', False), 'mask': mask, 'entries': entries,
           'labels': [{'offset': o, 'name': n, 'comment': c} for o, n, c in labels]}
    for k in ('uses', 'variants', 'docs', 'notes'):
        if k in meta:
            sig[k] = meta[k]
    sig['found_in'] = [{'program': args.program, 'case': rel(case), 'address': S.hexaddr(origin), 'bank': args.bank,
                        'delta': '+$0000', 'match': 'exact', 'commit': commit()}]
    sig['source'] = {'case': rel(case), 'file': meta.get('source_file', args.lst), 'label': args.start}
    copies = []
    for c in meta.get('copies', []):
        crows = S.read_listing(os.path.join(case, c['lst']))
        cimage = open(os.path.join(case, c['image']), 'rb').read() if c.get('image') else None
        corigin, cdata, *_ = S.listing_piece(crows, args.start, args.end, c.get('nth', 1), cimage,
                                             S.addr(c['image_origin']) if c.get('image') else None)
        if len(cdata) != len(data):
            sys.exit(f'{args.id}: the copy in {c["lst"]} is {len(cdata)} bytes, not {len(data)}')
        delta = (corigin - origin) & 0xFFFF
        masked = S.masked_offsets(sig)
        for o in range(len(data)):
            if o in masked or cdata[o] == data[o]:
                continue
            kind = 'rel8hi' if delta & 0xFF == 0 and (cdata[o] - data[o]) & 0xFF == delta >> 8 else 'var8'
            sig['mask'].append({'offset': o, 'length': 1, 'kind': kind})
            masked.add(o)
        sig['mask'].sort(key=lambda m: m['offset'])
        copies.append((cdata, {'program': c.get('program', args.program), 'case': rel(case),
                               'address': S.hexaddr(corigin), 'bank': c.get('bank'), 'delta': S.delta_text(delta),
                               'match': None, 'commit': commit()}))
    store(finish(sig, data), data, sig['found_in'][0])
    for cdata, place in copies:
        store(finish(dict(sig, origin=place['address'], found_in=[place]), cdata), cdata, place)


def add_sources(args):
    spec = json.load(open(args.file))
    for item in spec['additions']:
        ns = argparse.Namespace(**dict(DEFAULTS[item['mode']], **{k.replace('-', '_'): v for k, v in item.items()}))
        (add_ann if item['mode'] == 'ann' else add_lst)(ns)


DEFAULTS = {
    'ann': {'ann': 'src/game/game.ann', 'config': 'case.json', 'family': 'games', 'image': None, 'lst': None, 'bank': None, 'modules': None, 'authors': None,
            'year': None, 'part': None, 'segment': 0, 'prefix': None},
    'lst': {'nth': 1, 'image': None, 'image_origin': None, 'bank': None},
}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = p.add_subparsers(dest='mode', required=True)
    a = sub.add_parser('ann')
    a.add_argument('--case', required=True)
    a.add_argument('--program', required=True)
    a.add_argument('--authors')
    a.add_argument('--year', type=int)
    a.add_argument('--ann', default='src/game/game.ann')
    a.add_argument('--config', default='case.json', help='the case.json, relative to the case')
    a.add_argument('--family', default='games', help='games, demos or utilities')
    a.add_argument('--image')
    a.add_argument('--lst')
    a.add_argument('--bank', type=int)
    a.add_argument('--modules')
    a.add_argument('--part', help='a part file (src/<part>/<name>.json) instead of case.json')
    a.add_argument('--segment', type=int, default=0, help='the segment of the part file (default the first)')
    a.add_argument('--prefix', help='entry ids <prefix>-<module>: the parts of one case whose module names repeat')
    b = sub.add_parser('lst')
    b.add_argument('--case', required=True)
    b.add_argument('--lst', required=True)
    b.add_argument('--start', required=True)
    b.add_argument('--end', required=True)
    b.add_argument('--nth', type=int, default=1)
    b.add_argument('--id', required=True)
    b.add_argument('--meta', required=True)
    b.add_argument('--program', required=True)
    b.add_argument('--image')
    b.add_argument('--image-origin')
    b.add_argument('--bank', type=int)
    c = sub.add_parser('sources')
    c.add_argument('file', nargs='?', default=os.path.join(S.BASE, 'sources.json'))
    args = p.parse_args()
    {'ann': add_ann, 'lst': add_lst, 'sources': add_sources}[args.mode](args)


if __name__ == '__main__':
    main()
