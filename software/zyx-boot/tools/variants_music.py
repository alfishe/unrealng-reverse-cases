#!/usr/bin/env python3
"""A variant's music piece in a readable form: one shared player for each kind of player, the tune as text, the
variant's own leftover bytes. tools/variants.py builds the piece from it (build_piece) when variants/NAME/music/ has
no piece.bin.

    python3 tools/variants_music.py image KIND          # the player's image for kit/mkgame.py (work/parts/player-KIND.bin)
    python3 tools/variants_music.py convert NAME...     # piece.bin -> player.txt + the tune; the variant must build identical
    python3 tools/variants_music.py split NAME          # print what convert would write (no file changes)

The piece of a converted variant is, in order:
  - the player: variants/players/KIND (a kit/mkgame.py .ann piece, one source for every variant that has the player),
    assembled at the variant's MusicPiece address;
  - the tune: music/KIND-TUNE.txt through its converter (tools/res_stc.py, tools/res_music.py, tools/res_fuxoft.py;
    the game rips' tools/res_whittaker.py, tools/res_sheridan.py, tools/res_daglish.py);
  - the tail: the bytes after the tune up to the end of the piece's last sector (what the sectors held before).
music/player.txt names the player and holds the variant's state bytes: what the player's variables and
self-modified operands held when the disk was saved (`at LABEL+N bytes`; LABEL from the player's source), and the
tail. The format is in src/res/music/README.md.
"""
import glob
import importlib
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VAR = os.path.join(ROOT, 'variants')
PLAYERS = os.path.join(VAR, 'players')
sys.path.insert(0, os.path.join(ROOT, 'tools'))

# kind: the tune's offset in the piece (= the player's length), the tune's converter and file, the variant the
# player's image is taken from
KINDS = {
    'stc': {'module': 0x43C, 'conv': 'res_stc', 'tune': 'stc', 'ref': 'zyxalex2'},
    'asc2': {'module': 0x4A7, 'conv': 'res_music', 'tune': 'asc', 'ref': 'zyxboot-14'},
    'fuxoft': {'module': 0x4E5, 'conv': 'res_fuxoft', 'tune': 'fuxoft', 'ref': 'zyxae'},
    'asc1': {'module': 0x671, 'conv': 'res_music', 'tune': 'asc1', 'ref': 'zyxboot-01'},
    # Sound Tracker 1's compilation (zyxtvmbt, packed): its head, the 'stc' player at +$59, the stop routine's end
    'stc1': {'module': 0x4A8, 'conv': 'res_stc', 'tune': 'stc', 'ref': 'zyxtvmbt',
             'parts': [('stc1-head', 0x000), ('stc', 0x059), ('stc1-tail', 0x495)]},
    # game rips: the tune's words are absolute addresses and the code reads the tables at fixed addresses, so the
    # player stays at its own address ('fixed'); 'version' names the driver version for the converter
    'whittaker-platoon': {'module': 0x8ED, 'conv': 'res_whittaker', 'tune': 'whittaker', 'ref': 'zyxboot-05',
                          'fixed': True, 'version': 'platoon'},
    'whittaker-dizzy': {'module': 0x8DC, 'conv': 'res_whittaker', 'tune': 'whittaker', 'ref': 'zyxboot-10',
                        'fixed': True, 'version': 'dizzy'},
    'whittaker-storm': {'module': 0x4EE, 'conv': 'res_whittaker', 'tune': 'whittaker', 'ref': 'zyxboot-11',
                        'fixed': True, 'version': 'storm'},
    'sheridan': {'module': 0x7E0, 'conv': 'res_sheridan', 'tune': 'sheridan', 'ref': 'zyxboot-12', 'fixed': True},
    'daglish': {'module': 0x6D1, 'conv': 'res_daglish', 'tune': 'daglish', 'ref': 'zyxrover', 'fixed': True},
    # one-off rips, one tune format each in tools/res_rip.py ('version' = its format)
    'hydrofool': {'module': 0x4CD, 'conv': 'res_rip', 'tune': 'hydrofool', 'ref': 'zyxalex', 'fixed': True,
                  'version': 'hydrofool'},
    'megaapoc': {'module': 0x45B, 'conv': 'res_rip', 'tune': 'megaapoc', 'ref': 'zyxdimob', 'fixed': True,
                 'version': 'megaapoc'},
    'ziutek': {'module': 0x303, 'conv': 'res_rip', 'tune': 'ziutek', 'ref': 'zyxfp4bt', 'fixed': True,
               'version': 'ziutek'},
    'awbt': {'module': 0x4EE, 'conv': 'res_rip', 'tune': 'awbt', 'ref': 'zyxawbt', 'fixed': True, 'version': 'awbt'},
    'fp3bt': {'module': 0x518, 'conv': 'res_rip', 'tune': 'fp3bt', 'ref': 'zyxfp3bt', 'fixed': True,
              'version': 'fp3bt'},
}
# names of self-modified operands (inside an instruction, so the source has no label there): name -> (label, offset)
OPERANDS = {
    'stc': {'ModuleBase': ('AddModuleBase', 1),     # LD BC,nn: the module's address (Init writes it)
            'OrnamentRow': ('TonePeriod', 10),      # LD DE,nn (low byte): the channel's sample row
            'Transposition': ('TonePeriod', 18)},   # ADD A,n: the position's transposition
    'fuxoft': {'NoiseMask': ('CommandNoiseAdd', 5)},  # AND n: the noise period's mask
}


