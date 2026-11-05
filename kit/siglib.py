"""The signature base's shared code: entries, masks, anchors, matches, sjasmplus listings (docs/signature-format.md)

Used by sig_index.py, sig_scan.py and sig_add.py.
"""
import hashlib
import importlib.util
import json
import os
import re

KIT = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(KIT)
BASE = os.path.join(REPO, 'signatures')

SCHEMA = 1
ANCHOR_LENGTH = 12
ANCHORS_PER_ENTRY = 8
MIN_DISTINCT = 4
MIN_UNMASKED = 32

DOMAINS = ('sound', 'packers', 'protection', 'disk', 'tape', 'system', 'graphics', 'rom', 'programs', 'formats')
KINDS = ('code', 'data', 'format', 'rom')
ROLES = ('player', 'sfx', 'depacker', 'packer-setup', 'protection-layer', 'loader', 'sector-reader', 'interrupt',
         'input', 'paging', 'print', 'screen', 'sprite', 'font', 'picture', 'table', 'rom-call', 'game-module',
         'demo-part', 'music-data', 'stream')
MASK_KINDS = ('rel16', 'rel8hi', 'ext16', 'var8', 'var16', 'data')
RELATIONS = ('newer', 'older', 'patched', 'same-family', 'contains', 'part-of')
NAMED_MASKS = ('ext16', 'data')


def addr(text):
    """'$C000' / 'C000' / '0xC000' / '49152' -> int"""
    if isinstance(text, int):
        return text
    t = text.strip()
    if t.startswith('$'):
        return int(t[1:], 16)
    if t.lower().startswith('0x'):
        return int(t, 16)
    if re.fullmatch(r'[0-9A-Fa-f]{4}', t):
        return int(t, 16)
    return int(t)


def hexaddr(a):
    return '$%04X' % (a & 0xFFFF)


# ---- entries

def entry_dirs(base=BASE):
    """every folder under base that holds a sig.json"""
    out = []
    for root, dirs, files in os.walk(base):
        dirs.sort()
        if 'sig.json' in files:
            out.append(root)
    return out


def entry_id(path, base=BASE):
    return os.path.relpath(path, base).replace(os.sep, '/')


def load_entry(path):
    sig = json.load(open(os.path.join(path, 'sig.json')))
    data = None
    if sig.get('bytes'):
        data = open(os.path.join(path, sig['bytes']['file']), 'rb').read()
    return sig, data


def save_entry(path, sig, data=None):
    os.makedirs(path, exist_ok=True)
    if data is not None:
        open(os.path.join(path, sig['bytes']['file']), 'wb').write(data)
    with open(os.path.join(path, 'sig.json'), 'w') as f:
        json.dump(sig, f, indent=2, ensure_ascii=False)
        f.write('\n')


def masked_offsets(sig):
    out = set()
    for m in sig.get('mask', []):
        out.update(range(m['offset'], m['offset'] + m['length']))
    return out


def masked_bytes(data, sig):
    b = bytearray(data)
    for i in masked_offsets(sig):
        if i < len(b):
            b[i] = 0
    return bytes(b)


def sha1(b):
    return hashlib.sha1(b).hexdigest()


def anchors(data, sig):
    """up to 8 anchors (entry offset, 12 bytes) from the unmasked runs, spread over the entry"""
    masked = masked_offsets(sig)
    ok = []
    for i in range(0, len(data) - ANCHOR_LENGTH + 1):
        if any((i + k) in masked for k in range(ANCHOR_LENGTH)):
            continue
        w = data[i:i + ANCHOR_LENGTH]
        if len(set(w)) < MIN_DISTINCT:
            continue
        ok.append(i)
    if len(ok) <= ANCHORS_PER_ENTRY:
        picked = ok
    else:
        picked = []
        for k in range(ANCHORS_PER_ENTRY):
            target = k * (len(data) - ANCHOR_LENGTH) / (ANCHORS_PER_ENTRY - 1)
            best = min(ok, key=lambda i: abs(i - target))
            if best not in picked:
                picked.append(best)
    return [(i, data[i:i + ANCHOR_LENGTH].hex()) for i in sorted(picked)]


def word(b, i):
    return b[i] | b[i + 1] << 8


