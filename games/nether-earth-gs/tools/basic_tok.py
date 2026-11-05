#!/usr/bin/env python3
"""48K BASIC programs as UTF-8 listings, both ways, without loss (the disk's "neart GS" and Hood's tape BASIC).

    python3 tools/basic_tok.py list PROGRAM.bin LENGTH OUT.txt      the first LENGTH bytes as a listing
    python3 tools/basic_tok.py tokenize IN.txt OUT.bin              the listing back to the program bytes

The listing: one program line a text line, "NUMBER BODY". In the body a keyword is written by its name followed by
one space, which the tokenizer takes as part of the keyword (a space the program itself holds after a keyword is
written as a second space). Keywords are matched only in upper case and outside strings, in REM text too (the TR-DOS command after
"REM :" in "neart GS" is tokens, as the keyboard enters them). Every number literal outside REM (digits, a point, an exponent: 25e3) gets its hidden form after it: $0E and the 5 bytes; all the literals of
these programs are integers 0-65535, whose form is 0, 0, the value low and high, 0 (the tokenizer refuses others).
A byte with no character of its own is written {XX}. The line's ending $0D is implied.
"""
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
BY_LENGTH = sorted(range(len(TOKENS)), key=lambda k: -len(TOKENS[k]))
NUMBER = re.compile(r'\d+(\.\d*)?([eE][+-]?\d+)?|\.\d+([eE][+-]?\d+)?')


def list_program(data, length):
    out, p = [], 0
    while p < length:
        num = data[p] << 8 | data[p + 1]
        n = data[p + 2] | data[p + 3] << 8
        body = data[p + 4:p + 4 + n]
        assert body[-1] == 0x0D, 'line %d does not end with $0D' % num
        text, i, after_token = [], 0, False
        while i < len(body) - 1:
            b = body[i]
            if b == 0x0E:
                i += 6
                continue
            if b >= FIRST:
                text.append(TOKENS[b - FIRST] + ' ')
                after_token = True
                i += 1
                continue
            ch = chr(b) if 32 <= b < 127 and b not in (ord('{'), ord('}')) else '{%02X}' % b
            if ch == ' ' and after_token:
                ch = '  '
            text.append(ch)
            after_token = False
            i += 1
        out.append('%d %s' % (num, ''.join(text)))
        p += 4 + n
    return '\n'.join(out) + '\n'


def number_form(literal):
    value = float(literal)
    if value != int(value) or not 0 <= value <= 65535:
        sys.exit('number %s: only integers 0-65535 are written here' % literal)
    v = int(value)
    return bytes([0x0E, 0, 0, v & 255, v >> 8, 0])


def tokenize_line(body):
    out, i, in_string, in_rem = bytearray(), 0, False, False
    while i < len(body):
        c = body[i]
        if c == '{' and re.match(r'\{[0-9A-F]{2}\}', body[i:i + 4]):
            out.append(int(body[i + 1:i + 3], 16))
            i += 4
            continue
        if c == '"':
            in_string = not in_string
            out.append(34)
            i += 1
            continue
        if not in_string:
            for k in BY_LENGTH:
                t = TOKENS[k]
                if body.startswith(t, i):
                    out.append(FIRST + k)
                    i += len(t)
                    if body[i:i + 1] == ' ':
                        i += 1
                    in_rem = in_rem or t == 'REM'
                    break
            else:
                prev = body[i - 1] if i else ' '
                m = NUMBER.match(body, i)
                if m and not in_rem and not (prev.isalpha() or prev == '$'):
                    out += m.group(0).encode('ascii') + number_form(m.group(0))
                    i = m.end()
                    continue
                out.append(ord(c))
                i += 1
            continue
        out.append(ord(c))
        i += 1
    return bytes(out) + b'\x0d'


def tokenize(text):
    out = bytearray()
    for line in text.split('\n'):
        if not line:
            continue
        num, _, body = line.partition(' ')
        body = tokenize_line(body)
        out += int(num).to_bytes(2, 'big') + len(body).to_bytes(2, 'little') + body
    return bytes(out)


def main():
    if sys.argv[1] == 'list':
        data = open(sys.argv[2], 'rb').read()
        open(sys.argv[4], 'w', encoding='utf-8').write(list_program(data, int(sys.argv[3])))
    elif sys.argv[1] == 'tokenize':
        open(sys.argv[3], 'wb').write(tokenize(open(sys.argv[2], encoding='utf-8').read()))
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
