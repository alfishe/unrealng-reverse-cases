#!/usr/bin/env python3
"""A boot's BASIC sectors as a text listing and back, byte for byte: a variant's basic.txt <-> basic.bin.

    python3 tools/res_basic.py list FILE.bin [OUT.txt]       # the sectors as a listing
    python3 tools/res_basic.py build FILE.txt OUT.bin        # the listing back to the bytes

tools/variants.py builds a variant's basic.txt with from_editable; tools/res_formats.py check proves every listing
gives its bytes back and the bytes the same listing.

The listing, one statement of the format a line:

- `# ...`: a comment.
- `NUMBER BODY`: a program line. In the body a keyword is written by its name followed by one space, which belongs
  to the keyword (a space the program itself holds after a keyword is a second space). Keywords are matched in upper
  case outside strings, in REM text too (the TR-DOS command after `REM :` is tokens, as the keyboard enters them).
  A number literal outside strings and REM is followed in the bytes by its hidden form ($0E and five bytes): it is
  implied when it is the literal's own value (an integer 0-65535, written 0, 0, low, high, 0) and written `{=N}`
  after the literal when the program holds another one (`RANDOMIZE USR 15616{=23926}`: the listing shows 15616, the
  machine calls 23926), or `{=XX XX XX XX XX}` for a form that is not a small integer. A literal with no hidden form
  at all is followed by `{=none}`. Any other byte without a character is `{XX}`; `{` and `}` themselves are `{7B}`
  and `{7D}`. The line's ending $0D is implied; a line whose length word is not its body's says so with `{len=N}` at
  the end.
- A REM that holds machine code: the line ends after `REM`, and the code follows as `  code XX XX ...` lines, one
  instruction a line, the disassembly after `;` (a comment: only the hex counts).
- `end`: the program's end mark $80; `autostart N`: TR-DOS's $AA and the line to start at (two bytes).
- `tail XX XX ...`: the bytes after that, up to the end of the sectors (lines of 32).
"""
import glob
import os
import re
import sys

TOKENS = [
    'RND', 'INKEY$', 'PI', 'FN', 'POINT', 'SCREEN$', 'ATTR', 'AT', 'TAB', 'VAL$', 'CODE', 'VAL', 'LEN', 'SIN',
    'COS', 'TAN', 'ASN', 'ACS', 'ATN', 'LN', 'EXP', 'INT', 'SQR', 'SGN', 'ABS', 'PEEK', 'IN', 'USR', 'STR$', 'CHR$',
    'NOT', 'BIN', 'OR', 'AND', '<=', '>=', '<>', 'LINE', 'THEN', 'TO', 'STEP', 'DEF FN', 'CAT', 'FORMAT', 'MOVE',
    'ERASE', 'OPEN #', 'CLOSE #', 'MERGE', 'VERIFY', 'BEEP', 'CIRCLE', 'INK', 'PAPER', 'FLASH', 'BRIGHT', 'INVERSE',
    'OVER', 'OUT', 'LPRINT', 'LLIST', 'STOP', 'READ', 'DATA', 'RESTORE', 'NEW', 'BORDER', 'CONTINUE', 'DIM', 'REM',
    'FOR', 'GO TO', 'GO SUB', 'INPUT', 'LOAD', 'LIST', 'LET', 'PAUSE', 'NEXT', 'POKE', 'PRINT', 'PLOT', 'RUN',
    'SAVE', 'RANDOMIZE', 'IF', 'CLS', 'DRAW', 'CLEAR', 'RETURN', 'COPY']
FIRST = 0xA5
REM = 0xEA
BY_LENGTH = sorted(range(len(TOKENS)), key=lambda k: -len(TOKENS[k]))
NUMBER = re.compile(rb'\d+(\.\d*)?([eE][+-]?\d+)?|\.\d+([eE][+-]?\d+)?')
PROG = 0x5D3B


def handles(name):
    return name.endswith('basic.bin')


# ----------------------------------------------------------------------------------------------- bytes -> text

def disassembler():
    """SkoolKit's disassembler (the case's venv) for the comments of the code lines, or None"""
    try:
        from skoolkit.disassembler import Disassembler  # noqa: F401
    except ImportError:
        here = os.path.dirname(os.path.abspath(__file__))
        sys.path.insert(0, os.path.join(here, '..', '..', '..', 'kit'))
        try:
            import toolpaths
            venv = toolpaths.skoolkit_venv('')
        except (SystemExit, Exception):  # noqa: BLE001
            return None
        for sp in glob.glob(os.path.join(venv, 'lib', 'python*', 'site-packages')):
            sys.path.append(sp)
        try:
            from skoolkit.disassembler import Disassembler  # noqa: F401
        except ImportError:
            return None
    from types import SimpleNamespace as NS
    from skoolkit.disassembler import Disassembler

    class Ins:
        def __init__(self, address, operation, bts):
            self.address, self.operation, self.bytes = address, operation, bts

    def dis(code, org):
        mem = bytearray(65536)
        mem[org:org + len(code)] = code
        d = Disassembler(mem, NS(asm_hex=True, asm_lower=False, defb_size=8, defm_size=65, defw_size=1,
                                 handle_rst=False, imaker=Ins, opcodes='', wrap=False))
        out, a, end = [], org, org + len(code)
        while a < end:
            ins = d.disassemble(a, a + 1, 'h')[0]
            n = min(len(ins.bytes), end - a)
            op = ins.operation if n == len(ins.bytes) else 'DEFB ' + ','.join('$%02X' % b for b in code[a - org:a - org + n])
            out.append((a, bytes(code[a - org:a - org + n]), op))
            a += n
        return out
    return dis


