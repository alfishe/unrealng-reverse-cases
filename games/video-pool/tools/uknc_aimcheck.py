#!/usr/bin/env python3
"""The UKNC port's integer AimShot (doc 14, 14.6.3) against the exact rounding of 16 P d / r.

    python3 tools/uknc_aimcheck.py [--dy-step 1] [--powers 2,4,...,126]

aim_int is the game's AimShot `$8A02` on the ROM calculator, in integers: checked against the ROM itself on every
input the game can give by tools/uknc_romcheck.py (7 761 096 inputs, 0 differences). This script compares it with
the exact rounding of 16 P d / r (aim_model): they differ only where the ROM rounds a near-half its own way (doc 14,
14.6.3), and every difference is checked to be one of those.

The defaults are dx -255..255, every dy -191..191 and the 63 even powers 2..126 (the power is always even; P 0 does
not move the ball): 12 329 856 inputs, about 20 s, a superset of the game's inputs (|dx| <= 245, |dy| <= 125). Prints
the number of inputs, the differences from the model by cause, and any difference with no cause (none expected).
"""
import argparse
import math

# The six inputs of the game where the ROM's own error (SQR as exp (0.5 ln x) with series, the divisions, the
# 32-bit mantissas) puts 16 P d / r on the other side of a rounding edge: (dx, dy, P): [vy, vx], read from the ROM
# by tools/uknc_romcheck.py. At (-225, +-51, 72) vx is -1123.5000146 (1.46 x 10^-5 above the half, under 2^-16): the
# rule below rounds it to -1123, the ROM gives -1124. At P 94 with |dx|, |dy| = 124, 29 or 29, 124 the positive
# component is 342.49999998: the ROM gives 343 (its value is the half or above), the exact rounding 342.
ROM_TABLE = {
    (-225, -51, 72): [0xFF01, 0xFB9C],
    (-225, 51, 72): [0x00FF, 0xFB9C],
    (-124, 29, 94): [0x0157, 0xFA48],
    (29, -124, 94): [0xFA48, 0x0157],
    (29, 124, 94): [0x05B8, 0x0157],
    (124, 29, 94): [0x0157, 0x05B8],
}


def near_half_negative(a, r2, q):
    """True when x = sqrt(a / r2) / 2 lies in [q - 0.5, q - 0.5 + 2^-16]: 2^14 rest <= (2q - 1) r2 + r2 / 2^16, with
    rest = a - (2q - 1)² r2 (never negative: x >= q - 0.5)"""
    rest = a - (2 * q - 1) ** 2 * r2
    return rest << 14 <= (2 * q - 1) * r2 + (r2 >> 16)


def aim_int(dx, dy, p):
    """[vy, vx] as 16-bit words as the ROM gives them, integers only. q = floor(x + 0.5) for x = 16 p |d| / r is the
    largest q with (2q - 1)² r² <= (32 p d)². A negative product gets 65536 added (ScaleByPowerCalc `$8A7A`): the
    ROM's addition lines it up with 65536's last mantissa bit, 2^-15, rounding to the nearest (SHIFT-FP `$2FDD`,
    ADD-BACK `$3004`), so x within 2^-16 above a half becomes the half, which FP-TO-BC rounds toward zero"""
    if (dx, dy, p) in ROM_TABLE:
        return list(ROM_TABLE[(dx, dy, p)])
    r2 = dx * dx + dy * dy
    out = []
    for d in (dy, dx):
        a = (32 * p * d) ** 2
        q = (math.isqrt(a // r2) + 1) // 2
        if d < 0 and q and near_half_negative(a, r2, q):
            q -= 1
        out.append((q if d >= 0 else -q) & 0xFFFF)
    return out


def aim_model(dx, dy, p):
    """The exact rounding floor(16 P d / r + 0.5); Model.shot uses aim_int"""
    r = math.sqrt(dx * dx + dy * dy)
    return [int(math.floor(16 * p * dy / r + 0.5)) & 0xFFFF, int(math.floor(16 * p * dx / r + 0.5)) & 0xFFFF]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--dy-step', type=int, default=1)
    ap.add_argument('--powers', default=','.join(str(p) for p in range(2, 127, 2)))
    a = ap.parse_args()
    powers = [int(v) for v in a.powers.split(',')]
    n, rule, table, bad = 0, 0, 0, []
    for dx in range(-255, 256):
        for dy in range(-191, 192, a.dy_step):
            if dx == 0 and dy == 0:
                continue
            r2 = dx * dx + dy * dy
            for p in powers:
                n += 1
                got, model = aim_int(dx, dy, p), aim_model(dx, dy, p)
                if got == model:
                    continue
                if (dx, dy, p) in ROM_TABLE:
                    table += 1
                    continue
                # every other difference must be the 2^-16 rule: a negative component one nearer zero
                ok = True
                for d, g, m in zip((dy, dx), got, model):
                    if g != m and not (d < 0 and g == (m + 1) & 0xFFFF
                                       and near_half_negative((32 * p * d) ** 2, r2, (-m) & 0xFFFF)):
                        ok = False
                if ok:
                    rule += 1
                else:
                    bad.append((dx, dy, p))
    print(f'{n} inputs, {rule + table + len(bad)} differences from the exact rounding: {rule} the ROM\'s 2^-15 addition, '
          f'{table} the ROM table, {len(bad)} unexplained')
    for x in bad[:20]:
        print('  dx %d dy %d P %d' % x, aim_int(*x), aim_model(*x))
    print('w1 break (212, 15, 76):', ['$%04X' % v for v in aim_int(212, 15, 76)], '(vy, vx)')


if __name__ == '__main__':
    main()
