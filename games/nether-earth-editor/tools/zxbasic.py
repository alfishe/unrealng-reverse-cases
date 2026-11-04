#!/usr/bin/env python3
"""ZX Spectrum 48K BASIC: a program block to an editable listing and back, byte for byte.

    python3 zxbasic.py list PROG.bin OUT.bas      # detokenise (checks that `build` gives PROG.bin back)
    python3 zxbasic.py build [-I DIR ...] IN.bas OUT.bin   # tokenise

The 5-byte number forms come from the ROM's own DEC-TO-FP run in SkoolKit's simulator: run it with the SkoolKit venv's
python.

The listing format (one program line per text line):

    NUMBER TEXT
    # a comment line: ignored by `build` (blank lines too)

- A keyword token is written as its name with one "soft" space before it (none at the start of a line or right
  after another keyword) and one after it (none at the end of a line); `build` drops exactly those. Any other
  space is a byte of the program: `PRINT  a` stores a space after the PRINT token.
- A number literal (digits, `.`, an exponent) outside strings is followed in the program by $0E and its 5-byte
  form; `build` computes it (the small-integer form for 0..65535, the ROM's float otherwise). When the stored form
  is not the one the digits give, the listing says it: `0{=00 00 39 30 00}` (the digits show 0, the value is 12345).
- `{XX YY ...}` are bytes in hex: control codes (`{10 02}` = INK 2), UDGs, block graphics, the (c) sign `{7F}`,
  a keyword byte inside a string or a REM, and `{7B}` / `{7D}` for the braces themselves.
- `{<FILE}` (build only): the bytes of FILE, looked up in the `-I` folders: machine code in a REM, assembled
  from its own source.
- A line whose length word is not the line's real length: `NUMBER [len=FFFF] TEXT`.
"""
import functools
import sys

TOKENS = [
    'RND', 'INKEY$', 'PI', 'FN', 'POINT', 'SCREEN$', 'ATTR', 'AT', 'TAB', 'VAL$', 'CODE', 'VAL', 'LEN', 'SIN',
    'COS', 'TAN', 'ASN', 'ACS', 'ATN', 'LN', 'EXP', 'INT', 'SQR', 'SGN', 'ABS', 'PEEK', 'IN', 'USR', 'STR$', 'CHR$',
    'NOT', 'BIN', 'OR', 'AND', '<=', '>=', '<>', 'LINE', 'THEN', 'TO', 'STEP', 'DEF FN', 'CAT', 'FORMAT', 'MOVE',
    'ERASE', 'OPEN #', 'CLOSE #', 'MERGE', 'VERIFY', 'BEEP', 'CIRCLE', 'INK', 'PAPER', 'FLASH', 'BRIGHT', 'INVERSE',
    'OVER', 'OUT', 'LPRINT', 'LLIST', 'STOP', 'READ', 'DATA', 'RESTORE', 'NEW', 'BORDER', 'CONTINUE', 'DIM', 'REM',
    'FOR', 'GO TO', 'GO SUB', 'INPUT', 'LOAD', 'LIST', 'LET', 'PAUSE', 'NEXT', 'POKE', 'PRINT', 'PLOT', 'RUN',
    'SAVE', 'RANDOMIZE', 'IF', 'CLS', 'DRAW', 'CLEAR', 'RETURN', 'COPY']
assert len(TOKENS) == 0x100 - 0xA5
FIRST = 0xA5
T_REM, T_BIN = FIRST + TOKENS.index('REM'), FIRST + TOKENS.index('BIN')
BY_LENGTH = sorted(range(len(TOKENS)), key=lambda k: -len(TOKENS[k]))


_ROM = None


@functools.lru_cache(maxsize=None)
def float5(literal):
    """The 5 bytes the ROM's DEC-TO-FP ($2C9B) makes of a number literal's bytes (BIN and its digits included).

    Run in SkoolKit's Z80 simulator over the 48K ROM: the ROM's decimal arithmetic is not exact (".5" is
    $7F $7F $FF $FF $FF, not one half), and only running it gives the same bytes."""
    global _ROM
    import os
    from skoolkit.simulator import Simulator
    import skoolkit
    if _ROM is None:
        _ROM = open(os.path.join(os.path.dirname(skoolkit.__file__), 'resources', '48.rom'), 'rb').read()
    m = bytearray(65536)
    m[:16384] = _ROM
    t = bytes(literal) + b'\x0D'
    m[0x8000:0x8000 + len(t)] = t

    def word(a, v):
        m[a], m[a + 1] = v & 255, v >> 8
    word(0x5C5D, 0x8000)  # CH_ADD: the literal
    word(0x5C63, 0x9000)  # STKBOT
    word(0x5C65, 0x9000)  # STKEND: the calculator stack, empty
    word(0x5C68, 0x5C92)  # MEM: MEMBOT
    word(0xF000, 0xFFF0)  # the return address: where the run stops
    Simulator(m, {'SP': 0xF000, 'A': t[0], 'IY': 0x5C3A}).run(0x2C9B, 0xFFF0)
    if m[0x5C5D] | m[0x5C5E] << 8 != 0x8000 + len(literal):
        raise ValueError('not a number literal: %r' % literal)
    return bytes(m[0x9000:0x9005])


