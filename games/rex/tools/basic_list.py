#!/usr/bin/env python3
"""LIST a Spectrum BASIC program block (the data of a Program block, no flag or checksum).

    python3 basic_list.py PROGRAM.bin [VARS_OFFSET]

Prints each line with its number, its stated length and the text; hidden 5-byte numbers are shown as {=value}
when they differ from the digits before them. A line whose stated length runs past the program is flagged.
"""
import sys

TOKENS = ('RND INKEY$ PI FN POINT SCREEN$ ATTR AT TAB VAL$ CODE VAL LEN SIN COS TAN ASN ACS ATN LN EXP INT SQR SGN '
          'ABS PEEK IN USR STR$ CHR$ NOT BIN OR AND <= >= <> LINE THEN TO STEP DEF_FN CAT FORMAT MOVE ERASE OPEN_# '
          'CLOSE_# MERGE VERIFY BEEP CIRCLE INK PAPER FLASH BRIGHT INVERSE OVER OUT LPRINT LLIST STOP READ DATA '
          'RESTORE NEW BORDER CONTINUE DIM REM FOR GO_TO GO_SUB INPUT LOAD LIST LET PAUSE NEXT POKE PRINT PLOT RUN '
          'SAVE RANDOMIZE IF CLS DRAW CLEAR RETURN COPY').split()


def number(b):
    if b[0] == 0:
        v = b[2] | b[3] << 8
        return v - 65536 if b[1] == 0xFF else v
    exp = b[0] - 128
    mant = ((b[1] | 0x80) << 24 | b[2] << 16 | b[3] << 8 | b[4]) / 2 ** 32
    return (-mant if b[1] & 0x80 else mant) * 2 ** exp


def listing(data, end=None):
    end = len(data) if end is None else end
    i = 0
    while i + 4 <= end:
        line, length = data[i] << 8 | data[i + 1], data[i + 2] | data[i + 3] << 8
        body = data[i + 4:i + 4 + length]
        note = '' if i + 4 + length <= end else f'  [length {length} runs past the program end by {i + 4 + length - end}]'
        out, j, digits = [], 0, ''
        while j < len(body):
            c = body[j]
            if c == 0x0E and j + 5 < len(body):
                v = number(body[j + 1:j + 6])
                try:
                    shown = float(digits) == v
                except ValueError:
                    shown = False
                if not shown:
                    out.append(f'{{={v:g}}}')
                j += 6
                digits = ''
                continue
            if c == 0x0D:
                break
            if c >= 0xA5:
                out.append(" " + TOKENS[c - 0xA5].replace("_", " ") + " ")
                digits = ''
            elif 32 <= c < 128:
                out.append(chr(c))
                digits = digits + chr(c) if chr(c) in '0123456789.' else ''
            else:
                out.append(f'{{{c:02X}}}')
            j += 1
        print(f'{line:5d} (length {length}) ' + ' '.join(''.join(out).split()) + note)
        i += 4 + length


if __name__ == '__main__':
    d = open(sys.argv[1], 'rb').read()
    listing(d, int(sys.argv[2]) if len(sys.argv) > 2 else None)