def h(s):
    return int(s.lstrip('$'), 16)


def base_of(cfg):
    return h(cfg['equ']['MusicPiece'])


def tune_length(kind, d):
    m = importlib.import_module(KINDS[kind]['conv'])
    if kind in ('stc', 'stc1'):
        return d[25] | d[26] << 8
    return m.length(d, 1) if kind == 'asc1' else m.length(d)


def default_asm():
    r = subprocess.run(['python3', os.path.join(ROOT, '..', '..', 'kit', 'toolpaths.py'), 'sjasmplus'],
                       capture_output=True, text=True)
    if r.returncode:
        raise SystemExit('variants_music: no sjasmplus: ' + r.stderr)
    return r.stdout.strip()


def symbols(path):
    out = {}
    for line in open(path):
        m = re.match(r'(\w+):\s+EQU\s+0x([0-9A-Fa-f]+)', line)
        if m:
            out[m.group(1)] = int(m.group(2), 16)
    return out


def player(kind, base, work, asm, module=None):
    """(the player's bytes assembled at base, its labels as offsets from base); a kind with 'parts' is several player
    sources one after the other (each at its offset), the module after the last"""
    if module is None and kind in KINDS:
        module = base + KINDS[kind]['module']
    if 'parts' in KINDS.get(kind, {}):
        data, labels = bytearray(), {}
        for sub, off in KINDS[kind]['parts']:
            if len(data) != off:
                raise SystemExit('variants_music: %s: %s at +$%X, the parts before end at +$%X' % (kind, sub, off,
                                                                                                    len(data)))
            d, lab = player(sub, base + off, work, asm, module)
            data += d
            labels.update({n: v + off for n, v in lab.items()})
        return bytes(data), labels
    src = os.path.join(PLAYERS, kind)
    pw = os.path.join(work, 'player-' + kind)
    shutil.rmtree(pw, ignore_errors=True)
    os.makedirs(pw)
    for f in glob.glob(os.path.join(src, '*.asm')):
        shutil.copy(f, pw)
    top = os.path.join(pw, kind + '.asm')
    s = open(top).read()
    org = h(re.search(r'^  ORG (\$[0-9A-F]+)', s, re.M).group(1))
    s = re.sub(r'^  ORG \$[0-9A-F]+', '  ORG $%04X' % base, s, flags=re.M)
    s = re.sub(r'SAVEBIN "([^"]+)",\$[0-9A-F]+', lambda m: 'SAVEBIN "%s",$%04X' % (m.group(1), base), s)
    s = re.sub(r'^(Module\s+EQU\s+)\$[0-9A-F]+', lambda m: m.group(1) + '$%04X' % module, s,
               flags=re.M)
    if org != base and (kind == 'fuxoft' or KINDS.get(kind, {}).get('fixed')):
        raise SystemExit('variants_music: the %s player reads its tune at fixed addresses ($%04X only)' % (kind, org))
    open(top, 'w').write(s)
    r = subprocess.run([asm, '--nologo', '--msg=war', '--sym=' + kind + '.sym', kind + '.asm'], cwd=pw,
                       capture_output=True, text=True)
    if r.returncode or r.stdout.strip() or r.stderr.strip():
        raise SystemExit('variants_music: %s: %s%s' % (kind, r.stdout, r.stderr))
    data = open(os.path.join(pw, kind + '.bin'), 'rb').read()
    labels = {k: v - base for k, v in symbols(os.path.join(pw, kind + '.sym')).items() if 0 <= v - base < len(data)}
    for n, (lab, off) in OPERANDS.get(kind, {}).items():
        labels[n] = labels[lab] + off
    return data, labels