def match_at(sig, data, mem, start, base):
    """the 3.8 match of the entry at mem[start:], mem loaded at base: None, or a hit dict"""
    n = len(data)
    if start < 0 or start + n > len(mem):
        return None
    seg = mem[start:start + n]
    address = (base + start) & 0xFFFF
    delta = (address - addr(sig['origin'])) & 0xFFFF
    hit = {'id': sig['id'], 'address': hexaddr(address), 'match': None, 'delta': delta_text(delta),
           'values': {}, 'differs': []}
    if seg == data:
        hit['match'] = 'exact'
        return hit
    masked = masked_offsets(sig)
    differs = [i for i in range(n) if i not in masked and seg[i] != data[i]]
    if differs:
        hit['match'] = 'candidate'
        hit['differs'] = differs
        return hit
    rel, high = set(), []
    for m in sig.get('mask', []):
        o, kind, name = m['offset'], m['kind'], m.get('name')
        if kind == 'rel16':
            rel.add((word(seg, o) - word(data, o)) & 0xFFFF)
        elif kind == 'rel8hi':
            high.append((seg[o] - data[o]) & 0xFF)
        elif kind in ('ext16', 'var16'):
            hit['values'][name or '+%d' % o] = hexaddr(word(seg, o))
        elif kind == 'var8':
            hit['values'][name or '+%d' % o] = seg[o]
        elif kind == 'data':
            hit['values'][name or '+%d' % o] = '%s-%s' % (hexaddr(address + o), hexaddr(address + o + m['length'] - 1))
    # the rel16 words say where the copy runs: here, or (a copy a program moves before it runs) somewhere else
    run = rel.pop() if len(rel) == 1 else delta if not rel else None
    if run is None:
        hit['match'] = 'candidate'
        hit['note'] = 'the rel16 words disagree: %s' % ', '.join(sorted(delta_text(d) for d in rel))
        return hit
    if high and (run & 0xFF or any(h != run >> 8 for h in high)):
        hit['match'] = 'candidate'
        hit['note'] = 'the rel8hi bytes do not follow the rel16 words (%s)' % delta_text(run)
        return hit
    if n - len(masked) < MIN_UNMASKED:
        hit['match'] = 'candidate'
        hit['note'] = 'fewer than %d unmasked bytes' % MIN_UNMASKED
        return hit
    if run != delta:
        hit['runs_at'] = hexaddr(addr(sig['origin']) + run)
        hit['delta'] = delta_text(run)
    hit['match'] = 'masked'
    return hit


def delta_text(d):
    d &= 0xFFFF
    return '+%s' % hexaddr(d) if d < 0x8000 else '-%s' % hexaddr(0x10000 - d)


