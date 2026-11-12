#!/usr/bin/env python3
"""Variant zyxlgbt: the Lotus Group boot's R-register cipher and its TRD image.

    python3 tools/lotus.py image loader|stage2 OUT   # the decrypted bytes a part .ann describes (from the candidate)
    python3 tools/lotus.py check                     # decrypt the candidate, encrypt the plain bytes back, compare

The boot (variants/zyxlgbt) is a whole TRD whose loader is encrypted in two layers. Both decrypt with the same
loop: A = R, then XOR the byte, XOR the address and the counter, store, next. R is the refresh register, set once
by LD R,A before the loop and stepped by every instruction fetch, so the key is fixed by the instructions the loop
runs, not by the data:

- the loader: line 1's REM copies 256 bytes ($5D84) to $9C40 and runs them; they decrypt $9C7D-$A07C (1024 bytes,
  the 195 that came from the file and 829 that did not) with R (set to 2), the byte, IX, SP ($404C) and DE (the
  count down from $0400). The first byte it decrypts is the offset of its own JR NZ back to the loop;
- stage 2: the loader reads track 5, sector 0 to $FDE8 and returns there; the sector decrypts $FE02-$FF01 the
  same way with R (set to $DE), the byte, HL and DE.

The cipher runs here in SkoolKit's Z80 simulator (the case's venv), the same instructions as on the machine, so R
is exact. Encryption runs the same loop in lockstep: before the loop reads a byte, the byte is 0, so the loop
computes the key itself; the cipher byte is that key XOR the plain byte, and the plain byte is what the loop
stores, as the real decryption does, so the loop runs on (its JR offset included) exactly as on the machine.
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import disk  # noqa: E402

PROG = 0x5D3B             # the BASIC's first byte (TR-DOS)
STUB = 0x5D76             # line 1's REM code: copies the loader to LOADER and RETs into it
COPY_FROM = 0x5D84        # the 256 bytes of the loader in the REM
LOADER = 0x9C40           # where they run
LOADER_LOOP = dict(start=LOADER, end=0x9C7E, read=0x9C65, store=0x9C74, reg='IX', lo=0x9C7D)
STAGE2 = 0xFDE8           # track 5, sector 0
STAGE2_LOOP = dict(start=STAGE2, end=0xFE03, read=0xFDF7, store=0xFDFC, reg='HL', lo=0xFE02)
SECTOR = 256
TRD_SIZE = 655360


def skoolkit():
    try:
        import skoolkit  # noqa: F401
    except ImportError:
        import glob
        sys.path.insert(0, os.path.join(ROOT, '..', '..', 'kit'))
        import toolpaths
        for sp in glob.glob(os.path.join(toolpaths.skoolkit_venv(''), 'lib', 'python*', 'site-packages')):
            sys.path.append(sp)
    from skoolkit.simulator import Simulator
    return Simulator


def run_loop(mem, loop, plain=None):
    """run a decryption loop from its start to its end; with plain ({address: byte}), encrypt in lockstep and
    return {address: cipher byte}"""
    sim = skoolkit()(mem, {'SP': 0xFF40, 'PC': loop['start'], 'IY': 0x5C3A})
    r, m = sim.registers, sim.memory
    out = {}
    for _ in range(200000):
        pc = r[24]
        if pc == loop['end']:
            return out
        addr = (r[8] << 8 | r[9]) if loop['reg'] == 'IX' else (r[6] << 8 | r[7])
        if plain is not None and pc == loop['read']:
            m[addr] = 0                       # the loop then computes the bare key
        if plain is not None and pc == loop['store'] and addr in plain:
            out[addr] = r[0] ^ plain[addr]    # key XOR plain: the byte the disk holds
            r[0] = plain[addr]                # and the loop stores the plain byte, as on the machine
        sim.run()
    raise SystemExit('lotus: the loop at $%04X did not end' % loop['start'])


def candidate():
    cfg = json.load(open(os.path.join(ROOT, 'variants', 'zyxlgbt', 'variant.json')))
    return open(os.path.join(ROOT, cfg['image']), 'rb').read()


def decrypt_loader(basic):
    """the loader's 256 bytes as they run at $9C40, from the boot's BASIC"""
    mem = bytearray(65536)
    mem[PROG:PROG + len(basic)] = basic
    mem[LOADER:LOADER + 256] = mem[COPY_FROM:COPY_FROM + 256]
    sim_mem = bytearray(mem)
    run_loop(sim_mem, LOADER_LOOP)
    return bytes(sim_mem[LOADER:LOADER + 256])


def decrypt_stage2(sector):
    mem = bytearray(65536)
    mem[STAGE2:STAGE2 + SECTOR] = sector
    run_loop(mem, STAGE2_LOOP)
    return bytes(mem[STAGE2:STAGE2 + SECTOR])


def encrypt(loop, base, plain):
    """the bytes the disk holds for plain (running at base), its first bytes before loop['lo'] left as they are"""
    mem = bytearray(65536)
    mem[base:base + len(plain)] = plain
    want = {base + i: b for i, b in enumerate(plain) if base + i >= loop['lo']}
    out = run_loop(mem, loop, want)
    return bytes(out.get(base + i, b) for i, b in enumerate(plain))


def encrypt_loader(plain):
    return encrypt(LOADER_LOOP, LOADER, plain)


def encrypt_stage2(plain):
    return encrypt(STAGE2_LOOP, STAGE2, plain)


def info_sector(first_free, files, free, label=b' ' * 8, deleted=0):
    """TR-DOS's disk information, track 0 sector 8 (a double-sided 80-track disk, type $16)"""
    s = bytearray(SECTOR)
    s[0xE1], s[0xE2] = first_free % 16, first_free // 16
    s[0xE3], s[0xE4] = 0x16, files
    s[0xE5], s[0xE6] = free & 255, free >> 8
    s[0xE7] = 0x10
    s[0xEA:0xF3] = b' ' * 9
    s[0xF4] = deleted
    s[0xF5:0xFD] = label
    return bytes(s)