def hexes(bs):
    return '{' + ' '.join('%02X' % b for b in bs) + '}'


def is_num_start(prev, c):
    """A digit or point here starts a number literal (not a digit inside a variable name)."""
    return (c.isdigit() or c == '.') and not (prev.isalnum() or prev == '$')


def scan_number(s, i):
    """The end of the number literal that starts at s[i]."""
    j = i
    while j < len(s) and (s[j].isdigit() or s[j] == '.'):
        j += 1
    if j < len(s) and s[j] in 'eE':
        k = j + 1
        if k < len(s) and s[k] in '+-':
            k += 1
        if k < len(s) and s[k].isdigit():
            while k < len(s) and s[k].isdigit():
                k += 1
            j = k
    return j


# ---- detokenise -------------------------------------------------------------------------------------------------

def detok_line(body, escape_upper=False, escape_digits=False):
    """One line's bytes (without the $0D) to text."""
    out = []
    after_kw = True  # line start counts as "after a keyword": no soft space
    in_str = in_rem = False
    i = 0
    text_so_far = ''  # the literal characters since the last keyword, for the number rule

    def lit(s):
        nonlocal after_kw
        out.append(s)
        after_kw = False

    while i < len(body):
        b = body[i]
        if in_rem or in_str:
            if b == 0x22 and in_str:
                in_str = False
                lit('"')
            elif 0x20 <= b < 0x7F and b not in (0x7B, 0x7D):
                lit(chr(b))
            else:
                lit(hexes([b]))
            i += 1
            continue
        if b >= FIRST:
            if not after_kw:
                out.append(' ')
            out.append(TOKENS[b - FIRST] + ' ')
            after_kw = True
            if b == T_REM:
                in_rem = True
            i += 1
            text_so_far = ''
            continue
        if b == 0x0E:
            # a hidden number: is it the one the digits before it give?
            j = len(text_so_far)
            k = j
            while k > 0 and (text_so_far[k - 1].isdigit() or text_so_far[k - 1] in '.eE+-'):
                k -= 1
            num = body[i + 1:i + 6]
            out.append('{=' + ' '.join('%02X' % x for x in num) + '}')
            after_kw = False
            i += 6
            text_so_far += '\0'
            continue
        if b == 0x22:
            in_str = True
            lit('"')
            text_so_far += '"'
            i += 1
            continue
        if 0x20 <= b < 0x7F and b not in (0x7B, 0x7D):
            c = chr(b)
            if (escape_upper and c.isupper()) or (escape_digits and (c.isdigit() or c == '.')):
                lit(hexes([b]))
                text_so_far += '\0'
            else:
                lit(c)
                text_so_far += c
            i += 1
            continue
        if 0x10 <= b <= 0x15 and i + 1 < len(body):
            lit(hexes(body[i:i + 2]))
            i += 2
            continue
        lit(hexes([b]))
        text_so_far += '\0'
        i += 1
    s = ''.join(out)
    if s.endswith(' ') and after_kw:
        s = s[:-1]  # no soft space at the end of a line
    return s


def drop_derivable_numbers(s, inner):
    """Remove each `{=...}` that `build` would compute the same (the usual case): try, keep what still builds."""
    i = 0
    while True:
        i = s.find('{=', i)
        if i < 0:
            return s
        j = s.index('}', i) + 1
        try:
            same = tok_line(s[:i] + s[j:]) == inner
        except (ValueError, IndexError):
            same = False
        if same:
            s = s[:i] + s[j:]
        else:
            i = j


def split_lines(prog):
    i = 0
    while i < len(prog):
        num = prog[i] << 8 | prog[i + 1]
        ln = prog[i + 2] | prog[i + 3] << 8
        end = i + 4 + ln
        # a line ends at its $0D; the length word says where the next one starts
        body = prog[i + 4:end]
        yield num, ln, body
        i = end