def load_detector(path):
    spec = importlib.util.spec_from_file_location('detect_' + re.sub(r'\W', '_', path), path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.detect


# ---- Z80: where an instruction holds a 16-bit address

LEN3 = {0x01, 0x11, 0x21, 0x31, 0x22, 0x2A, 0x32, 0x3A, 0xC2, 0xC3, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA,
        0xC4, 0xCC, 0xCD, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC}
ED4 = {0x43, 0x4B, 0x53, 0x5B, 0x63, 0x6B, 0x73, 0x7B}
INDEX_WORD = {0x21, 0x22, 0x2A}  # LD IX,nn / LD (nn),IX / LD IX,(nn)


def word_operand(b, i):
    """the offset (from i) of the 16-bit operand of the instruction at b[i], or None"""
    if i >= len(b):
        return None
    op = b[i]
    if op in (0xDD, 0xFD):
        return 2 if i + 1 < len(b) and b[i + 1] in INDEX_WORD else None
    if op == 0xED:
        return 2 if i + 1 < len(b) and b[i + 1] in ED4 else None
    if op == 0xCB:
        return None
    return 1 if op in LEN3 else None


def classify(value, lo, hi):
    """rel16 for an address inside the piece [lo, hi), None for the ROM (fixed), ext16 otherwise"""
    if lo <= value < hi:
        return 'rel16'
    if value < 0x4000:
        return None
    return 'ext16'


def build_mask(data, origin, starts, words=(), ext_names=None):
    """the mask from the instruction starts (offsets) and the data words (offsets) that hold addresses"""
    lo, hi = origin, origin + len(data)
    mask = []
    ext_names = ext_names or {}
    seen = set()
    for i in sorted(starts):
        o = word_operand(data, i)
        if o is None or i + o + 2 > len(data):
            continue
        at = i + o
        v = word(data, at)
        kind = classify(v, lo, hi)
        if kind and at not in seen:
            seen.add(at)
            m = {'offset': at, 'length': 2, 'kind': kind}
            if kind == 'ext16':
                m['name'] = ext_names.get(v) or 'ext_%04X' % v
            mask.append(m)
    for at in sorted(words):
        if at + 2 > len(data) or at in seen:
            continue
        v = word(data, at)
        if lo <= v < hi:
            seen.add(at)
            mask.append({'offset': at, 'length': 2, 'kind': 'rel16'})
    mask.sort(key=lambda m: m['offset'])
    return mask


# ---- sjasmplus listings

DATA_DIRECTIVES = {'DB', 'DEFB', 'DM', 'DEFM', 'DW', 'DEFW', 'DS', 'DEFS', 'BLOCK', 'INCBIN', 'DZ', 'DC', 'DD',
                   'DEFD', 'D24', 'DG', 'DH', 'DEFG', 'DEFH', 'ABYTE', 'ABYTEC', 'ABYTEZ', 'BYTE', 'WORD', 'DWORD'}
WORD_DIRECTIVES = {'DW', 'DEFW', 'WORD'}
LINE = re.compile(r'^\s*(\d+)\+*\s+([0-9A-F]{4})(.*)$')
BYTES = re.compile(r'^[0-9A-F]{2}( [0-9A-F]{2})*$')
LABEL = re.compile(r'^@?(\.?[A-Za-z_][\w.]*):?(?=\s|$|;)')


def read_listing(path):
    """the listing's rows: [line number, address, bytes, source, is instruction, is a word directive, label]"""
    rows = []
    for text in open(path, errors='replace'):
        text = text.rstrip('\n')
        m = LINE.match(text)
        if not m:
            continue
        number, a, rest = int(m.group(1)), int(m.group(2), 16), m.group(3)
        if rest[1:2] == '~':
            continue
        field = rest[1:13].strip()
        raw = bytes.fromhex(field.replace(' ', '')) if field and BYTES.match(field) else b''
        source = rest[14:] if len(rest) > 14 else ''
        if rest[13:14] == '>':
            source = rest[14:]
        label = None
        if source and not source[0].isspace():
            lm = LABEL.match(source)
            if lm:
                label = lm.group(1)
                body = source[lm.end():]
            else:
                body = ''
        else:
            body = source
        body = body.split(';', 1)[0].strip()
        mnemonic = body.split()[0].upper() if body else ''
        comment = source.split(';', 1)[1].strip() if ';' in source else ''
        if label and mnemonic in ('EQU', '=', 'DEFL'):
            continue
        rows.append({'line': number, 'address': a, 'bytes': raw, 'mnemonic': mnemonic,
                     'instruction': bool(raw) and mnemonic not in DATA_DIRECTIVES and not mnemonic.startswith('.'),
                     'words': mnemonic in WORD_DIRECTIVES, 'label': label, 'comment': comment,
                     'continuation': bool(raw) and not source.strip()})
    return rows


def listing_piece(rows, start, end, nth=1, image=None, image_origin=None):
    """the piece from label start to label end (exclusive), the nth time start appears in the listing:
    (origin, bytes, instruction offsets, word offsets, labels [(offset, name, comment)]). The bytes come from the
    listing; an INCBIN shows only its first bytes there, so with image (loaded at image_origin, the run address of
    its first byte) the bytes come from the image and the listing's bytes are checked against it"""
    seen, i0 = 0, None
    for i, r in enumerate(rows):
        if r['label'] == start:
            seen += 1
            if seen == nth:
                i0 = i
                break
    if i0 is None:
        raise SystemExit(f'listing: label {start} (time {nth}) not found')
    i1 = None
    for i in range(i0 + 1, len(rows)):
        if rows[i]['label'] == end:
            i1 = i
            break
    if i1 is None:
        raise SystemExit(f'listing: label {end} after {start} not found')
    origin = rows[i0]['address']
    length = (rows[i1]['address'] - origin) & 0xFFFF
    listed = {}
    starts, words, labels = [], [], []
    last = None
    for r in rows[i0:i1]:
        off = (r['address'] - origin) & 0xFFFF
        if off >= length and r['bytes']:
            raise SystemExit(f'listing: {hexaddr(r["address"])} (line {r["line"]}) lies outside {start}-{end}')
        if r['label'] and off < length:
            name = r['label'][1:2].upper() + r['label'][2:] if r['label'].startswith('.') else r['label']
            labels.append((off, name, r['comment']))
        if not r['bytes']:
            continue
        if not r['continuation']:
            last = r
            if r['instruction']:
                starts.append(off)
        if last is not None and last['words']:
            words.extend(range(off, off + len(r['bytes']), 2))
        for k, b in enumerate(r['bytes']):
            listed[off + k] = b
    if image is not None:
        at = (origin - image_origin) & 0xFFFF
        data = bytes(image[at:at + length])
        if len(data) != length:
            raise SystemExit(f'image: {start}-{end} runs past its end')
        bad = [o for o, b in listed.items() if data[o] != b]
        if bad:
            raise SystemExit(f'image: differs from the listing at {", ".join(hexaddr(origin + o) for o in bad[:8])}')
    else:
        missing = [o for o in range(length) if o not in listed]
        if missing:
            raise SystemExit(f'listing: {len(missing)} bytes not listed from {hexaddr(origin + missing[0])} (an INCBIN?):'
                             ' give the image')
        data = bytes(listed[o] for o in range(length))
    return origin, data, starts, words, labels


def kit_import(name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(KIT, name + '.py'))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod
