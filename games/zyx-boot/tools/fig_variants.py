#!/usr/bin/env python3
"""The figures and the audio of doc 13 (the variants): every variant's menu, the logos and the rhombi, a WAV of each
distinct tune and the register timelines of the player kinds.

    python3 tools/fig_variants.py shots [NAME ...] [--port-base 37460]   # boot each variant, save its menu
    python3 tools/fig_variants.py sheets                                 # docs/img/variants/menus-sheet-N.png
    python3 tools/fig_variants.py logos                                  # docs/img/variants/logos.png, rhombi.png
    python3 tools/fig_variants.py audio                                  # docs/audio/variants/*.mp3
    python3 tools/fig_variants.py players                                # docs/img/variants/players.png

shots: one unreal-qt instance (offscreen, muted, RAM zeroed, a Pentagon 128K as the recordings c1-c4) boots, for each
variant, a disk made of the variant's boot file (saved as `boot`) and the 32 other files of tests/disks/many.scl, so
every menu lists the same catalogue (zyxlgbt, whose boot reads its pieces by track and sector, runs from its own
TRD). The keys are c1's (tests/inputs/c1.txt: CS 7, ENTER, R, ENTER onto TR-DOS's RUN). The machine then runs in
steps of 100 frames until the menu is drawn (the logo's 20 attribute cells at `$5806` and the catalogue's names in
place) and 600 frames more, so the reflection is drawn and the rhombi have turned; a loader that waits for a key
before the menu (zyxboot-09, zyxisl) gets SPACE after 600 frames without the menu. The screen is read from the
running machine (WebAPI memory read of `$4000-$5AFF`). Each shot's frame (counted from the power-on's end) goes to
work/docs/zbV/figs/shots.json.
"""
import argparse
import glob
import json
import os
import struct
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = os.path.join(ROOT, '..', '..', 'kit')
sys.path.insert(0, os.path.join(ROOT, 'tools'))
sys.path.insert(0, KIT)
import disk  # noqa: E402


def skoolkit_path():
    """SkoolKit's site-packages (the case's venv, kit/toolpaths.py) after this Python's own: ay_render.py runs the
    players in its simulator, numpy and matplotlib come from this Python"""
    try:
        import skoolkit  # noqa: F401
        return
    except ImportError:
        pass
    import toolpaths
    for sp in glob.glob(os.path.join(toolpaths.skoolkit_venv(''), 'lib', 'python*', 'site-packages')):
        sys.path.append(sp)

IMG = os.path.join(ROOT, 'docs', 'img', 'variants')
MENUS = os.path.join(ROOT, 'work', 'docs', 'zbV', 'figs', 'menus')   # one shot a variant: the sheets' input, linked by no doc
AUDIO = os.path.join(ROOT, 'docs', 'audio', 'variants')
TMP = os.path.join(ROOT, 'work', 'docs', 'zbV', 'figs')
WIDTH = 1050


def variants():
    return sorted(n for n in os.listdir(os.path.join(ROOT, 'variants'))
                  if os.path.isfile(os.path.join(ROOT, 'variants', n, 'variant.json')))


def config(name):
    return json.load(open(os.path.join(ROOT, 'variants', name, 'variant.json')))


# ----------------------------------------------------------------------------------------------------- shots

def test_disk(name):
    """the disk a variant boots from: its boot file as `boot` and many.scl's other files, or its own TRD"""
    cfg = config(name)
    image = os.path.join(ROOT, cfg['image'])
    if image.lower().endswith('.trd'):
        return image
    files, _ = disk.read(image)
    boot = next(f for f in files if f['name'] == cfg['file'])
    many, _ = disk.read(os.path.join(ROOT, 'tests', 'disks', 'many.scl'))
    entries = [('boot    ', boot)] + [(f['name'], f) for f in many if f['name'].strip() != 'boot']
    head, bodies = [], []
    for nm, f in entries:
        body = f['body'][:f['sectors'] * 256]
        head.append(nm.encode('latin-1') + f['type'].encode() + struct.pack('<HHB', f['start'], f['length'],
                                                                             f['sectors']))
        bodies.append(body)
    d = b'SINCLAIR' + bytes([len(entries)]) + b''.join(head) + b''.join(bodies)
    d += struct.pack('<I', sum(d) & 0xFFFFFFFF)
    os.makedirs(os.path.join(TMP, 'disks'), exist_ok=True)
    out = os.path.join(TMP, 'disks', name + '.scl')
    open(out, 'wb').write(d)
    return out