def is_code(rest):
    """a REM's text that is machine code: a byte that is neither a character, a token nor a space"""
    return any(b < 32 or 127 < b < FIRST or b == 0x7F for b in rest)


def number_form(text):
    """the hidden form BASIC stores after the literal: a small integer as 0, 0, low, high, 0"""
    try:
        v = float(text)
    except ValueError:
        return None
    if v == int(v) and 0 <= v <= 65535:
        v = int(v)
        return bytes([0, 0, v & 255, v >> 8, 0])
    return None


def body_text(body):
    """a line's body (without its $0D) as listing text, the REM code apart: (text, code bytes or b'', code offset)"""
    out, i, after_token, in_string, in_rem = [], 0, False, False, False
    while i < len(body):
        b = body[i]
        if in_rem and i == body.index(REM) + 1 and is_code(body[i:]):
            if b == 0x20 and len(body) > i + 1:   # REM, one space, then the code
                return ''.join(out) + '{20}', body[i + 1:], i + 1
            return finish(out), body[i:], i
        if not in_string and not in_rem and (48 <= b <= 57 or b == 0x2E):
            m = NUMBER.match(bytes(body[i:]))
            if m and m.end() > 0:
                lit = m.group().decode()
                j = i + m.end()
                out.append(lit)
                if j < len(body) and body[j] == 0x0E and j + 6 <= len(body):
                    form = bytes(body[j + 1:j + 6])
                    if form != number_form(lit):
                        if form[0] == 0 and form[1] == 0 and form[4] == 0:
                            out.append('{=%d}' % (form[2] | form[3] << 8))
                        else:
                            out.append('{=%s}' % form.hex(' ').upper())
                    i = j + 6
                else:
                    out.append('{=none}')
                    i = j
                after_token = False
                continue
        if b >= FIRST and in_string:   # a keyword byte inside a string: the text form would be letters
            out.append('{%02X}' % b)
            after_token = False
            i += 1
            continue
        if b >= FIRST:
            out.append(TOKENS[b - FIRST] + ' ')
            after_token = True
            if b == REM:
                in_rem = True
            i += 1
            continue
        if b == 0x22:
            in_string = not in_string
        if 32 <= b < 127 and b not in (0x7B, 0x7D):
            ch = chr(b)
            out.append('  ' if ch == ' ' and after_token else ch)
        else:
            out.append('{%02X}' % b)
        after_token = False
        i += 1
    return finish(out), b'', None


def finish(out):
    """the text of a line: a keyword's own space at the end dropped, a space byte at the end written {20}"""
    out = list(out)
    if out and out[-1].endswith(' ') and out[-1].strip() in TOKENS:
        out[-1] = out[-1][:-1]
    elif out and out[-1] in (' ', '  '):
        out[-1] = out[-1][:-1] + '{20}'
    return ''.join(out)


def to_text(data, org=PROG, fills=()):
    """fills: [(address, N, comment)] written as `  fill N` lines instead of code (bytes the build puts in)"""
    lines, p = [], 0
    dis = disassembler()
    while p + 4 <= len(data) and data[p] < 0x40:
        num = data[p] << 8 | data[p + 1]
        n = data[p + 2] | data[p + 3] << 8
        body = data[p + 4:p + 4 + n]
        ends = body[-1:] == b'\r'
        text, code, at = body_text(body[:-1] if ends else body)
        extra = '' if ends else '{len=%d,open}' % n
        lines.append('%d %s%s' % (num, text, extra) if text else '%d %s' % (num, extra) if extra else '%d' % num)
        if code:
            base = org + p + 4 + at
            segs, k = [], 0
            for fa, fn, fc in sorted(fills):
                if base <= fa < base + len(code):
                    segs.append((k, fa - base))
                    segs.append(('fill', fa, fn, fc))
                    k = fa - base + fn
            segs.append((k, len(code)))
            for seg in segs:
                if seg[0] == 'fill':
                    lines.append(('  fill %-14d ; $%04X %s' % (seg[2], seg[1], seg[3])).rstrip())
                    continue
                c, cb = code[seg[0]:seg[1]], base + seg[0]
                rows = dis(c, cb) if dis else [(cb + k, c[k:k + 1], '') for k in range(len(c))]
                for a, bts, op in rows:
                    lines.append(('  code %-14s ; $%04X %s' % (bts.hex(' ').upper(), a, op)).rstrip())
        p += 4 + n
    rest = data[p:]
    if rest[:1] == b'\x80':
        lines.append('end')
        rest = rest[1:]
        if rest[:1] == b'\xaa' and len(rest) >= 3:
            lines.append('autostart %d' % (rest[1] | rest[2] << 8))
            rest = rest[3:]
    for k in range(0, len(rest), 32):
        lines.append('tail ' + rest[k:k + 32].hex(' ').upper())
    return '\n'.join(lines) + '\n'


