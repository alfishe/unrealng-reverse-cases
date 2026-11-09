#!/usr/bin/env python3
"""The UKNC port's integer AimShot (doc 14, 14.6.3) against the physics model's (tools/physics_model.py, Model.shot).

    python3 tools/uknc_aimcheck.py [--dy-step 1] [--powers 2,4,...,126]

The defaults are every input the game can give (doc 14, 14.6.3): dx -255..255, every dy -191..191 and the 63 even
powers 2..126 (the power is always even; P 0 does not move the ball): 12 329 856 inputs, about 30 s. Prints the number
of inputs tried and every difference (none expected). The model rounds 16 P d / r as FP-TO-BC
does; whether the ROM's SQR agrees with it at every near-tie is a separate check (doc 14, 14.7).
"""
import argparse
import math


def aim_int(dx, dy, p):
    """[vy, vx] as 16-bit words, integers only: q = floor(x + 0.5) is the largest q with (2q - 1)² r² <= (32 p d)²"""
    r2 = dx * dx + dy * dy
    out = []
    for d in (dy, dx):
        a = (32 * p * d) ** 2
        q = (math.isqrt(a // r2) + 1) // 2
        if d < 0 and q and (2 * q - 1) ** 2 * r2 == a:
            q -= 1          # a tie: the ROM adds 65536 to a negative product and rounds up, toward zero
        out.append((q if d >= 0 else -q) & 0xFFFF)
    return out


def aim_model(dx, dy, p):
    """Model.shot's formula"""
    r = math.sqrt(dx * dx + dy * dy)
    return [int(math.floor(16 * p * dy / r + 0.5)) & 0xFFFF, int(math.floor(16 * p * dx / r + 0.5)) & 0xFFFF]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--dy-step', type=int, default=1)
    ap.add_argument('--powers', default=','.join(str(p) for p in range(2, 127, 2)))
    a = ap.parse_args()
    powers = [int(v) for v in a.powers.split(',')]
    n, bad = 0, []
    for dx in range(-255, 256):
        for dy in range(-191, 192, a.dy_step):
            if dx == 0 and dy == 0:
                continue
            for p in powers:
                n += 1
                if aim_int(dx, dy, p) != aim_model(dx, dy, p):
                    bad.append((dx, dy, p))
    print(f'{n} inputs, {len(bad)} differences')
    for x in bad[:20]:
        print('  dx %d dy %d P %d' % x, aim_int(*x), aim_model(*x))
    print('w1 break (212, 15, 76):', ['$%04X' % v for v in aim_int(212, 15, 76)], '(vy, vx)')


if __name__ == '__main__':
    main()
