#!/usr/bin/env python3
"""The owner's boot variants built from the case's one source: a variant is src/res with some files replaced.

    python3 tools/variants.py extract [NAME ...]          # work/candidates -> variants/NAME/ (only what differs)
    python3 tools/variants.py build NAME [--sjasmplus P]  # build/variants/NAME/, compared with the candidate
    python3 tools/variants.py build --all                 # every variant, one line each
    python3 tools/variants.py index                       # build all and write variants/README.md
    tools/build.sh [SJASMPLUS] --variant NAME | --all      # the same through the build script

A variant folder variants/NAME/ holds:
- the resource files that differ from src/res, under the same names and in the same formats (graphics/logo.png,
  texts/menu-help.txt, ...); a file the converter cannot write back byte for byte stays NAME.bin;
- music/piece.bin when its music piece is not the original's (a whole compiled player and tune, kept as bytes: no
  converter reads these players yet);
- basic.bin when its BASIC sector is not the original's with the variant's music address and sector count;
- files/NN.NAME.T: the disk's other files, as bytes;
- variant.json: the candidate (image, file), the boot file's header, the music piece's address, entries and
  sectors, and the code additions (see CODE below);
- README.md: what differs, written by extract.

The code is never copied: a variant's code is the case's src/main with
- the music entries as constants (@const MusicInit, MusicPlay in src/main/main.ann; MusicPiece, MusicSectors in
  src/basic/basic.ann), set from variant.json "equ";
- "start": one more CALL into the music piece after CALL MusicInit (family B: CALL MusicStart, 3 bytes); every
  later address of the code piece moves by 3, which the labels follow (the build moves the code piece's ORG lines).
Whatever else differs is listed in the README as a code difference and the build reports it.
"""
import argparse
import glob
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import disk  # noqa: E402
import res_formats  # noqa: E402

CAND = os.path.join(ROOT, 'work', 'candidates', 'owner-boots_zyx')
VAR = os.path.join(ROOT, 'variants')
CODE, CODE_END, GFX, GFX_END = 0x61A8, 0x61A8 + 15 * 256, 0xA600, 0xAE00
START_AT = 0x61EA          # the instruction after CALL MusicInit: family B's extra CALL goes here
SHIFT = 3
MAIN_EQU = ('MusicInit', 'MusicPlay', 'MusicStart', 'MenuStack', 'Im2Table', 'Im2Jump', 'ScreenCopy', 'ScreenCopyHigh', 'GlintEdge', 'GlintCentre')
WHERE = {'MenuStack': "the menu's stack", 'Im2Table': 'the IM 2 vector table', 'Im2Jump': "the interrupt's JP",
         'ScreenCopy': 'the clean screen copy',
         'ScreenCopyHigh': 'the OR mask from a screen address to the copy',
         'GlintEdge': "the glint's outer cells' attribute", 'GlintCentre': "the glint's middle cell's attribute"}
ORIG_EQU = {'MenuStack': '$FCBC', 'Im2Table': '$FD00', 'Im2Jump': '$FCFC', 'ScreenCopy': '$E000', 'ScreenCopyHigh': '$E0', 'GlintEdge': '$02', 'GlintCentre': '$42'}


def boots():
    """(variant name, image path, file) for every boot of 20 sectors or more on the owner's images"""
    for im in sorted(glob.glob(os.path.join(CAND, '*')), key=str.lower):
        files, _ = disk.read(im)
        bs = [f for f in files if f['type'] == 'B' and f['sectors'] >= 20]
        stem = os.path.splitext(os.path.basename(im))[0].lower()
        if not bs:
            bs = [f for f in files if f['type'] == 'B']
        for f in bs:
            name = stem
            if len(bs) > 1:
                name = '%s-%02d' % (stem, int(f['name'].strip().split('-')[-1]))
            yield name, im, f, files


def res_entries(part='main', last_end=GFX_END):
    """{res name: (first, end)} from src/PART/PART.ann (an entry ends at the next entry)"""
    ents, res = [], {}
    for line in open(os.path.join(ROOT, 'src', part, part + '.ann')):
        m = re.match(r'\$([0-9A-F]{4}) [a-z] \w+', line)
        if m:
            ents.append(int(m.group(1), 16))
            continue
        m = re.match(r'@res (\S+)', line)
        if m:
            res.setdefault(m.group(1), []).append(ents[-1])
    ents.sort()
    out = {}
    for name, starts in res.items():
        last = max(starts)
        end = next((a for a in ents if a > last), last_end)
        out[name] = (min(starts), end)
    return out


def original():
    o = disk.read(os.path.join(ROOT, 'orig', 'boot.scl'))[0][0]['body']
    img = bytearray(65536)
    img[CODE:CODE_END] = o[256:4096]
    img[GFX:GFX_END] = o[4096:6144]
    return o, img


def reads(basic):
    """the loader's (address, sectors) reads: LD HL,nn ... LD BC,$ss05 ... CALL $3D13"""
    out = []
    for m in re.finditer(rb'\x21(..)(?:\xed\x5b\xf4\x5c)?\x01\x05(.)\xcd\x13\x3d', basic, re.S):
        out.append((m.group(1)[0] | m.group(1)[1] << 8, m.group(2)[0]))
    return out


def word(b, a):
    return b[a] | b[a + 1] << 8


def editable(name, data):
    """(file name under the res folder, bytes) of a resource, in its editable form when it round-trips"""
    m = res_formats.converter(name)
    if m:
        try:
            suffix, out = m.to_editable(name, data)
            if m.from_editable(name, out) == data:
                return name[:-4] + suffix, out
        except Exception:  # noqa: BLE001 - a variant's bytes the format does not cover stay bytes
            pass
    return name, data


def basic_bytes(asm, equ, work, res):
    """the original BASIC sector assembled with the variant's music constants (and the resources in res)"""
    shutil.rmtree(work, ignore_errors=True)
    shutil.copytree(res, os.path.join(work, 'res'))
    for f in glob.glob(os.path.join(ROOT, 'src', 'basic', '*.asm')):
        shutil.copy(f, work)
    set_equ(os.path.join(work, 'basic.asm'), equ)
    run_asm(asm, os.path.join(work, 'basic.asm'), work)
    return open(os.path.join(work, 'basic.bin'), 'rb').read()