def read_player_txt(text):
    cfg = {'residue': [], 'tail': bytearray()}
    in_tail = False
    for line in text.split('\n'):
        if not line.strip() or line.startswith('#'):
            continue
        t = line.split()
        if line.startswith('  ') and in_tail:
            cfg['tail'] += bytes.fromhex(''.join(t))
        elif t[0] == 'player':
            cfg['kind'] = t[1]
        elif t[0] == 'tune':
            cfg['tune'] = t[1]
        elif t[0] == 'at':
            cfg['residue'].append((t[1], bytes.fromhex(''.join(t[2:]))))
        elif t[0] == 'tail':
            in_tail = True
        else:
            raise SystemExit('variants_music: player.txt: cannot read %r' % line)
    return cfg


def offset(spec, labels):
    """LABEL, LABEL+N (a label of the player's source) or +N (an offset from the piece's start, no label needed)"""
    if spec.startswith('+'):
        return int(spec[1:], 0)
    m = re.match(r'(\w+)([+-]\d+)?$', spec)
    if not m or m.group(1) not in labels:
        raise SystemExit('variants_music: player.txt: "at %s": no such label in the player' % spec)
    return labels[m.group(1)] + int(m.group(2) or 0)


def build_piece(vdir, cfg, work, asm, sub='', base=None):
    """the piece of music/ (at MusicPiece), or of a second piece in music/SUB at base (variant.json music_extra)"""
    mdir = os.path.join(vdir, 'music', sub)
    p = read_player_txt(open(os.path.join(mdir, 'player.txt')).read())
    kind = p['kind']
    data, labels = player(kind, base_of(cfg) if base is None else base, os.path.join(work, sub), asm)
    piece = bytearray(data[:KINDS[kind]['module']])
    for spec, b in p['residue']:
        a = offset(spec, labels)
        piece[a:a + len(b)] = b
    conv = importlib.import_module(KINDS[kind]['conv'])
    piece += conv.from_text(open(os.path.join(mdir, p['tune'])).read())
    piece += p['tail']
    # as the original's music.asm: tools/ay_render.py reads it (a second piece: music-SUB.bin)
    open(os.path.join(work, 'music-%s.bin' % sub if sub else 'music.bin'), 'wb').write(piece)
    return bytes(piece)


# ------------------------------------------------------------------------------------------------- conversion

def ref_piece(kind, asm=None):
    """the music piece of the kind's reference variant: its piece.bin, or built from its readable form"""
    vdir = os.path.join(VAR, KINDS[kind]['ref'])
    p = os.path.join(vdir, 'music', 'piece.bin')
    if os.path.exists(p):
        return open(p, 'rb').read()
    work = os.path.join(ROOT, 'work', 'docs', 'zbV', 'music', 'ref-' + kind)
    os.makedirs(work, exist_ok=True)
    return build_piece(vdir, json.load(open(os.path.join(vdir, 'variant.json'))), work, asm or default_asm())


def kind_of(piece, asm):
    """the player kind of a piece, by comparing it with each kind's reference variant's player"""
    for kind, k in KINDS.items():
        ref = ref_piece(kind, asm)[:k['module']]
        same = sum(a == b for a, b in zip(ref, piece[:k['module']]))
        if same > 0.6 * len(ref):
            return kind
    return None


def split(name, asm, work):
    """the files of variants/NAME/music in the readable form: {file name: text}"""
    vdir = os.path.join(VAR, name)
    cfg = json.load(open(os.path.join(vdir, 'variant.json')))
    pb = os.path.join(vdir, 'music', 'piece.bin')
    piece = open(pb, 'rb').read() if os.path.exists(pb) else build_piece(vdir, cfg, work, asm)   # again: re-split
    kind = kind_of(piece, asm)
    if not kind:
        raise SystemExit('variants_music: %s: no known player' % name)
    k = KINDS[kind]
    base = base_of(cfg)
    data, labels = player(kind, base, work, asm)
    mod = piece[k['module']:]
    if hasattr(importlib.import_module(k['conv']), 'set_org'):   # a rip's tune: its words are absolute addresses
        importlib.import_module(k['conv']).set_org(base + k['module'], k.get('version'))
    n = tune_length(kind, mod)
    conv = importlib.import_module(k['conv'])
    suffix, tune = conv.to_editable('music/%s.bin' % k['tune'], mod[:n])
    # the state bytes: runs of differing bytes (runs closer than 4 bytes merge)
    diff = [i for i in range(k['module']) if piece[i] != data[i]]
    runs = []
    for i in diff:
        if runs and i - runs[-1][1] < 4:
            runs[-1][1] = i + 1
        else:
            runs.append([i, i + 1])
    by_off = sorted((v, n) for n, v in labels.items() if not n.startswith('l_'))
    out = ['# The music piece of variant %s (tools/variants_music.py; the format in src/res/music/README.md):' % name,
           '# the player variants/players/%s at MusicPiece %s, the tune %s, then the tail.' %
           (kind, cfg['equ']['MusicPiece'], k['tune'] + '.txt'),
           '# "at LABEL+N" lines: the bytes the saved disk holds there in place of the source\'s (the player\'s',
           '# variables, self-modified operands and buffers as they were when the disk was saved).', '',
           'player ' + kind, 'tune ' + k['tune'] + '.txt']
    chunks = [(a, min(a + 16, b)) for r0, b in runs for a in range(r0, b, 16)]
    for a, b in chunks:
        lab = max((x for x in by_off if x[0] <= a), default=None)
        spec = '%s+%d' % (lab[1], a - lab[0]) if lab else 'MusicInit+%d' % a
        if lab and a == lab[0]:
            spec = lab[1]
        out.append('at %s %s' % (spec, ' '.join('%02X' % x for x in piece[a:b])))
    tail = mod[n:]
    if tail:
        out.append('tail')
        out += ['  ' + ' '.join('%02X' % x for x in tail[i:i + 32]) for i in range(0, len(tail), 32)]
    return kind, {'player.txt': '\n'.join(out) + '\n', k['tune'] + '.txt': tune.decode()}, piece