def build(vdir, cfg, img, basic):
    """the TRD image: the catalogue, the information sector, the boot file (its loader encrypted), the sectors the
    loader reads by track and sector (cut from img, the variant's memory; stage 2 encrypted), the leftover bytes"""
    t = cfg['trd']
    trd = bytearray(TRD_SIZE)
    loader = bytes(img[LOADER:LOADER + 256])
    basic = bytearray(basic)
    o = COPY_FROM - PROG
    basic[o:o + 256] = encrypt_loader(loader)
    h = cfg['header']
    boot_lsn = t['boot_lsn']
    trd[boot_lsn * SECTOR:boot_lsn * SECTOR + len(basic)] = basic
    entry = cfg['file'].encode().ljust(8)[:8] + h['type'].encode() + bytes([
        h['start'] & 255, h['start'] >> 8, h['length'] & 255, h['length'] >> 8, h['sectors'], boot_lsn % 16, boot_lsn // 16])
    trd[0:16] = entry
    extra = bytes.fromhex(t.get('catalogue_extra', ''))
    trd[16:16 + len(extra)] = extra
    trd[8 * SECTOR:9 * SECTOR] = info_sector(t['first_free'], 1, t['free'])
    for p in t['pieces']:
        a, n, lsn = int(p['at'][1:], 16), p['sectors'] * SECTOR, p['lsn']
        d = bytes(img[a:a + n])
        if p.get('encrypt') == 'stage2':
            d = encrypt_stage2(d)
        trd[lsn * SECTOR:lsn * SECTOR + n] = d
    for f in t.get('files', []):
        d = open(os.path.join(vdir, f['file']), 'rb').read()
        trd[f['lsn'] * SECTOR:f['lsn'] * SECTOR + len(d)] = d
    return bytes(trd)


def compare(cfg, trd, work):
    """write work/variant.trd and compare it with the candidate image: (identical, message)"""
    open(os.path.join(work, 'variant.trd'), 'wb').write(trd)
    want = open(os.path.join(ROOT, cfg['image']), 'rb').read()
    if trd == want:
        return True, 'identical to %s' % os.path.basename(cfg['image'])
    first = next((i for i in range(min(len(trd), len(want))) if trd[i] != want[i]), min(len(trd), len(want)))
    return False, 'differs: image offset %d (track %d sector %d, byte %d)' % (
        first, first // 4096, first // 256 % 16, first % 256)


def main():
    a = sys.argv[1:]
    trd = candidate()
    basic = trd[9 * SECTOR:11 * SECTOR]
    if a[:1] == ['image']:
        data = decrypt_loader(basic) if a[1] == 'loader' else decrypt_stage2(trd[80 * SECTOR:81 * SECTOR])
        os.makedirs(os.path.dirname(os.path.join(ROOT, a[2])), exist_ok=True)
        open(os.path.join(ROOT, a[2]), 'wb').write(data)
        return 0
    if a[:1] == ['check']:
        lp = decrypt_loader(basic)
        ok1 = encrypt_loader(lp)[LOADER_LOOP['lo'] - LOADER:] == bytes(
            basic[COPY_FROM - PROG + LOADER_LOOP['lo'] - LOADER:COPY_FROM - PROG + 256])
        s2 = trd[80 * SECTOR:81 * SECTOR]
        ok2 = encrypt_stage2(decrypt_stage2(s2)) == s2
        print('lotus: loader %s, stage 2 %s' % ('round-trips' if ok1 else 'DIFFERS', 'round-trips' if ok2 else 'DIFFERS'))
        return 0 if ok1 and ok2 else 1
    print(__doc__)
    return 1


if __name__ == '__main__':
    sys.exit(main())