def set_equ(path, equ):
    s = open(path).read()
    for k, v in equ.items():
        s, n = re.subn(r'^(%s\s+EQU\s+)\S+' % k, lambda m: m.group(1) + v, s, flags=re.M)
        if not n and k == 'MusicStart':
            s = s.replace('\n  ORG ', '\nMusicStart EQU %s  ; the extra CALL of family B (variants)\n  ORG ' % v, 1)
    open(path, 'w').write(s)


def run_asm(asm, path, work):
    r = subprocess.run([asm, '--nologo', '--msg=war', '-I' + work, '--lst=' + os.path.splitext(path)[0] + '.lst',
                        '--sym=' + os.path.splitext(path)[0] + '.sym', path], cwd=work, capture_output=True, text=True)
    if r.returncode or r.stdout.strip() or r.stderr.strip():
        raise SystemExit('%s: %s%s' % (os.path.basename(path), r.stdout, r.stderr))


def shifted(a, start):
    return a + SHIFT if start and START_AT <= a < CODE_END - SHIFT else a


def extract(names, asm):
    o, img = original()
    entries = res_entries()
    entries.update(res_entries('basic', 0x5E3B))
    orig_res = {}
    tmp = os.path.join(ROOT, 'build', 'variants', '_orig-res')
    shutil.rmtree(tmp, ignore_errors=True)
    res_formats.build(tmp)
    for n in entries:
        orig_res[n] = open(os.path.join(tmp, n), 'rb').read()
    summary = []
    for name, im, f, files in boots():
        if names and name not in names:
            continue
        body = f['body'][:f['sectors'] * 256]
        rd = reads(body[:256])
        vdir = os.path.join(VAR, name)
        shutil.rmtree(vdir, ignore_errors=True)
        os.makedirs(vdir)
        cfg = {'image': os.path.relpath(im, ROOT), 'file': f['name'],
               'header': {'type': f['type'], 'start': f['start'], 'length': f['length'], 'sectors': f['sectors']}}
        notes = []
        if [a for a, _ in rd][:2] != [CODE, GFX] or [s for _, s in rd][:2] != [15, 8] or len(rd) != 3:
            cfg['loader'] = 'own'
            open(os.path.join(vdir, 'basic.bin'), 'wb').write(body[:256])
            notes.append('Its own loader (reads %s): not built from the source yet.' %
                         ', '.join('`$%04X` x %d' % r for r in rd) if rd else 'Its own loader: not built from the source yet.')
            write_variant(vdir, name, cfg, notes, [])
            summary.append((name, 'own loader'))
            continue
        v = bytearray(65536)
        v[CODE:CODE_END] = body[256:4096]
        v[GFX:GFX_END] = body[4096:6144]
        v[0x5D3B:0x5E3B] = body[:256]
        music = body[6144:]
        start = v[START_AT] == 0xCD and v[START_AT + 3:START_AT + 6] == bytes([0xCD, 0x13, 0x65])
        silent = v[0x61E7:0x61ED] == bytes(6) and v[0x61ED:0x61F0] == bytes([0xCD, 0x13, 0x65])
        start = start or silent
        code = code_switches(v, start) + (['no-music-init'] if silent else [])
        equ = {'MusicPiece': '$%04X' % rd[2][0], 'MusicSectors': str(rd[2][1]),
               'MusicInit': '$%04X' % word(v, 0x61EB if 'music-after-screen' in code else 0x61E8),
               'MusicPlay': '$%04X' % word(v, shifted(0x676E, start))}
        for k, val, orig in (('MenuStack', word(v, 0x61C6), 0xFCBC), ('Im2Table', v[0x61E4] << 8, 0xFD00),
                             ('Im2Jump', word(v, 0x61DF), 0xFCFC),
                             ('ScreenCopy', (v[shifted(0x6CA7, start)] ^ 0xFF ^ 0x40) << 8, 0xE000),
                             ('ScreenCopyHigh', v[shifted(0x6C87, start)], 0xE0),
                             ('GlintEdge', v[shifted(0x6DB8, start)], 0x02),
                             ('GlintCentre', v[shifted(0x6DC4, start)], 0x42)):
            if val != orig:
                equ[k] = ('$%02X' if val < 256 and k not in ('MenuStack', 'Im2Jump') else '$%04X') % val
        if code:
            cfg['code'] = code
        if silent:
            equ['MusicInit'] = equ['MusicStart'] = '$0000'
        elif start:
            equ['MusicStart'] = '$%04X' % word(v, START_AT + 1)
        if start:
            cfg['start'] = True
        cfg['equ'] = equ
        changed = []
        for n, (a, e) in sorted(entries.items()):
            data = bytes(v[shifted(a, start):shifted(a, start) + (e - a)])
            if data == orig_res[n]:
                continue
            fn, out = editable(n, data)
            path = os.path.join(vdir, fn)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, 'wb').write(out)
            changed.append(fn)
        if music != o[6144:6144 + len(music)] or rd[2] != (0xC000, 22):
            os.makedirs(os.path.join(vdir, 'music'), exist_ok=True)
            open(os.path.join(vdir, 'music', 'piece.bin'), 'wb').write(music)
            changed.append('music/piece.bin')
        t0, t1 = entries['spare/basic-tail.bin']
        got = basic_bytes(asm, equ, os.path.join(ROOT, 'build', 'variants', '_basic'), tmp)
        if got[:t0 - 0x5D3B] != body[:t0 - 0x5D3B]:
            open(os.path.join(vdir, 'basic.bin'), 'wb').write(body[:256])
            changed.append('basic.bin')
            if 'spare/basic-tail.bin' in changed:
                changed.remove('spare/basic-tail.bin')
                os.remove(os.path.join(vdir, 'spare', 'basic-tail.bin'))
        others = [g for g in files if g is not f] if len(files) <= 8 else []
        if others:
            os.makedirs(os.path.join(vdir, 'files'), exist_ok=True)
            cfg['files'] = []
            for i, g in enumerate(files):
                if g is f:
                    cfg['files'].append('boot')
                    continue
                fn = '%02d.%s.%s' % (i, g['name'].strip() or 'file', g['type'])
                open(os.path.join(vdir, 'files', fn), 'wb').write(g['body'][:g['sectors'] * 256])
                cfg['files'].append({'file': fn, 'name': g['name'], 'type': g['type'], 'start': g['start'],
                                     'length': g['length']})
                changed.append('files/' + fn)
        cfg['whole_image'] = len(files) <= 8
        write_variant(vdir, name, cfg, notes, changed)
        summary.append((name, ', '.join(changed) or 'nothing'))
    for name, what in summary:
        print('%-14s %s' % (name, what))