# ----------------------------------------------------------------------------------------------- text -> bytes

def tokenize(text):
    out, i, in_string, in_rem = bytearray(), 0, False, False
    length = None
    while i < len(text):
        if text[i] == '{':
            j = text.index('}', i)
            inner = text[i + 1:j]
            if inner.startswith('len='):
                length = inner[4:]
            else:
                out.append(int(inner, 16))
            i = j + 1
            continue
        c = text[i]
        if c == '"':
            in_string = not in_string
            out.append(0x22)
            i += 1
            continue
        if not in_string:
            if not in_rem and (c.isdigit() or c == '.'):
                m = NUMBER.match(text[i:].encode())
                if m and m.end():
                    lit = m.group().decode()
                    out += lit.encode()
                    i += m.end()
                    if text.startswith('{=', i):
                        j = text.index('}', i)
                        f = text[i + 2:j]
                        i = j + 1
                        if f == 'none':
                            continue
                        if ' ' in f:
                            form = bytes.fromhex(f)
                        else:
                            v = int(f)
                            form = bytes([0, 0, v & 255, v >> 8, 0])
                    else:
                        form = number_form(lit)
                        if form is None:
                            raise ValueError('res_basic: %s needs its hidden form written {=...}' % lit)
                    out += b'\x0e' + form
                    continue
            hit = next((k for k in BY_LENGTH if text.startswith(TOKENS[k], i)), None)
            if hit is not None:
                out.append(FIRST + hit)
                i += len(TOKENS[hit])
                if i < len(text) and text[i] == ' ':
                    i += 1
                if FIRST + hit == REM:
                    in_rem = True
                continue
        out.append(ord(c))
        i += 1
    return bytes(out), length


def from_text(text):
    out, cur = bytearray(), None

    def close():
        if cur is None:
            return
        num, body, length = cur
        if length is None:
            body = body + b'\r'
            n = len(body)
        else:
            n = int(length.split(',')[0])
        out.extend(bytes([num >> 8, num & 255, n & 255, n >> 8]) + body)

    for line in text.split('\n'):
        if not line.strip() or line.startswith('#'):
            continue
        if line.startswith('  code '):
            hexpart = line[7:].split(';')[0]
            cur = (cur[0], cur[1] + bytes.fromhex(hexpart), cur[2])
            continue
        if line.startswith('  fill '):   # N zero bytes the build fills in (e.g. a loader assembled and encrypted)
            cur = (cur[0], cur[1] + bytes(int(line[7:].split(';')[0])), cur[2])
            continue
        m = re.match(r'(\d+)(?: (.*))?$', line)
        if m and not line.startswith(('end', 'autostart', 'tail')):
            close()
            body, length = tokenize(m.group(2) or '')
            cur = (int(m.group(1)), body, length)
            continue
        close()
        cur = None
        if line == 'end':
            out.append(0x80)
        elif line.startswith('autostart '):
            v = int(line.split()[1])
            out += bytes([0xAA, v & 255, v >> 8])
        elif line.startswith('tail '):
            out += bytes.fromhex(line[5:])
        else:
            raise ValueError('res_basic: cannot read %r' % line)
    close()
    return bytes(out)


def fills_of(text):
    """the `  fill N ; $ADDR comment` lines of a listing: [(address, N, comment)]"""
    out = []
    for line in text.split('\n'):
        m = re.match(r'  fill (\d+) +; \$([0-9A-F]{4}) ?(.*)$', line)
        if m:
            out.append((int(m.group(2), 16), int(m.group(1)), m.group(3)))
    return out


def round_trip_text(text):
    """a listing reads to bytes and writes back the same (its fill lines kept where they were)"""
    return to_text(from_text(text), fills=fills_of(text)) == text


def to_editable(name, data):
    return '.txt', to_text(data).encode()


def from_editable(name, data):
    return from_text(data.decode())


def main():
    if sys.argv[1] == 'list':
        t = to_text(open(sys.argv[2], 'rb').read())
        if len(sys.argv) > 3:
            open(sys.argv[3], 'w').write(t)
        else:
            sys.stdout.write(t)
    elif sys.argv[1] == 'build':
        open(sys.argv[3], 'wb').write(from_text(open(sys.argv[2]).read()))
    return 0


if __name__ == '__main__':
    sys.exit(main())
