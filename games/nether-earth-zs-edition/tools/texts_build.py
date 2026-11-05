#!/usr/bin/env python3
"""The five ZX Word texts of the '99 disk (the `W` files) from their UTF-8 sources, as their sectors lie on the disk.

    python3 tools/texts_build.py build --out build/texts      write build/texts/<NAME>.W (sector-padded)
    python3 tools/texts_build.py check --out build/texts      the same, then compare each with the file's sectors
                                                               in work/media/99/files/ (tools/zs_media.py writes them)

A file's sectors are, in order:
  1. the text: src/res/text/<NAME>.txt (UTF-8, LF) written in CP866 with CR LF line ends;
  2. the end mark, a $00 byte, where the author's editor wrote one (NEabout, NEdescri, NEgreets, NEadvice: it is the
     last byte of the catalogue length; the readme NEZSEd99.W has none);
  3. the slack up to the end of the last sector: zeros, or the bytes of src/res/text/slack/<NAME>.slack.bin where
     the editor left older bytes there (no program reads them).
The catalogue length (src/disk99.txt) is parts 1 + 2; the sector count is fixed, since the 128 K loader reads the
first 64 sectors after the game file into page 3 by position (docs/03-build-and-load.md): NEabout must stay within
15 sectors so that NEdescri starts at `$CF00` and so on. The build refuses a text that no longer fits.
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'src', 'res', 'text')
MEDIA = os.path.join(ROOT, 'work', 'media', '99', 'files')

# name, file index on the disk (work/media/99/files/NN_NAME.W), sectors, catalogue length, end mark
TEXTS = [
    ('NEabout', 1, 15, 3763, True),
    ('NEdescri', 2, 22, 5469, True),
    ('NEgreets', 3, 2, 313, True),
    ('NEadvice', 4, 22, 5572, True),
    ('NEZSEd99', 5, 22, 5384, False),
]


def encode(name, end_mark):
    """The text's bytes as the catalogue length counts them: CP866, CR LF, then the end mark"""
    with open(os.path.join(SRC, name + '.txt'), encoding='utf-8', newline='') as f:
        text = f.read()
    if '\r' in text:
        raise SystemExit(f'{name}.txt: has CR characters (the build writes CR LF itself; keep LF in the source)')
    data = text.replace('\n', '\r\n').encode('cp866')
    if b'\x00' in data:
        raise SystemExit(f'{name}.txt: a NUL character inside the text (the viewer reads it as the end)')
    return data + (b'\x00' if end_mark else b'')


def build_one(name, sectors, length, end_mark):
    data = encode(name, end_mark)
    if len(data) != length:
        print(f'texts_build: {name}: {len(data)} bytes, the catalogue says {length} (update src/disk99.txt)',
              file=sys.stderr)
    size = sectors * 256
    slack_path = os.path.join(SRC, 'slack', name + '.slack.bin')
    if os.path.exists(slack_path):
        with open(slack_path, 'rb') as f:
            slack = f.read()
        if len(data) + len(slack) != size:
            raise SystemExit(f'{name}: the text ({len(data)}) and its slack ({len(slack)}) do not fill {sectors} '
                             f'sectors ({size}); an edited text drops or trims the slack file')
    else:
        slack = bytes(max(0, size - len(data)))
    if len(data) > size:
        raise SystemExit(f'{name}: {len(data)} bytes do not fit in its {sectors} sectors (the page 3 layout)')
    return data + slack, len(data)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('action', choices=['build', 'check'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'texts'))
    args = p.parse_args()
    os.makedirs(args.out, exist_ok=True)
    bad = 0
    for name, index, sectors, length, end_mark in TEXTS:
        image, used = build_one(name, sectors, length, end_mark)
        out = os.path.join(args.out, name + '.W')
        with open(out, 'wb') as f:
            f.write(image)
        if args.action == 'check':
            ref_path = os.path.join(MEDIA, f'{index:02d}_{name}.W')
            if not os.path.exists(ref_path):
                raise SystemExit(f'{ref_path}: missing (run python3 tools/zs_media.py)')
            with open(ref_path, 'rb') as f:
                ref = f.read()
            if image == ref and used == length:
                print(f'{name}.W: {used} bytes + {len(image) - used} slack = {sectors} sectors, identical')
            else:
                first = next((i for i, (a, b) in enumerate(zip(image, ref)) if a != b), min(len(image), len(ref)))
                print(f'{name}.W: DIFFERS at byte {first} (built {len(image)}, disk {len(ref)})', file=sys.stderr)
                bad += 1
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