def write_variant(vdir, name, cfg, notes, changed):
    for top, dirs, files in os.walk(vdir, topdown=False):
        if not dirs and not files:
            os.rmdir(top)
    json.dump(cfg, open(os.path.join(vdir, 'variant.json'), 'w'), indent=2)
    open(os.path.join(vdir, 'variant.json'), 'a').write('\n')
    lines = ['# Variant %s' % name, '',
             'From `%s`, file `%s` (B, start %d, length %d, %d sectors). Written by `tools/variants.py extract`; '
             'built by `tools/build.sh --variant %s`.' % (cfg['image'], cfg['file'].rstrip(), cfg['header']['start'],
                                                          cfg['header']['length'], cfg['header']['sectors'], name), '']
    if 'equ' in cfg and 'no-music-init' in cfg.get('code', []):
        e = cfg['equ']
        lines.append('- The music piece at `%s`, %s sectors; the menu calls `%s` every frame and never an init.' % (
            e['MusicPiece'], e['MusicSectors'], e['MusicPlay']))
    elif 'equ' in cfg:
        e = cfg['equ']
        lines.append('- The music piece at `%s`, %s sectors; the menu calls `%s` at the start%s and `%s` every frame.' % (
            e['MusicPiece'], e['MusicSectors'], e['MusicInit'],
            ', then `%s` (one more CALL: every later code address moves by 3)' % e['MusicStart'] if 'MusicStart' in e
            else '', e['MusicPlay']))
    for k in WHERE:
        if k in cfg.get('equ', {}):
            lines.append('- %s at `%s` (%s `%s` in the original).' % (WHERE[k][0].upper() + WHERE[k][1:],
                                                                     cfg['equ'][k], k, ORIG_EQU[k]))
    for sw in cfg.get('code', []):
        lines.append('- Code: %s (`%s` in variant.json, tools/variants.py CODE_SWITCHES).' % (switch_what(sw), sw))
    for c in changed:
        lines.append('- `%s` differs from the original.' % c if not c.startswith('files/') else
                     '- `%s`: another file of the disk, kept as its bytes.' % c)
    if not changed and 'equ' in cfg:
        lines.append('- No resource differs.')
    lines += ['- ' + n for n in notes]
    open(os.path.join(vdir, 'README.md'), 'w').write('\n'.join(lines) + '\n')


def overlay(src, vdir, out):
    shutil.copytree(src, out)
    for top, _d, names in os.walk(vdir):
        for n in names:
            rel = os.path.relpath(os.path.join(top, n), vdir)
            if '/' not in rel or rel.startswith(('files/', 'music/piece')):
                continue
            stem = os.path.splitext(os.path.join(out, rel))[0]
            for old in glob.glob(stem + '.*'):
                os.remove(old)
            os.makedirs(os.path.dirname(os.path.join(out, rel)), exist_ok=True)
            shutil.copy(os.path.join(top, n), os.path.join(out, rel))


def build(name, asm):
    """build variants/NAME; returns (identical, message)"""
    vdir = os.path.join(VAR, name)
    cfg = json.load(open(os.path.join(vdir, 'variant.json')))
    if cfg.get('loader') == 'own' and not cfg.get('pieces'):
        return False, 'its own loader: not built from the source yet'
    work = os.path.join(ROOT, 'build', 'variants', name)
    shutil.rmtree(work, ignore_errors=True)
    os.makedirs(work)
    overlay(os.path.join(ROOT, 'src', 'res'), vdir, os.path.join(work, 'res-src'))
    res_formats.build(os.path.join(work, 'res'), os.path.join(work, 'res-src'))
    for part in ('main', 'basic', 'music'):
        for f in glob.glob(os.path.join(ROOT, 'src', part, '*.asm')):
            shutil.copy(f, work)
    equ = cfg['equ']
    set_equ(os.path.join(work, 'main.asm'), {k: equ[k] for k in MAIN_EQU if k in equ})
    set_equ(os.path.join(work, 'basic.asm'), {k: equ[k] for k in ('MusicPiece', 'MusicSectors')})
    if cfg.get('start'):
        add_start(work)
    apply_code(work, cfg.get('code', []))
    if cfg.get('pieces'):
        open(os.path.join(work, 'main.asm'), 'a').write('  SAVEBIN "image.bin",$4000,$C000  ; variants: the whole memory\n')
    run_asm(asm, os.path.join(work, 'main.asm'), work)
    menu = open(os.path.join(work, 'main.bin'), 'rb').read()
    if os.path.exists(os.path.join(vdir, 'basic.txt')):
        import res_basic
        basic = res_basic.from_text(open(os.path.join(vdir, 'basic.txt')).read())
    elif os.path.exists(os.path.join(vdir, 'basic.bin')):
        basic = open(os.path.join(vdir, 'basic.bin'), 'rb').read()
    else:
        run_asm(asm, os.path.join(work, 'basic.asm'), work)
        basic = open(os.path.join(work, 'basic.bin'), 'rb').read()
    music = music_piece(vdir, cfg, work, asm)
    if cfg.get('trd'):   # a whole TRD its loader reads by track and sector, encrypted (zyxlgbt, tools/lotus.py)
        import lotus
        return lotus.compare(cfg, lotus.build(vdir, cfg, pieces_body(vdir, cfg, work, asm, music, image=True), basic),
                             work)
    if cfg.get('pieces'):
        body = basic + pieces_body(vdir, cfg, work, asm, music)
    else:
        body = basic + menu[:CODE_END - CODE] + menu[GFX - CODE:GFX_END - CODE] + music
    h = cfg['header']
    want_files, _ = disk.read(os.path.join(ROOT, cfg['image']))
    want = next(g for g in want_files if g['name'] == cfg['file'])
    specs = []
    open(os.path.join(work, 'boot.body'), 'wb').write(body)
    for item in cfg.get('files', ['boot']):
        if item == 'boot':
            specs.append('%s:%s:%d:%d:%s' % (cfg['file'], h['type'], h['start'], h['length'], 'boot.body'))
        else:
            shutil.copy(os.path.join(vdir, 'files', item['file']), os.path.join(work, item['file']))
            specs.append('%s:%s:%d:%d:%s' % (item['name'], item['type'], item['start'], item['length'], item['file']))
    r = subprocess.run([sys.executable, os.path.join(ROOT, 'tools', 'disk.py'), 'scl', 'variant.scl'] + specs,
                       cwd=work, capture_output=True, text=True)
    if r.returncode:
        return False, 'disk.py: ' + r.stdout + r.stderr
    if body != want['body'][:want['sectors'] * 256]:
        first = next(i for i in range(min(len(body), len(want['body']))) if body[i] != want['body'][i]) \
            if body[:len(want['body'])] != want['body'][:len(body)] else min(len(body), len(want['body']))
        return False, 'differs: body offset %d (%s)%s' % (first, where(first, cfg), ', length %d vs %d' % (
            len(body), want['sectors'] * 256) if len(body) != want['sectors'] * 256 else '')
    if cfg.get('whole_image') and cfg['image'].lower().endswith('.scl'):
        if open(os.path.join(work, 'variant.scl'), 'rb').read() != open(os.path.join(ROOT, cfg['image']), 'rb').read():
            return False, 'the boot file is identical, the image is not'
        return True, 'identical to %s' % os.path.basename(cfg['image'])
    return True, 'identical to the file %s on %s' % (cfg['file'].rstrip(), os.path.basename(cfg['image']))