def detok(prog):
    lines = []
    for num, ln, body in split_lines(prog):
        assert body and body[-1] == 0x0D, f'line {num}: no $0D at the end'
        inner = body[:-1]
        for mode in ((False, False), (True, False), (False, True), (True, True)):
            t = detok_line(inner, *mode)
            if tok_line(t) == inner:
                t = drop_derivable_numbers(t, inner)
                break
        else:
            t = hexes(inner)
        head = f'{num}'
        lines.append(f'{head} {t}' if t else head)
    return lines


# ---- tokenise ---------------------------------------------------------------------------------------------------

def tok_line(s):
    out = bytearray()
    i = 0
    after_kw = True
    in_str = in_rem = False
    while i < len(s):
        if s[i] == '{':
            j = s.index('}', i)
            inner = s[i + 1:j]
            if inner.startswith('='):
                out += b'\x0E' + bytes(int(x, 16) for x in inner[1:].split())
            elif inner.startswith('<'):
                out += include(inner[1:])
            else:
                out += bytes(int(x, 16) for x in inner.split())
            i = j + 1
            after_kw = False
            continue
        c = s[i]
        if in_rem:
            out.append(ord(c))
            i += 1
            continue
        if in_str:
            out.append(ord(c))
            if c == '"':
                in_str = False
            i += 1
            continue
        # a keyword: after a soft space (or at the start / after a keyword)
        start = i
        soft = False
        if not after_kw and c == ' ':
            start = i + 1
            soft = True
        if after_kw or soft:
            hit = None
            for k in BY_LENGTH:
                name = TOKENS[k]
                if s.startswith(name, start):
                    end = start + len(name)
                    if end == len(s) or s[end] == ' ':
                        hit = k
                        break
            if hit is not None:
                out.append(FIRST + hit)
                end = start + len(TOKENS[hit])
                i = end + 1 if end < len(s) else end
                after_kw = True
                if FIRST + hit == T_REM:
                    in_rem = True
                if FIRST + hit == T_BIN and not (s[i:i + 1] in ('0', '1') or s.startswith('{=', i)):
                    out += b'\x0E' + float5(bytes([T_BIN]))  # BIN without digits: 0 in 6 bytes, "0" in 7
                continue
        after_kw = False
        if c == '"':
            in_str = True
            out.append(0x22)
            i += 1
            continue
        prev = chr(out[-1]) if out and out[-1] < 0x80 else ' '
        if out and out[-1] >= FIRST:
            prev = ' '
        if is_num_start(prev, c):
            j = scan_number(s, i)
            lit = s[i:j]
            out += lit.encode('ascii')
            if s.startswith('{=', j):
                k = s.index('}', j)
                out += b'\x0E' + bytes(int(x, 16) for x in s[j + 2:k].split())
                i = k + 1
            else:
                binary = len(out) > len(lit) and out[-len(lit) - 1] == T_BIN
                out += b'\x0E' + float5((bytes([T_BIN]) if binary else b'') + lit.encode('ascii'))
                i = j
            continue
        out.append(ord(c))
        i += 1
    return bytes(out)


INCLUDE = ['.']


def include(name):
    """`{<FILE}`: the bytes of FILE (machine code in a REM, assembled apart), found in the -I folders"""
    import os
    for folder in INCLUDE:
        path = os.path.join(folder, name)
        if os.path.exists(path):
            return open(path, 'rb').read()
    raise SystemExit(f'{{<{name}}}: not found in ' + ', '.join(INCLUDE))


def build(text):
    prog = bytearray()
    for raw in text.splitlines():
        if not raw.strip() or raw.lstrip().startswith('#'):
            continue
        num_s, _, rest = raw.partition(' ')
        num = int(num_s)
        forced = None
        if rest.startswith('[len='):
            k = rest.index(']')
            forced = int(rest[5:k], 16)
            rest = rest[k + 2:] if rest[k + 1:k + 2] == ' ' else rest[k + 1:]
        body = tok_line(rest) + b'\x0D'
        ln = forced if forced is not None else len(body)
        prog += bytes([num >> 8, num & 255, ln & 255, ln >> 8]) + body
    return bytes(prog)


def main():
    cmd = sys.argv[1]
    if cmd == 'list':
        prog = open(sys.argv[2], 'rb').read()
        lines = detok(prog)
        text = '\n'.join(lines) + '\n'
        assert build(text) == prog, 'the listing does not build back'
        open(sys.argv[3], 'w').write(text)
    elif cmd == 'build':
        args = sys.argv[2:]
        while args[0] == '-I':
            INCLUDE.append(args[1])
            args = args[2:]
        open(args[1], 'wb').write(build(open(args[0]).read()))
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()
