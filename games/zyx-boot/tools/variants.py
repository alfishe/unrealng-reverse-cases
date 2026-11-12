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

The code is never copied: a variant's code is the case's src/game with
- the music entries as constants (@const MusicInit, MusicPlay in src/game/game.ann; MusicPiece, MusicSectors in
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
GAME_EQU = ('MusicInit', 'MusicPlay', 'MusicStart', 'MenuStack', 'Im2Table', 'Im2Jump', 'ScreenCopy', 'ScreenCopyHigh', 'GlintEdge', 'GlintCentre')
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


def res_entries(part='game', last_end=GFX_END):
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
                        path], cwd=work, capture_output=True, text=True)
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
        lines.append('- Code: %s (`%s` in variant.json, tools/variants.py CODE_SWITCHES).' % (CODE_SWITCHES[sw][3], sw))
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
    if cfg.get('loader') == 'own':
        return False, 'its own loader: not built from the source yet'
    work = os.path.join(ROOT, 'build', 'variants', name)
    shutil.rmtree(work, ignore_errors=True)
    os.makedirs(work)
    overlay(os.path.join(ROOT, 'src', 'res'), vdir, os.path.join(work, 'res-src'))
    res_formats.build(os.path.join(work, 'res'), os.path.join(work, 'res-src'))
    for part in ('game', 'basic', 'music'):
        for f in glob.glob(os.path.join(ROOT, 'src', part, '*.asm')):
            shutil.copy(f, work)
    equ = cfg['equ']
    set_equ(os.path.join(work, 'game.asm'), {k: equ[k] for k in GAME_EQU if k in equ})
    set_equ(os.path.join(work, 'basic.asm'), {k: equ[k] for k in ('MusicPiece', 'MusicSectors')})
    if cfg.get('start'):
        add_start(work)
    apply_code(work, cfg.get('code', []))
    run_asm(asm, os.path.join(work, 'game.asm'), work)
    game = open(os.path.join(work, 'game.bin'), 'rb').read()
    if os.path.exists(os.path.join(vdir, 'basic.bin')):
        basic = open(os.path.join(vdir, 'basic.bin'), 'rb').read()
    else:
        run_asm(asm, os.path.join(work, 'basic.asm'), work)
        basic = open(os.path.join(work, 'basic.bin'), 'rb').read()
    if os.path.exists(os.path.join(vdir, 'music', 'piece.bin')):
        music = open(os.path.join(vdir, 'music', 'piece.bin'), 'rb').read()
    else:
        run_asm(asm, os.path.join(work, 'music.asm'), work)
        music = open(os.path.join(work, 'music.bin'), 'rb').read()
    body = basic + game[:CODE_END - CODE] + game[GFX - CODE:GFX_END - CODE] + music
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


def where(off, cfg):
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
}


def apply_code(work, switches):
    for sw in switches:
        fn, old, new, _what = CODE_SWITCHES[sw]
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


def index(asm):
    rows, ok, total = [], 0, 0
    for n in sorted(os.listdir(VAR)):
        if not os.path.isfile(os.path.join(VAR, n, 'variant.json')):
            continue
        cfg = json.load(open(os.path.join(VAR, n, 'variant.json')))
        same, msg = build(n, asm)
        ok += same
        total += 1
        files = []
        for top, _d, names in os.walk(os.path.join(VAR, n)):
            for f in names:
                rel = os.path.relpath(os.path.join(top, f), os.path.join(VAR, n))
                if rel not in ('README.md', 'variant.json') and not rel.startswith('files/'):
                    files.append(rel)
        if cfg.get('loader') == 'own':
            layout, code = 'own loader', ''
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
    p.add_argument('command', choices=['extract', 'build', 'index'])
    p.add_argument('names', nargs='*')
    p.add_argument('--all', action='store_true')
    p.add_argument('--sjasmplus', default='')
    a = p.parse_args()
    asm = subprocess.run([sys.executable, os.path.join(ROOT, '..', '..', 'kit', 'toolpaths.py'), 'sjasmplus',
                          a.sjasmplus], capture_output=True, text=True).stdout.strip()
    if not asm:
        raise SystemExit('variants: no sjasmplus')
    if a.command == 'extract':
        extract(a.names, asm)
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