def symbols(path):
    """{label: address} from an sjasmplus --sym file"""
    out = {}
    if os.path.exists(path):
        for line in open(path):
            m = re.match(r'([\w.]+): EQU 0x([0-9A-Fa-f]+)', line)
            if m:
                out[m.group(1)] = int(m.group(2), 16) & 0xFFFF
    return out


def address(text, syms):
    """$XXXX, or Label, or Label+N (the variant's own assembly's labels)"""
    m = re.match(r'\$([0-9A-Fa-f]{4})$', text)
    if m:
        return int(m.group(1), 16)
    m = re.match(r'([\w.]+)(?:\+(\d+))?$', text)
    if not m or m.group(1) not in syms:
        raise SystemExit('variants: no label %s' % text)
    return syms[m.group(1)] + int(m.group(2) or 0)


def pieces_body(vdir, cfg, work, asm, music, image=False):
    """the boot file after its BASIC sectors for a variant with its own loader: the memory the menu's source
    assembles to (with the variant's resources, constants and switches), its music piece at MusicPiece, its parts
    (variant .ann pieces, assembled), the residues of self-modified operands and work bytes the saved file kept; then
    the sectors the loader reads, in its order ("pieces"), and the sectors it never reads ("tail", bytes)"""
    img = bytearray(65536)
    img[0x4000:] = open(os.path.join(work, 'image.bin'), 'rb').read()
    syms = symbols(os.path.join(work, 'main.sym'))
    syms.update(symbols(os.path.join(work, 'music.sym')))   # the original's music piece, when the variant keeps it
    base = int(cfg['equ'].get('MusicPiece', '$C000')[1:], 16)
    img[base:base + len(music)] = music[:65536 - base]
    for extra in cfg.get('music_extra', []):
        a = int(extra['at'][1:], 16)
        if extra.get('music'):   # a second piece in the readable form: music/SUB (tools/variants_music.py)
            import variants_music
            d = variants_music.build_piece(vdir, cfg, work, asm, extra['music'], a)
        else:
            d = open(os.path.join(vdir, extra['file']), 'rb').read()
        img[a:a + len(d)] = d[:65536 - a]
    for part in cfg.get('parts', []):
        pj = json.load(open(os.path.join(vdir, part)))
        src = os.path.join(vdir, os.path.dirname(part))
        pw = os.path.join(work, 'part-' + pj['top'])
        shutil.copytree(src, pw)
        if pj.get('res') and not os.path.exists(os.path.join(pw, 'res')):
            # a part whose resources are the variant's editable files: the built ones (work/res) as its res/
            shutil.copytree(os.path.join(work, 'res'), os.path.join(pw, 'res'))
        run_asm(asm, os.path.join(pw, pj['top'] + '.asm'), pw)
        d = open(os.path.join(pw, pj['bin']), 'rb').read()
        a = int(pj.get('org') or pj['at'], 16)
        img[a:a + len(d)] = d[:65536 - a]
        syms.update(symbols(os.path.join(pw, pj['top'] + '.sym')))
    for r in cfg.get('residue', []):
        a = address(r['at'], syms)
        d = bytes.fromhex(r['bytes'])
        img[a:a + len(d)] = d
    for st in cfg.get('state', []):   # work areas the saved memory held (buffers the menu fills as it runs)
        a = address(st['at'], syms)
        d = open(os.path.join(vdir, st['file']), 'rb').read()
        img[a:a + len(d)] = d[:65536 - a]
    if cfg.get('packed'):
        packed_piece(vdir, cfg, work, asm, img, syms)
    if image:   # the whole memory (a TRD variant cuts its sectors itself, tools/lotus.py)
        return img
    out = bytearray()
    for p in cfg['pieces']:
        a = int(p['at'][1:], 16)
        out += img[a:a + 256 * p['sectors']]
        if a + 256 * p['sectors'] > 65536:   # the read runs past $FFFF onto the ROM: those bytes are only on the disk
            out += open(os.path.join(vdir, cfg['past_ffff']), 'rb').read()
    if cfg.get('tail'):
        out += open(os.path.join(vdir, cfg['tail']), 'rb').read()
    return bytes(out)


def packed_piece(vdir, cfg, work, asm, img, syms):
    """variant.json "packed": the memory from..to packed by tools/lzpack.py behind the depacker head (a part, at the
    head's address), the hook's RET after the stream, then the piece's other bytes ("fill", else zeros)"""
    import lzpack
    pk = cfg['packed']
    lo, hi = address(pk['from'], syms), address(pk['to'], syms)
    raw = pk.get('raw_tail', 0)   # the last bytes stay raw after the end mark: the stream's move up puts them in place
    stream = lzpack.pack(img[lo:hi + 1 - raw]) + bytes(img[hi + 1 - raw:hi + 1])
    pj = json.load(open(os.path.join(vdir, pk['head'])))
    pw = os.path.join(work, 'part-' + pj['top'])
    shutil.copytree(os.path.join(vdir, os.path.dirname(pk['head'])), pw)
    run_asm(asm, os.path.join(pw, pj['top'] + '.asm'), pw)
    head = open(os.path.join(pw, pj['bin']), 'rb').read()
    a = int(pj['org'], 16)
    hook = a + len(head) + len(stream)
    if word(head, 1) != hook or word(head, 27) != len(stream):
        raise SystemExit('variants: %s: the head calls $%04X and moves %d bytes; the stream needs $%04X and %d' % (
            pk['head'], word(head, 1), word(head, 27), hook, len(stream)))
    blob = head + stream + b'\xc9'
    piece = next(p for p in cfg['pieces'] if int(p['at'][1:], 16) == a)
    end = a + 256 * piece['sectors']
    if pk.get('rest') == 'unpacked':   # the packer wrote into memory that held the unpacked data: its bytes stay after
        img[a:a + len(blob)] = blob
    else:                              # zeros after the hook's RET
        img[a:end] = blob + bytes(end - a - len(blob))