AFTER = 600   # frames after the menu is first seen: DrawReflection ends about 450 frames after DrawScreen (c1)
C1_KEYS = [(0, ['cs', '7']), (6, []), (14, ['enter']), (20, []), (144, ['r']), (150, []), (160, ['enter']),
           (166, [])]


def menu_shown(scr):
    """the menu's screen: the logo's attribute cells at $5806 not all one colour and ink in the catalogue's rows"""
    attrs = scr[6144 + 6:6144 + 26]
    names = sum(1 for r in range(48, 144) for b in scr[(r & 0xC0) << 5 | (r & 7) << 8 | (r & 0x38) << 2:][:32] if b)
    return len(set(attrs)) > 1 and names > 200


def shots(names, port_base):
    import shutil
    toolpaths = __import__('toolpaths')
    unreal = toolpaths.unreal_ng('')
    binary = toolpaths.unreal_binary('')
    sys.path.insert(0, os.path.join(unreal, 'tools', 'verification', 'mcp'))
    sys.path.insert(0, os.path.join(unreal, 'tools', 'verification', 'analysis'))
    import mcplib
    import corpus
    os.makedirs(os.path.join(MENUS), exist_ok=True)
    log_path = os.path.join(TMP, 'shots.json')
    log = json.load(open(log_path)) if os.path.exists(log_path) else {}
    process = mcplib.launch(binary, port_base)
    try:
        s = mcplib.Session(f'http://127.0.0.1:{port_base + 200}/mcp', 'PENTAGON')
        for name in names or variants():
            s.fresh_machine('PENTAGON', ram_power_on='zero')
            s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                                  'body': {'muted': True}}, ok=False)
            m = corpus.Machine(s, port_base)
            r = s.call('load_software', {'path': test_disk(name), 'autostart': False, 'play': False}, ok=False)
            if r.is_error:
                log[name] = {'error': r.text}
                continue
            run = lambda n: s.call('control_execution', {'action': 'run_frames', 'frames': n})
            at = 0
            run(100)
            at += 100
            held, last = [], 0
            for frame, keys in C1_KEYS:              # tests/inputs/c1.txt
                run(frame - last) if frame > last else None
                at += frame - last
                last = frame
                for k in held:
                    s.call('type_input', {'action': 'release', 'key': k})
                for k in keys:
                    s.call('type_input', {'action': 'press', 'key': k})
                held = keys
            seen, since, spaces = None, 0, 0
            while at < 4000:
                run(100)
                at += 100
                since += 100
                scr = m.read(0x4000, 6912)
                if menu_shown(scr):
                    seen = at
                    break
                if since >= 600 and spaces < 4:
                    s.call('type_input', {'action': 'press', 'key': 'space'})
                    run(8)
                    s.call('type_input', {'action': 'release', 'key': 'space'})
                    at += 8
                    since, spaces = 0, spaces + 1
            if seen is not None:
                run(AFTER)
                at += AFTER
            scr = m.read(0x4000, 6912)
            open(os.path.join(TMP, name + '.scr'), 'wb').write(scr)
            png(scr, os.path.join(MENUS, name + '.png'))
            log[name] = {'menu_at': seen, 'shot_at': at, 'spaces': spaces, 'disk': os.path.relpath(test_disk(name),
                                                                                                   ROOT)}
            print('%-12s menu %s, shot at frame %d%s' % (name, seen, at, ', %d SPACE' % spaces if spaces else ''))
            json.dump(log, open(log_path, 'w'), indent=1)
    finally:
        try:
            s.destroy_all()
        except Exception:  # noqa: BLE001
            pass
        process.terminate()
        try:
            process.wait(10)
        except subprocess.TimeoutExpired:
            process.kill()


PALETTE = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0),
           (205, 205, 205), (0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255),
           (255, 255, 0), (255, 255, 255)]


def scr_image(scr):
    from PIL import Image
    im = Image.new('RGB', (256, 192))
    px = im.load()
    for y in range(192):
        row = (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2
        for cx in range(32):
            a = scr[6144 + (y >> 3) * 32 + cx]
            ink, paper = PALETTE[(a & 7) | (a & 0x40) >> 3], PALETTE[(a >> 3 & 7) | (a & 0x40) >> 3]
            b = scr[row + cx]
            for bit in range(8):
                px[cx * 8 + bit, y] = ink if b & (0x80 >> bit) else paper
    return im


def png(scr, path):
    from PIL import Image
    scr_image(scr).resize((512, 384), Image.NEAREST).save(path)


# ----------------------------------------------------------------------------------------------------- sheets

def font(size):
    from PIL import ImageFont
    for p in ('/System/Library/Fonts/Supplemental/Arial.ttf', '/System/Library/Fonts/Helvetica.ttc',
              '/Library/Fonts/Arial.ttf'):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def sheet(tiles, cols, title, subtitle, out, tile_w, label_h=22, pad=8, bg=(255, 255, 255)):
    """tiles: [(label, PIL image)] in a grid cols wide, WIDTH px, a title and a subtitle line above"""
    from PIL import Image, ImageDraw
    th = int(tiles[0][1].height * tile_w / tiles[0][1].width)
    rows = (len(tiles) + cols - 1) // cols
    head = 64
    H = head + rows * (th + label_h + pad) + pad
    im = Image.new('RGB', (WIDTH, H), bg)
    d = ImageDraw.Draw(im)
    d.text((pad, 6), title, fill=(0, 0, 0), font=font(22))
    d.text((pad, 36), subtitle, fill=(60, 60, 60), font=font(15))
    gap = (WIDTH - cols * tile_w) / (cols + 1)
    for i, (label, t) in enumerate(tiles):
        r, c = divmod(i, cols)
        x = int(gap + c * (tile_w + gap))
        y = head + r * (th + label_h + pad)
        im.paste(t.resize((tile_w, th), Image.NEAREST), (x, y + label_h))
        d.multiline_text((x, y + 2), label, fill=(0, 0, 0), font=font(16), spacing=2)
    im.save(out)
    return out


def sheets():
    from PIL import Image
    names = [n for n in variants() if os.path.exists(os.path.join(MENUS, n + '.png'))]
    per = 15
    out = []
    for k in range(0, len(names), per):
        part = names[k:k + per]
        tiles = [(n, Image.open(os.path.join(MENUS, n + '.png'))) for n in part]
        n = k // per + 1
        p = os.path.join(IMG, 'menus-sheet-%d.png' % n)
        sheet(tiles, 3, 'The variants\' menus, %d-%d of %d: one program, %d faces' % (
            k + 1, k + len(part), len(names), len(names)),
            'Each variant boots a disk with the same 32 files (tests/disks/many.scl); the screen about 600 frames '
            'after the menu is drawn (fig_variants.py shots).', p, 330)
        out.append(p)
    for p in glob.glob(os.path.join(IMG, 'menus-sheet-*.png')):
        if p not in out:
            os.remove(p)
    print('sheets: ' + ', '.join(os.path.relpath(p, ROOT) for p in out))


# ----------------------------------------------------------------------------------------------------- logos

def res_png(name, rel):
    p = os.path.join(ROOT, 'variants', name, 'graphics', rel)
    if os.path.exists(p):
        return p, 'own'
    return os.path.join(ROOT, 'src', 'res', 'graphics', rel), 'original'


def own_loader(name):
    return config(name).get('loader') == 'own'


def logos():
    from PIL import Image
    tiles_l, tiles_r, groups_l, groups_r = [], [], {}, {}
    for n in variants():
        cfg = json.load(open(os.path.join(ROOT, 'variants', n, 'variant.json')))
        if own_loader(n) and not cfg.get('pieces') and not os.path.exists(os.path.join(ROOT, 'variants', n, 'graphics')):
            # an own loader not built from the resources yet: its drawings are cut from its menu screenshot
            shot = os.path.join(MENUS, n + '.png')
            if not os.path.exists(shot):
                continue
            im = Image.open(shot)
            logo = im.crop((6 * 16, 0, 26 * 16, 40 * 2))          # the logo: columns 6-25, pixel rows 0-39
            romb = im.crop((0, 0, 6 * 16, 40 * 2))               # the top-left rhombus: columns 0-5
            tiles_l.append((n + ' (screen)', logo.convert('RGB')))
            tiles_r.append((n + '\n(screen)', romb.convert('RGB')))
            continue
        for rel, tiles, groups in (('logo.png', tiles_l, groups_l), ('rhombus.png', tiles_r, groups_r)):
            p, src = res_png(n, rel)
            key = open(p, 'rb').read() if src == 'own' else b'orig'
            groups.setdefault(key, []).append(n)
            if len(groups[key]) == 1:
                tiles.append((n if src == 'own' else 'original', Image.open(p).convert('RGB')))
    # a tile shared by several variants is labelled with the first and the count
    def relabel(tiles, groups):
        out = []
        for label, im in tiles:
            g = next((v for v in groups.values() if v and v[0] == label), None)
            if label == 'original':
                g = groups.get(b'orig', [])
                label = 'original (%d)' % (len(g)) if g else 'original'
            elif g and len(g) > 1:
                label = '%s +%d' % (label, len(g) - 1)
            if len(im.getcolors(1 << 16) or []) == 1:
                label += ' (all paper)'
            out.append((label, im))
        return out
    tl = relabel(tiles_l, groups_l)
    tr = relabel(tiles_r, groups_r)
    sheet(tl, 4, 'The ZYX logo in %d distinct drawings' % len(tl),
          'graphics/logo.png of each variant (four 40x40 sprites); "+N": N more variants share it; "(screen)": '
          'cut from the menu screenshot (own loader).', os.path.join(IMG, 'logos.png'), 240)
    sheet(tr, 8, 'The rhombus: %d distinct source sprites' % len(tr),
          'graphics/rhombus.png (RombSource, 40x40, the sprite all 34 phases are built from); "+N": shared; '
          '"(screen)": cut from the menu, mid-turn.', os.path.join(IMG, 'rhombi.png'), 112, label_h=40)
    print('logos: %d logos, %d rhombi' % (len(tl), len(tr)))


# ----------------------------------------------------------------------------------------------------- audio

def tunes():
    """[(slug, title, author, [variants])]: the variants grouped by their tune's AY fingerprint"""
    ident = json.load(open(os.path.join(TMP, '..', 'ident-many.json')))
    groups = {}
    for n, r in sorted(ident.items()):
        fp = r['fp'].get('fp_exact')
        if not fp:
            continue
        groups.setdefault(fp, []).append(n)
    out = []
    for fp, ns in groups.items():
        hits = ident[ns[0]]['hits']
        title, author = (hits[0][1], hits[0][2]) if hits else ('unidentified', '')
        out.append((ns[0], title, author, ns, fp))
    return out


def audio(seconds=30, rate=22050):
    import wave
    import numpy as np
    import ay_render as A
    os.makedirs(AUDIO, exist_ok=True)
    rows = []
    for first, title, author, ns, fp in tunes():
        mem, init, play, start = A.variant_piece(first)
        fr = A.frames(mem, init, play, seconds * A.FRAME, start)
        tmp = os.path.join(TMP, first + '-44k.wav')
        A.wav(fr, tmp)
        with wave.open(tmp) as w:
            x = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2').astype(np.float32)
        y = x.reshape(-1, 2).mean(axis=1)                   # 44.1 kHz -> 22.05 kHz (a 2-tap average)
        out = os.path.join(AUDIO, first + '.wav')
        with wave.open(out, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(rate)
            w.writeframes(y.astype('<i2').tobytes())
        os.remove(tmp)
        mp3 = out[:-4] + '.mp3'                              # the repository keeps the MP3 (a tenth of the WAV)
        subprocess.run(['lame', '--quiet', '-V', '4', out, mp3], check=True)
        os.remove(out)
        out = mp3
        rows.append({'file': os.path.relpath(out, ROOT), 'title': title, 'author': author, 'variants': ns,
                     'seconds': seconds, 'bytes': os.path.getsize(out), 'fp_exact': fp})
        print('%-14s %-40s %s' % (first, title[:40], ', '.join(ns)))
    json.dump(rows, open(os.path.join(TMP, 'audio.json'), 'w'), indent=1)


# ----------------------------------------------------------------------------------------------------- players

PLAYERS = [('original', 'ASC Sound Master (the original: Disco music, Ant P)'),
           ('zyxdebt', 'Sound Tracker, compiled (zyxdebt: Lyra 2 demo 05, Ziutek)'),
           ('zyxboot-06', "Fuxoft's player (zyxboot-06: Magnetic Fields IV, F. Fuka)"),
           ('zyxboot-11', 'A game rip (zyxboot-11: Stormbringer, D. Whittaker)')]


def players(frames=300):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import numpy as np
    import ay_render as A
    fig, axes = plt.subplots(len(PLAYERS), 1, figsize=(10.5, 2.6 * len(PLAYERS) + 0.8), dpi=100, sharex=True)
    for ax, (name, title) in zip(axes, PLAYERS):
        mem, init, play, start = A.variant_piece(name)
        fr = A.frames(mem, init, play, frames, start)
        x = np.arange(frames)
        for c, col in zip(range(3), ('tab:blue', 'tab:orange', 'tab:green')):
            per = np.array([r[2 * c] | (r[2 * c + 1] & 15) << 8 for r in fr], dtype=float)
            vol = np.array([r[8 + c] for r in fr])
            ton = np.array([not r[7] >> c & 1 for r in fr])
            note = np.where((per > 0) & ton & ((vol & 15) > 0) | (vol & 16 > 0) & (per > 0),
                            12 * np.log2(np.maximum(A.CLOCK / 16 / np.maximum(per, 1), 1) / 440) + 69, np.nan)
            ax.plot(x, note, '.', ms=2.5, color=col, label='channel %s tone' % 'ABC'[c])
            noise = np.array([not r[7] >> (c + 3) & 1 for r in fr]) & ((vol & 15) > 0)
            ax.plot(x[noise], np.full(noise.sum(), 26 + 3 * c), '|', ms=6, color=col)
        env = [i for i, r in enumerate(fr) if r[14]]
        ax.plot(env, [22] * len(env), 'kv', ms=4, label='R13 written (envelope restart)')
        ax.set_title(title, fontsize=12, loc='left')
        ax.set_ylabel('MIDI note', fontsize=11)
        ax.set_ylim(18, 100)
        ax.grid(alpha=0.3)
        ax.tick_params(labelsize=10)
    axes[0].legend(fontsize=10, ncol=4, loc='upper right', framealpha=0.9)
    axes[-1].set_xlabel('frame after the init (50 a second); short bars at the bottom: noise on per channel',
                        fontsize=11)
    fig.suptitle('Four players, four ways to fill the AY: the first %d frames of each' % frames, fontsize=14)
    fig.tight_layout()
    out = os.path.join(IMG, 'players.png')
    fig.savefig(out)
    print('players: ' + os.path.relpath(out, ROOT))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['shots', 'sheets', 'logos', 'audio', 'players'])
    p.add_argument('names', nargs='*')
    p.add_argument('--port-base', type=int, default=37460)
    a = p.parse_args()
    os.makedirs(TMP, exist_ok=True)
    os.makedirs(IMG, exist_ok=True)
    skoolkit_path()
    if a.command == 'shots':
        shots(a.names, a.port_base)
    elif a.command == 'sheets':
        sheets()
    elif a.command == 'logos':
        logos()
    elif a.command == 'audio':
        audio()
    elif a.command == 'players':
        players()
    return 0


if __name__ == '__main__':
    sys.exit(main())