def convert(names, asm):
    """write each variant's readable form (from its piece.bin, or again from its readable form: the labels of a
    changed player source); keep it only when the piece comes back and the variant builds identical"""
    for name in names:
        vdir = os.path.join(VAR, name)
        mdir = os.path.join(vdir, 'music')
        work = os.path.join(ROOT, 'work', 'docs', 'zbV', 'music', 'conv-' + name)
        os.makedirs(work, exist_ok=True)
        try:
            kind, files, piece = split(name, asm, work)
        except (SystemExit, ValueError) as e:
            print('%s: %s; kept as it was' % (name, e))
            continue
        old = {f: open(os.path.join(mdir, f), 'rb').read() for f in os.listdir(mdir)}

        def restore():
            for f in os.listdir(mdir):
                if f not in old:
                    os.remove(os.path.join(mdir, f))
            for f, b in old.items():
                open(os.path.join(mdir, f), 'wb').write(b)
        for f, t in files.items():
            open(os.path.join(mdir, f), 'w').write(t)
        if os.path.exists(os.path.join(mdir, 'piece.bin')):
            os.remove(os.path.join(mdir, 'piece.bin'))
        cfg = json.load(open(os.path.join(vdir, 'variant.json')))
        if build_piece(vdir, cfg, work, asm) != piece:
            restore()
            print('%s: %s: the readable form does not give the piece back; kept as it was' % (name, kind))
            continue
        r = subprocess.run([os.path.join(ROOT, 'tools', 'build.sh'), '--variant', name], capture_output=True, text=True)
        text = (r.stdout + r.stderr).strip()
        if r.returncode or ' identical to ' not in text:
            restore()
            print('%s: %s: the build differs (%s); kept as it was' % (name, kind, text.splitlines()[-1:]))
            continue
        print('%s: %s, %s' % (name, kind, ', '.join(sorted(files))))


def image(kind):
    out = os.path.join(ROOT, 'work', 'parts', 'player-%s.bin' % kind)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    if kind not in KINDS:   # one part of a kind made of parts: its bytes in that kind's reference piece
        parent, k = next((p, k) for p, k in KINDS.items() if kind in dict(k.get('parts', [])))
        offs = [o for _n, o in k['parts']] + [k['module']]
        i = [n for n, _o in k['parts']].index(kind)
        data = ref_piece(parent)[offs[i]:offs[i + 1]]
    else:
        data = ref_piece(kind)[:KINDS[kind]['module']]
    open(out, 'wb').write(data)
    print('%s: %d bytes' % (os.path.relpath(out, ROOT), len(data)))


def main():
    cmd, args = sys.argv[1], sys.argv[2:]
    if cmd == 'image':
        image(args[0])
    elif cmd == 'convert':
        convert(args, default_asm())
    elif cmd == 'split':
        work = os.path.join(ROOT, 'work', 'docs', 'zbV', 'music', 'conv-' + args[0])
        os.makedirs(work, exist_ok=True)
        kind, files, piece = split(args[0], default_asm(), work)
        for f, t in files.items():
            print('==== %s\n%s' % (f, t if f == 'player.txt' else t[:400]))
    else:
        print(__doc__)
    return 0


if __name__ == '__main__':
    sys.exit(main())