def candidate_memory(name, unpacked=False):
    """the memory a variant's own loader fills from its candidate file (variant.json pieces), and the file's body;
    unpacked: with a "packed" piece's data unpacked to its place"""
    cfg = json.load(open(os.path.join(VAR, name, 'variant.json')))
    f = next(g for g in disk.read(os.path.join(ROOT, cfg['image']))[0] if g['name'] == cfg['file'])
    body = f['body'][:f['sectors'] * 256]
    mem, off = bytearray(65536), cfg['basic_sectors'] * 256
    for p in cfg['pieces']:
        a, n = int(p['at'][1:], 16), 256 * p['sectors']
        d = body[off:off + n][:65536 - a]
        mem[a:a + len(d)] = d
        off += n
    if unpacked and cfg.get('packed'):   # the memory after the depacker ran (tools/lzpack.py)
        import lzpack
        pk = cfg['packed']
        head = json.load(open(os.path.join(VAR, name, pk['head'])))
        lo, hi = int(pk['from'][1:], 16), int(pk['to'][1:], 16)
        out, end = lzpack.unpack(mem, int(head['org'], 16) + 130)
        raw = pk.get('raw_tail', 0)
        tail = bytes(mem[end:end + raw])
        mem[lo:lo + len(out)] = out
        mem[hi + 1 - raw:hi + 1] = tail
    return mem, body


def music_piece(vdir, cfg, work, asm):
    """the bytes of a variant's music piece: music/piece.bin as it is, the readable form (tools/variants_music.py:
    a player's .ann piece and its tune as text) when the folder has one, else the original's src/music"""
    mdir = os.path.join(vdir, 'music')
    if os.path.exists(os.path.join(mdir, 'piece.bin')):
        return open(os.path.join(mdir, 'piece.bin'), 'rb').read()
    if os.path.isdir(mdir) and os.listdir(mdir):
        import variants_music
        return variants_music.build_piece(vdir, cfg, work, asm)
    run_asm(asm, os.path.join(work, 'music.asm'), work)
    return open(os.path.join(work, 'music.bin'), 'rb').read()


def where(off, cfg):
    if cfg.get('pieces'):   # an own loader: the BASIC sectors, then the pieces in file order
        base = cfg.get('basic_sectors', 1) * 256
        if off < base:
            return 'BASIC $%04X' % (0x5D3B + off)
        for p in cfg['pieces']:
            n = p['sectors'] * 256
            if off < base + n:
                return 'piece %s +$%04X ($%04X)' % (p['at'], off - base, int(p['at'][1:], 16) + off - base)
            base += n
        return 'past the pieces +$%04X' % (off - base)
    if off < 256:
        return 'BASIC $%04X' % (0x5D3B + off)
    if off < 4096:
        return 'code $%04X' % (CODE + off - 256)
    if off < 6144:
        return 'graphics $%04X' % (GFX + off - 4096)
    return 'music +$%04X' % (off - 6144)


