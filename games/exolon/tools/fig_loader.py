#!/usr/bin/env python3
"""Doc 03 figures of the load, from the power-on recording c1 (re_session.py capture --record-load, work/c1).
Copied from the Zynaps case's tools/fig_loader.py and changed to Exolon's loader and streams.

    python3 tools/fig_loader.py decrypt --work work/docs/docA/c1 --window 250:34000-251:6000 \
        --out docs/img/load/decrypt.gif
    python3 tools/fig_loader.py unpack --work work/docs/docA/c1 --window 1808:61000-1826:0 \
        --out docs/img/load/picy-unpack.gif

decrypt: Decrypt `$FC00` at work on the 768 bytes of the loader, from an access trace of c1 250:34000-251:6000
(kit/kitlib.py load_trace caches it in W/traces): every byte a cell with its value, red while it is as the tape
holds it, green once XORed with the next, the byte HL points at boxed; the last picture names the parts.

unpack: the picy unpacker `$800B`, from a trace of c1 1808:61000-1826:0: the TV picture (black until the attributes
come last) beside the bitmap as written, each new byte coloured by how it was made (a literal or a repeat), and the
three streams used up.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

BG, PANEL, TEXT, DIM = K.BACKGROUND, K.PANEL, K.TEXT, K.DIM
RED, GREEN, YELLOW, CYAN, GREY = (150, 45, 50), (45, 130, 70), (255, 230, 90), (90, 210, 230), (70, 70, 82)

# The loader's parts (src/tape/loader.asm, build/loader.lst)
CHAIN_LO, CHAIN_HI = 0xFC13, 0xFEA2  # LD BC,$0290: 656 bytes
PARTS = [(0xFC00, 0xFC12, 'Decrypt (plain)'), (0xFC13, 0xFC15, 'JP Start'), (0xFC16, 0xFC31, 'counter state, Header'),
         (0xFC32, 0xFC89, 'DigitGlyphs: 11 inverted digits'), (0xFC8A, 0xFD3A, 'LdBytes: the ROM LD-BYTES, moved'),
         (0xFD3B, 0xFE0E, 'CountStep: the countdown in the edge delay'), (0xFE0F, 0xFE39, 'CountSet'),
         (0xFE3A, 0xFE5E, 'Start'), (0xFE5F, 0xFE70, 'MoveStub'), (0xFE71, 0xFEA2, 'LoadFile (type 42 check)'),
         (0xFEA3, 0xFEFF, 'plain tail: zeros, RAM left-overs, ROM SA-DATA')]


def tape_block(n):
    import image
    for b in image.blocks():
        if b['index'] == n:
            return b['data'][1:-1]


def decrypt(args):
    t = K.load_trace(args)
    tape = bytes(tape_block(4))
    mem = bytearray(t.memory)
    f = K.font(11)
    fb = K.font(15)
    cw, ch, left, top = 26, 17, 60, 60
    W, H = left + 32 * cw + 20, top + 24 * ch + 160
    pictures, durations = [], []
    done_at = {}

    def picture(x, last_hl, final=False):
        im = Image.new('RGB', (W, H), BG)
        d = ImageDraw.Draw(im)
        d.text((12, 10), 'Decrypt $FC00: byte[i] ^= byte[i+1] from $FC13 up to $FEA2; the loader appears byte by byte',
               fill=TEXT, font=fb)
        n = sum(1 for a in range(0xFC13, CHAIN_HI + 1) if a in done_at)
        d.text((12, 32), f'c1 frame {x.frame} T {x.t}: {n} of 656 bytes decrypted' + ('' if final else
               f', HL = ${last_hl:04X}'), fill=DIM, font=f)
        for i in range(768):
            a = 0xFC00 + i
            r, c = divmod(i, 32)
            x0, y0 = left + c * cw, top + r * ch
            if a < 0xFC13 or a > CHAIN_HI:
                fill = GREY
            elif a in done_at:
                fill = YELLOW if done_at[a] >= len(pictures) - 1 and not final else GREEN
            else:
                fill = RED
            d.rectangle((x0, y0, x0 + cw - 2, y0 + ch - 2), fill=fill)
            d.text((x0 + 4, y0 + 2), f'{mem[a]:02X}', fill=(15, 15, 15) if fill == YELLOW else TEXT, font=f)
            if a == last_hl and not final:
                d.rectangle((x0 - 1, y0 - 1, x0 + cw - 1, y0 + ch - 1), outline=(255, 255, 255), width=2)
        for r in range(24):
            d.text((6, top + r * ch + 2), f'${0xFC00 + 32 * r:04X}', fill=DIM, font=f)
        y = top + 24 * ch + 10
        for k, (col, txt) in enumerate([(GREY, 'plain on the tape (Decrypt and the tail)'),
                                         (RED, 'as the tape holds it (encrypted)'),
                                         (GREEN, 'decrypted'), (YELLOW, 'decrypted in this step')]):
            xx = 12 + (k % 2) * 430
            yy = y + (k // 2) * 20
            d.rectangle((xx, yy + 2, xx + 14, yy + 14), fill=col)
            d.text((xx + 22, yy), txt, fill=TEXT, font=f)
        if final:
            yy = y + 48
            for k, (lo, hi, name) in enumerate(PARTS):
                xx = 12 + (k % 2) * 430
                d.text((xx, yy + (k // 2) * 15), f'${lo:04X}-${hi:04X} {name}', fill=TEXT, font=f)
            for lo, hi, name in PARTS:
                i = lo - 0xFC00
                r, c = divmod(i, 32)
                d.line((left + c * cw - 1, top + r * ch, left + c * cw - 1, top + r * ch + ch - 2), fill=(255, 255, 255),
                       width=2)
        return im

    xs = t.instructions
    steps = [i for i, x in enumerate(xs) if x.pc == 0xFC0B]  # LD (HL),A: one a byte
    picks = set(steps[k * (len(steps) - 1) // 59] for k in range(60))
    first = True
    for i, x in enumerate(xs):
        if x.pc == 0xFC0B:
            for c in x.cycles:
                pass
        for c in x.cycles:
            if c.tag == 'W':
                mem[c.address] = c.value
                if 0xFC13 <= c.address <= CHAIN_HI and x.pc == 0xFC0B:
                    done_at[c.address] = len(pictures)
        if first and x.pc == 0xFC00:
            pictures.append(picture(x, x.hl))
            durations.append(1500)
            first = False
        if i in picks:
            pictures.append(picture(x, x.hl))
            durations.append(90)
        if x.pc == 0xFC13:
            pictures.append(picture(x, 0, final=True))
            durations.append(6000)
            break
    K.save_gif(args.out, pictures, durations)
    changed = sum(1 for a in range(0xFC13, CHAIN_HI + 1) if mem[a] != tape[a - 0xFC00])
    print(f'{args.out}: {len(pictures)} pictures; {changed} of 656 bytes changed; Decrypt from '
          f'{xs[steps[0]].frame}:{xs[steps[0]].t} to {xs[steps[-1]].frame}:{xs[steps[-1]].t}')


def unpack(args):
    t = K.load_trace(args)
    mem = bytearray(t.memory)
    LIT, MASK, FLAG = 0x809E, 0x8BC0, 0x8F0C  # build/picy.lst: Literals, Masks, Flags
    lit_pc, rep_pc = 0x8073, 0x8081
    kind = {}
    f, fb = K.font(12), K.font(15)
    S = 1.5
    sw, sh = int(256 * S), int(192 * S)
    W, H = 900, sh + 230
    pictures, durations = [], []
    state = {'iy': LIT, 'hl': MASK, 'de': FLAG, 'out': 0}

    def bitmap_view(recent):
        im = Image.new('RGB', (256, 192), (10, 10, 14))
        px = im.load()
        for a in range(0x4000, 0x5800):
            if a not in kind:
                continue
            y = K.screen_line(a)
            col = (a & 31) * 8
            fresh = a in recent
            on = (YELLOW if kind[a] == 'L' else CYAN) if fresh else (230, 230, 230)
            off = (90, 80, 30) if fresh and kind[a] == 'L' else (30, 80, 90) if fresh else (36, 36, 44)
            v = mem[a]
            for b in range(8):
                px[col + b, y] = on if v & (0x80 >> b) else off
        d = ImageDraw.Draw(im)
        for a in range(0x5800, 0x5B00):
            if a in recent:
                r, c = divmod(a - 0x5800, 32)
                d.rectangle((c * 8, r * 8, c * 8 + 7, r * 8 + 7), outline=YELLOW if kind[a] == 'L' else CYAN)
        return im

    def picture(x, recent, phase):
        im = Image.new('RGB', (W, H), BG)
        d = ImageDraw.Draw(im)
        d.text((12, 8), 'picy: 6912 bytes in screen order; the picture shows only when the attributes come last', fill=TEXT, font=fb)
        d.text((12, 30), f'c1 frame {x.frame} T {x.t}: {phase}', fill=DIM, font=f)
        tv = K.render_screen(mem).resize((sw, sh), Image.NEAREST)
        bm = bitmap_view(recent).resize((sw, sh), Image.NEAREST)
        im.paste(tv, (15, 55))
        im.paste(bm, (35 + sw, 55))
        d.text((15, 55 + sh + 4), 'what the TV shows', fill=TEXT, font=f)
        d.text((35 + sw, 55 + sh + 4), 'the bitmap as written (new attributes: frames)', fill=TEXT, font=f)
        y = 55 + sh + 30
        bars = [('output bytes $4000-$5AFF', state['out'], 6912, (220, 220, 220)),
                ('literals $809E (IY)', state['iy'] - LIT, 2850, YELLOW),
                ('masks $8BC0 (HL): a bit a byte, set = repeat the last byte', state['hl'] - MASK, 844, CYAN),
                ('flags $8F0C (DE): a bit for 8 bytes, set = a mask follows', state['de'] - FLAG, 108, (200, 120, 230))]
        for k, (name, n, total, col) in enumerate(bars):
            yy = y + k * 26
            d.text((15, yy), f'{name}', fill=TEXT, font=f)
            bx = 450
            d.rectangle((bx, yy + 2, bx + 300, yy + 14), outline=(90, 90, 100))
            d.rectangle((bx, yy + 2, bx + int(300 * max(0, min(n, total)) / total), yy + 14), fill=col)
            d.text((bx + 310, yy), f'{max(0, n)} / {total}', fill=TEXT, font=f)
        d.rectangle((15, y + 110, 29, y + 122), fill=YELLOW)
        d.text((35, y + 108), 'a literal from the stream', fill=TEXT, font=f)
        d.rectangle((260, y + 110, 274, y + 122), fill=CYAN)
        d.text((280, y + 108), 'a repeat of the byte before', fill=TEXT, font=f)
        return im

    xs = t.instructions
    writes = [i for i, x in enumerate(xs) if x.pc in (lit_pc, rep_pc)]
    clear_end = next(i for i, x in enumerate(xs) if x.pc == 0x803B) if any(x.pc == 0x803B for x in xs) else 0
    picks = set(writes[k * (len(writes) - 1) // 69] for k in range(70))
    recent = set()
    started = False
    for i, x in enumerate(xs):
        if x.pc == 0x800B and not started:
            started = True
            pictures.append(picture(x, set(), 'the loader calls $8001'))
            durations.append(1200)
        if started and 0x8000 <= x.pc < 0x8100:
            if x.iy >= LIT and x.pc >= 0x8040:
                state['iy'], state['hl'], state['de'] = x.iy, x.hl, x.de
        for c in x.cycles:
            if c.tag == 'W':
                mem[c.address] = c.value
                if 0x4000 <= c.address < 0x5B00 and x.pc in (lit_pc, rep_pc):
                    kind[c.address] = 'L' if x.pc == lit_pc else 'R'
                    recent.add(c.address)
                    state['out'] += 1
        if i == clear_end and clear_end:
            pictures.append(picture(x, set(), 'the screen cleared (LDIR, 2.4 frames); the unpack starts'))
            durations.append(900)
        if i in picks:
            pictures.append(picture(x, recent, 'bitmap' if state['out'] < 6144 else 'attributes: the picture appears'))
            durations.append(110)
            recent = set()
        if x.pc == 0x809D:
            state['iy'], state['hl'], state['de'] = LIT + 2850, MASK + 844, FLAG + 108
            pictures.append(picture(x, set(), 'done: EI, RET to the loader'))
            durations.append(5000)
            break
    K.save_gif(args.out, pictures, durations)
    lits = sum(1 for v in kind.values() if v == 'L')
    print(f'{args.out}: {len(pictures)} pictures; {len(kind)} bytes: {lits} literals, {len(kind) - lits} repeats')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['decrypt', 'unpack'])
    K.add_trace_args(p)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    {'decrypt': decrypt, 'unpack': unpack}[args.what](args)


if __name__ == '__main__':
    main()