# The code switches a variant.json "code" list may name: (file, the generated lines, their replacement, what it does)
CODE_SWITCHES = {
    'kempston': ('keys.asm', r'^Joystick:\n  LD A,\$00[^\n]*\n(?:  +;[^\n]*\n)*',
                 'Joystick:\n  IN A,($1F)              ; variant: the Kempston joystick is read\n',
                 'reads the Kempston joystick: `IN A,($1F)` at Joystick `$68B9` in place of `LD A,$00`'),
    'no-joystick': ('keys.asm', r'^Joystick:\n  LD A,\$00[^\n]*\n(?:  +;[^\n]*\n)*(?:  RRA\n  CALL C,\w+\n){5}',
                    'Joystick:\n  DEFS 22                 ; variant: the dormant joystick block is zeros (NOPs)\n',
                    'has no joystick block: the 22 bytes at Joystick `$68B9` are zeros (NOPs)'),
    'glint-add': ('logo.asm', r'^GlintHalf:\n  AND \$01[^\n]*\n(?:  +;[^\n]*\n)*',
                  'GlintHalf:\n  ADD A,$01               ; variant: the reflection only in frames $FF00-$FF3F\n',
                  'tests the glint\'s half with `ADD A,$01` at GlintHalf `$6D1F` (the original `AND $01`)'),
    'no-music-init': ('setup.asm', r'^  CALL MusicInit\n  CALL MusicStart\n',
                      '  DEFS 6                  ; variant: the two calls into the music piece are zeros (NOPs)\n',
                      'never calls the music\'s init: the 6 bytes of the two CALLs at `$61E7` are zeros (family B layout)'),
    'glint-daa': ('logo.asm', r'^  LD BC,\$0020\n  AND A\n  SBC HL,BC\n', '  LD BC,$0020\n  DAA\n  SBC HL,BC\n',
                  'has `DAA` for the `AND A` at `$6D63` in LogoGlint (one bit off: `$27` for `$A7`), likely a damaged '
                  'byte; the carry it leaves is then not always clear'),
    'music-after-screen': ('setup.asm', r'^  CALL MusicInit\n  CALL DrawScreen\n',
                           '  CALL DrawScreen\n  CALL MusicInit\n',
                           'starts the music after DrawScreen (the two calls at `$61E7` swapped)'),
    'catalogue-call': ('setup.asm', r'^Start:\n((?:.*\n){6})  LD DE,\$0000\n  LD HL,Catalogue\n  LD BC,\$0805\n  CALL TrdosEntry\n',
                       '  ORG $619B\n'
                       'ReadCatalogue:          ; variant: the catalogue read moved into a routine just before Start\n'
                       '  LD DE,$0000\n  LD HL,Catalogue\n  LD BC,$0805\n  CALL TrdosEntry\n  RET\n'
                       'Start:\n\\1'
                       '  LD A,($FF14)            ; variant: the launcher\'s flag (zyxboot-01 parts/launcher.ann)\n'
                       '  OR A\n  JR NZ,CatalogueRead\n  CALL ReadCatalogue\n  NOP\n  NOP\n  NOP\n'
                       'CatalogueRead:\n',
                       'reads the catalogue through ReadCatalogue, a 13-byte routine just before Start at `$619B`, '
                       'and only while the byte at `$FF14` (the launcher\'s flag) is 0'),
    'corners-plain': ('fade.asm', r'^ColourCorners:\n  LD HL,Attributes\n  CALL ColourCornerRows\n  LD HL,Attributes\+635\n'
                      r'  CALL ColourCornerRows\n  LD DE,Attributes\+27\n  CALL ColourCornerColumns\n  LD DE,Attributes\+608\n'
                      r'  CALL ColourCornerColumns\n  RET\n((?:\n|;[^\n]*\n)*)ColourCornerRows:\n  LD B,\$05\n  LD DE,CornerColours\n'
                      r'CornerRowsNext:\n  LD C,\$05\n  LD A,\(DE\)\n',
                      'ColourCorners:\n  LD HL,Attributes\n  CALL ColourCornerRows\n  LD HL,Attributes+635\n  CALL ColourCornerRows\n'
                      '  LD HL,Attributes+27     ; variant: all four corners through ColourCornerRows\n  CALL ColourCornerRows\n'
                      '  LD HL,Attributes+608\n  CALL ColourCornerRows\n  RET\n\\1ColourCornerRows:\n  LD B,$05\n'
                      '  LD A,$04                ; variant: one colour, green ink, for every cell\n  NOP\n'
                      'CornerRowsNext:\n  LD C,$05\n  NOP\n',
                      'colours the four corners plain green (`LD A,$04` in ColourCornerRows, which draws all four): '
                      'no gradient, CornerColours is not read'),
    'catalogue-safe': ([
        ('setup.asm', r'^  LD DE,\$0000\n  LD HL,Catalogue\n  LD BC,\$0805\n  CALL TrdosEntry\n',
         '  CALL MusicInit           ; variant: the music first, then the catalogue through ReadCatalogueSafe\n'
         '  DI\n  CALL $6FE0              ; ReadCatalogueSafe (variants/zyxtvmbt/parts/safe.ann)\n  DEFS 5\n'),
        ('setup.asm', r'^  CALL MusicInit\n  CALL DrawScreen\n', '  DEFS 3                  ; variant: no second init\n  CALL DrawScreen\n'),
        ('interrupt.asm', r'^  LD IY,\(SavedIY\)\n  CALL MusicPlay\n',
         '  CALL MusicPlay           ; variant: the music before IY is set\n  LD IY,(SavedIY)\n'),
        ('keys.asm', r'^  LD HL,Catalogue\n  LD DE,\$0000\n  LD BC,\$0805\n  DI\n  IM 1\n  CALL TrdosEntry\n  DI\n  IM 2\n'
                     r'  CALL ShowCatalogue\n  RET\n',
         '  DI                      ; variant: SPACE reads the catalogue through ReadCatalogueSafe\n  IM 1\n'
         '  CALL $6FE0\n  DI\n  IM 2\n  CALL ShowCatalogue\n  RET\n'
         '  DEFB $2D,$2D,$52,$45,$52,$45,$41,$44,$20  ; "--REREAD ": leftover text, not read\n')],
        'reads the catalogue through its own ReadCatalogueSafe at `$6FE0` (an error trap on ERR_SP, then the drive '
        'stopped through the TR-DOS ROM), from Start and from SPACE; inits the music before that read instead of '
        'before DrawScreen; calls the music before it loads IY in the interrupt'),
    'sky-rotate-buffer': ([
        ('rhombi.asm', r'^  LD DE,RotateBuffer\n',
         '  LD DE,$60E0             ; variant: RotateBuffer below the code ($9C00 holds the Cyrillic font)\n'),
        ('rhombi.asm', r'^  INC E\n  DJNZ RotateShiftRow\n', '  INC DE                  ; variant: the buffer crosses a page\n  DJNZ RotateShiftRow\n'),
        ('rhombi.asm', r'^  DJNZ RotateSourceRow\n  INC E\n  INC E\n  INC E\n  INC E\n  INC E\n',
         '  DJNZ RotateSourceRow\n  INC DE\n  INC DE\n  INC DE\n  INC DE\n  INC DE\n'),
        ('rhombi.asm', r'^  LD HL,RotateBuffer\n', '  LD HL,$60E0\n')],
        'turns the rhombi through a buffer at `$60E0` (`INC DE` for `INC E`: it crosses a page) instead of RotateBuffer '
        '`$9C00`, which the scroller\'s Cyrillic font takes'),
    'sky-stars': ([
        ('font.asm', r'^PrintString:\n(?:.*\n)*?  JR PrintStringNext\n',
         'StarStep:                ; variant: PrintString moved to $6DC6 (logo.asm); a star one pixel row down\n'
         '  CALL $A7FF              ; SkyRowDown (variants/zyxskybt/parts/sky.ann)\n'
         '  LD A,H\n  AND $18\n  CP $18\n  JR NZ,StarStepStore\n  LD H,$40\n'
         'StarStepStore:\n  LD (IX+$00),L\n  LD (IX+$01),H\n  LD B,$01\n  RET\n'
         '  DEFB $18,$F8            ; leftover: the original JR PrintStringNext\n'),
        ('logo.asm', r'^DrawReflection:\n(?:.*\n)*?  LD DE,Logo\n',
         'DrawReflection:          ; variant: never called; its first 28 bytes hold PrintString\n'
         'PrintString:\n  PUSH HL\n  LD HL,(SavedHLAlt)\n  EXX\n  LD IY,(SavedIY)\n  LD A,$02\n  CALL RomChanOpen\n'
         '  POP HL\nPrintStringNext:\n  LD A,(HL)\n  CP $FF\n  RET Z\n  RST $10\n  INC HL\n  JR PrintStringNext\n'
         '  DEFS 5\n'),
        ('setup.asm', r'^  CALL DrawReflection\n', '  DEFS 3                  ; variant: no reflection (the scroller runs there)\n'),
        ('stars.asm', r'^  LD L,\(IX\+\$00\)\n  LD H,\(IX\+\$01\)\n  LD D,',
         '  JP $A86D                ; variant: SkyStarClip (parts/sky.ann) loads HL and skips the picture\n'
         '  LD H,(IX+$01)\n  LD D,'),
        ('stars.asm', r'^  INC H\n  LD A,H\n  AND \$07\n  JR NZ,MoveStarsMoved\n(?:.*\n)*?  ADD A,\$08\n',
         '  CALL StarStep            ; variant: the star a row down\n  CALL SampleStar\n  JP MoveStarsMoved+11\n'
         'MoveStarsHidden:         ; SkyStarClip comes here for a star over the picture or the scroller: no draw\n'
         '  CALL StarStep\n  CALL SampleStar\n  JP MoveStarsDraw+2\n  DEFS 3\n'),
        ('stars.asm', r'^  CALL CheckTwinkleSpot\n',
         '  CALL $A89E              ; variant: SkyTwinkleSpot (parts/sky.ann): also off the picture\n'),
        ('stars.asm', r'^EraseTwinkle:\n  INC HL\n',
         'EraseTwinkle:\n  NOP                     ; variant: SkyTwinkleSpot has stepped HL already\n')],
        'moves the stars and twinkles around the new picture and scroller: MoveStars goes through SkyStarClip '
        '(`$A86D`) and StarStep (at `$6720`, where PrintString was: PrintString moves over the start of the unused '
        'DrawReflection, `$6DC6`), the twinkle spots through SkyTwinkleSpot (`$A89E`); no reflection'),
    'sky-screen': ([
        ('screen.asm', r'^  LD HL,FontBase\n  LD \(Chars\),HL\n  LD HL,MenuHelp\n  CALL PrintString\n',
         '  LD HL,$A884             ; variant: the font as SkySetup moves it ($A984)\n  LD (Chars),HL\n'
         '  LD HL,MenuHelp\n  CALL $78DD              ; SkySetup (parts/sky.ann): the picture, the font, the scroller\n'),
        ('screen.asm', r'^ShowCatalogue:\n  CALL SoundOff\n',
         'ShowCatalogue:\n  DEFS 3                  ; variant: no SoundOff\n'),
        ('keys.asm', r'^  IM 2\n  CALL ShowCatalogue\n', '  IM 2\n  CALL ShowCatalogue+3\n'),
        ('interrupt.asm', r'^  CALL MusicPlay\n',
         '  CALL $A85C              ; variant: SkyFrame (parts/sky.ann): the scroller, the bars, then MusicPlay\n'),
        ('setup.asm', r'(every 8th pass: the bottom rhombi\n)  AND \$07\n  CP \$07\n',
         '\\1  AND $05                 ; variant: passes with bits 0 and 2 set\n  CP $05\n')],
        'hooks the Skynet screen in: DrawScreen calls SkySetup (`$78DD`) where it printed the help text, the '
        'interrupt calls SkyFrame (`$A85C`) for the music, the font is at `$A984`, ShowCatalogue has no SoundOff, '
        'the bottom rhombi turn on passes with bits 0 and 2 set'),
}


def switch_edits(sw):
    """[(file, regex, replacement)] of a code switch (one edit, or a list of edits in several modules)"""
    v = CODE_SWITCHES[sw]
    return v[0] if isinstance(v[0], list) else [v[:3]]


def switch_what(sw):
    return CODE_SWITCHES[sw][-1]


def apply_code(work, switches):
    for sw in switches:
        for fn, old, new in switch_edits(sw):
            p = os.path.join(work, fn)
            s, n = re.subn(old, new, open(p).read(), count=1, flags=re.M)
            if n != 1:
                raise SystemExit('variants: code switch %s does not match %s' % (sw, fn))
            open(p, 'w').write(s)


def code_switches(v, start):
    out = []
    j = shifted(0x68B9, start)
    if v[j:j + 2] == b'\xdb\x1f':
        out.append('kempston')
    elif v[j:j + 22] == bytes(22):
        out.append('no-joystick')
    if v[shifted(0x6D1F, start)] == 0xC6:
        out.append('glint-add')
    if v[shifted(0x6D63, start)] == 0x27:
        out.append('glint-daa')
    if v[0x61E7:0x61EA] == b'\xcd\x10\x65' and v[0x61EA] == 0xCD:
        out.append('music-after-screen')
    return out


def add_start(work):
    """family B: CALL MusicStart after CALL MusicInit; the code piece's later ORG lines move by 3"""
    p = os.path.join(work, 'setup.asm')
    s = open(p).read()
    s = s.replace('  CALL MusicInit\n', '  CALL MusicInit\n  CALL MusicStart\n', 1)
    open(p, 'w').write(s)
    for p in glob.glob(os.path.join(work, '*.asm')):
        s = open(p).read()

        def move(m):
            a = int(m.group(1), 16)
            return '  ORG $%04X' % (a + SHIFT) if START_AT < a < CODE_END else m.group(0)
        open(p, 'w').write(re.sub(r'^  ORG \$([0-9A-F]{4})', move, s, flags=re.M))


def write_own_readme(name, same, msg):
    """README.md of a variant with its own loader (variant.json pieces) or a whole-image one: written from
    variant.json (pieces, parts, residue, notes) by tools/variants.py index"""
    vdir = os.path.join(VAR, name)
    cfg = json.load(open(os.path.join(vdir, 'variant.json')))
    h = cfg['header']
    lines = ['# Variant %s' % name, '',
             'From `%s`, file `%s` (B, start %d, length %d, %d sectors). Built by `tools/build.sh --variant %s`: '
             '**%s**.' % (cfg['image'], cfg['file'].rstrip(), h['start'], h['length'], h['sectors'], name,
                          'identical' if same else msg), '']
    if cfg.get('pieces'):
        lines.append('- Its loader (%s) reads %d sector%s of BASIC, then: %s.' % (
            '`basic.txt`, the BASIC as text, `tools/res_basic.py`' if os.path.exists(os.path.join(vdir, 'basic.txt'))
            else 'the original\'s BASIC with the variant\'s music address and count',
            cfg.get('basic_sectors', 1), '' if cfg.get('basic_sectors', 1) == 1 else 's',
            ', '.join('`%s` x %d' % (p['at'], p['sectors']) for p in cfg['pieces'])))
    e = cfg.get('equ', {})
    if 'MusicPiece' in e:
        lines.append('- The music piece at `%s`, %s sectors%s; play `%s`%s.' % (
            e['MusicPiece'], e['MusicSectors'], ', init `%s`' % e['MusicInit'] if 'MusicInit' in e else '',
            e.get('MusicPlay', '?'), ', start `%s` (layout B)' % e['MusicStart'] if 'MusicStart' in e else ''))
    for sw in cfg.get('code', []):
        lines.append('- Code: %s (`%s`, tools/variants.py CODE_SWITCHES).' % (switch_what(sw), sw))
    for part in cfg.get('parts', []):
        pj = json.load(open(os.path.join(vdir, part)))
        ann = pj.get('ann') or pj['segments'][0]['ann']   # the segments layout: one .ann in pieces
        lines.append('- Code of its own, described in `%s` (built by kit/mkgame.py from `%s`, placed at `$%s`).' % (
            os.path.relpath(os.path.join(ROOT, ann), vdir), part, pj.get('org') or pj['at']))
    if cfg.get('residue'):
        lines.append('- Residue (bytes the saved file kept from a run, put back after the build):')
        lines += ['  - `%s`: `%s`%s' % (r['at'], r['bytes'], ' (%s)' % r['why'] if r.get('why') else '')
                  for r in cfg['residue']]
    for k in ('tail', 'past_ffff'):
        if cfg.get(k):
            lines.append('- `%s`: %s, kept as its bytes.' % (cfg[k], 'the file\'s sectors after the last piece' if k == 'tail'
                                                         else 'the last piece\'s bytes past `$FFFF`'))
    files = sorted(os.path.relpath(os.path.join(t, f), vdir) for t, _d, fs in os.walk(vdir) for f in fs
                   if f not in ('README.md', 'variant.json') and '/parts/' not in os.path.join(t, f) + '/'
                   and not os.path.join(t, f).startswith(os.path.join(vdir, 'parts')))
    if files:
        lines.append('- Files that differ from the original: %s.' % ', '.join('`%s`' % f for f in files))
    lines += ['- ' + n for n in cfg.get('notes', [])]
    open(os.path.join(vdir, 'README.md'), 'w').write('\n'.join(lines) + '\n')


def index(asm):
    rows, ok, total = [], 0, 0
    for n in sorted(os.listdir(VAR)):
        if not os.path.isfile(os.path.join(VAR, n, 'variant.json')):
            continue
        cfg = json.load(open(os.path.join(VAR, n, 'variant.json')))
        same, msg = build(n, asm)
        ok += same
        total += 1
        if cfg.get('pieces') or cfg.get('loader') == 'own':
            write_own_readme(n, same, msg)
        files = []
        for top, _d, names in os.walk(os.path.join(VAR, n)):
            for f in names:
                rel = os.path.relpath(os.path.join(top, f), os.path.join(VAR, n))
                if rel not in ('README.md', 'variant.json') and not rel.startswith('files/'):
                    files.append(rel)
        if cfg.get('loader') == 'own':
            layout, code = 'own loader' + (', B' if cfg.get('start') else ''), ', '.join(cfg.get('code', []))
        else:
            layout = 'B' if cfg.get('start') else 'A'
            code = ', '.join(cfg.get('code', []))
            extra = [k for k in cfg['equ'] if k in WHERE]
            code = ', '.join(x for x in (code, ' '.join(extra)) if x)
        rows.append('| [%s](%s/README.md) | %s | %s | %s | %s |' % (
            n, n, layout, ', '.join('`%s`' % f for f in sorted(files)) or 'none', code or '', 'identical' if same else msg))
    out = ['# The variants', '',
           'One folder a variant of the owner\'s 39 images (`work/candidates/owner-boots_zyx`; the 18 boots on '
           '`zyxboot.scl` are `zyxboot-01` ... `zyxboot-18`). Each holds only what differs from the original: the '
           'resource files (same names and formats as `src/res`), its music piece, its BASIC sector when that is not '
           'the original\'s, the disk\'s other files, and `variant.json` (the music piece\'s address and entries, the '
           'moved work areas, the code switches). `tools/variants.py extract` writes them from the candidates, '
           '`tools/build.sh --variant NAME` builds one, `tools/build.sh --all` all of them.', '',
           'Layout A is the original\'s code; layout B has one more CALL into the music piece after CALL MusicInit '
           '(3 bytes: every later address of the code piece moves by 3, which the labels follow); most B variants also keep the screen '
           'copy at `$C000` and its stack at `$BF68`. The code switches are in `tools/variants.py` (`CODE_SWITCHES`); '
           'no variant has a copy of the code.', '',
           '**%d of %d build identical.**' % (ok, total), '',
           '| Variant | Layout | Files that differ | Code switches and moved areas | Build |',
           '| --- | --- | --- | --- | --- |'] + rows
    open(os.path.join(VAR, 'README.md'), 'w').write('\n'.join(out) + '\n')
    print('variants: %d of %d identical; variants/README.md written' % (ok, total))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['extract', 'build', 'index', 'image'])
    p.add_argument('names', nargs='*')
    p.add_argument('--all', action='store_true')
    p.add_argument('--sjasmplus', default='')
    a = p.parse_args()
    asm = subprocess.run([sys.executable, os.path.join(ROOT, '..', '..', 'kit', 'toolpaths.py'), 'sjasmplus',
                          a.sjasmplus], capture_output=True, text=True).stdout.strip()
    if not asm and a.command != 'image':
        raise SystemExit('variants: no sjasmplus')
    if a.command == 'extract':
        extract(a.names, asm)
        return 0
    if a.command == 'image':   # image NAME $ADDR LENGTH OUT: the candidate's bytes a variant .ann piece describes
        name, addr, length, out = a.names[:4]   # a fifth word "unpacked": after a packed piece's depacker ran
        mem, _ = candidate_memory(name, a.names[4:] == ['unpacked'])
        os.makedirs(os.path.dirname(os.path.join(ROOT, out)), exist_ok=True)
        start = int(addr.lstrip('$'), 16)
        open(os.path.join(ROOT, out), 'wb').write(bytes(mem[start:start + int(length)]))
        return 0
    if a.command == 'index':
        index(asm)
        return 0
    names = sorted(os.listdir(VAR)) if a.all or not a.names else a.names
    names = [n for n in names if os.path.isfile(os.path.join(VAR, n, 'variant.json'))]
    ok = 0
    for n in names:
        same, msg = build(n, asm)
        ok += same
        print('%-14s %s' % (n, msg))
    if len(names) > 1:
        print('variants: %d of %d identical' % (ok, len(names)))
    return 0 if ok == len(names) else 1


if __name__ == '__main__':
    sys.exit(main())
