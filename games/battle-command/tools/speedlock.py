#!/usr/bin/env python3
"""The SpeedLock 7 decryption chain of Battle Command's BASIC, both ways (docs/03-build-and-load.md).

    python3 tools/speedlock.py layers TAPE_BASIC.bin           # run the chain on the tape's BASIC, list the layers
    python3 tools/speedlock.py plain TAPE_BASIC.bin OUT.bin    # the plain view of $AC38-$BF0C (below)
    python3 tools/speedlock.py trace PLAIN.bin OUT.json        # the chain's instructions as a simulator trace
    python3 tools/speedlock.py tape PLAIN.bin OUT.bin          # the tape's bytes of $AC38-$BF0C (the build's step)
    python3 tools/speedlock.py master PLAIN.bin BASIC_HEAD.bin OUT.bin
                                                               # the tape's BASIC from the plain view and the head

The BASIC's machine code ($5D06, line 0's USR) copies the 4821 bytes from PROG+$5F to $AC38-$BF0C and returns
into them. There, 104 layers follow one another: each one is a short routine that first shifts the 30 bytes
behind its own `LDDR` down by one (the code already run is garbled), then rewrites every byte from the end of its
own code up to $BF0C, and runs into the bytes it has just rewritten, the next layer. The last one rewrites the
SpeedLock loader at $B8F9. Each layer rewrites a byte in one of these ways (A the key, from `LD A,R` and a
register or two; c the byte before, p after):

    ADD A,(HL) then CPL / SUB D / SUB n     p = post(key + c)         (68 layers, `R XOR D` or R as the key)
    SUB (HL) then XOR IXl / DEC DE          p = post(key - c)         (12 layers, `R XOR IXh` or `R XOR E`)
    DEC (HL)                                p = c - 1                 (22 layers, no key)

The keys depend on the R register (set to 12 by the first layer, `LD R,A`), on constants and on the loop counters,
never on the bytes, so the transform of each byte is fixed by its address and the order of the layers.

The plain view (the source the build assembles, src/loader/chain.asm) is every byte of $AC38-$BF0C as it is after
the last layer that rewrites it: a layer's code as it runs, the loader as the last layer leaves it. The tape's bytes
are found from it by running the chain over the plain view in SkoolKit's simulator, every rewrite noted but not
kept (each byte stays its plain value, which is what the code sees when it runs it), and then undoing the noted
rewrites of each byte in reverse order. The control flow never depends on the bytes rewritten (the loops count
BC or DE) except a layer's own `JP NZ` operand, which it rewrites first and which is then plain.
"""
import os
import sys

from skoolkit.simulator import Simulator
from skoolkit.traceutils import disassemble
from skoolkit.simutils import PC, A, D, E, H, L, IXh, IXl

LO, HI = 0xAC38, 0xBF0D          # the chain and the loader
PROG = 0x5CCB
TAIL = PROG + 0x5F               # $5D2A: the bytes copied to $AC38
LOADER = 0xB8F9                  # the SpeedLock loader, entered by the last layer
READ_OPS = {0x86: 'add', 0x96: 'sub', 0x35: 'dec'}


def _post_ops(m, pc, regs):
    """the operations on A between a layer's read of (HL) and its `LD (HL),A`"""
    ops = []
    a = pc + 1
    while m[a] != 0x77:
        op = m[a]
        if op == 0x2F:
            ops.append(('cpl', 0))
        elif op == 0x92:
            ops.append(('sub', regs[D]))
        elif op == 0xD6:
            ops.append(('sub', m[a + 1]))
        elif op == 0xDD and m[a + 1] == 0xAD:
            ops.append(('xor', regs[IXl]))
        elif op == 0x1B:
            pass                                # DEC DE: the counter, A untouched
        else:
            raise SystemExit('speedlock: an operation the chain tool does not know at $%04X: %s'
                             % (a, disassemble(m, a)[0]))
        a += disassemble(m, a)[1]
    return ops


def _apply(op, c):
    kind, key, post = op
    if kind == 'dec':
        return (c - 1) & 255
    x = (key + c) & 255 if kind == 'add' else (key - c) & 255
    for p, n in post:
        x = (~x) & 255 if p == 'cpl' else (x - n) & 255 if p == 'sub' else x ^ n
    return x


def _undo(op, x):
    kind, key, post = op
    if kind == 'dec':
        return (x + 1) & 255
    for p, n in reversed(post):
        x = (~x) & 255 if p == 'cpl' else (x + n) & 255 if p == 'sub' else x ^ n
    return (x - key) & 255 if kind == 'add' else (key - x) & 255


def run(chain, keep):
    """Run the chain over CHAIN (the bytes of $AC38-$BF0C). keep=True: the rewrites are kept (the real run, from the
    tape's bytes). keep=False: each byte keeps its value (the run over the plain view). Returns the per-address list
    of rewrites, the layers [(entry, kind, count)] and the bytes at the loader's entry."""
    m = bytearray(0x10000)
    m[LO:HI] = chain
    sim = Simulator(m, {'SP': 0x7FFE, 'PC': LO})
    regs = sim.registers
    ops = {}
    layers = []
    steps = 0
    pending = None
    starts = {}
    while regs[PC] != LOADER:
        pc = regs[PC]
        code = m[pc]
        if pc not in starts:
            starts[pc] = disassemble(m, pc)[1]
        op = READ_OPS.get(code)
        hl = regs[H] * 256 + regs[L]
        if op and LO <= hl < HI and LO <= pc < LOADER:
            if not layers or layers[-1][0] != pc:
                layers.append([pc, op, 0])
            layers[-1][2] += 1
            ops.setdefault(hl, []).append((op, regs[A], _post_ops(m, pc, regs) if op != 'dec' else []))
            pending = (hl, m[hl])
        sim.run()
        if code == 0xC2 and regs[PC] == pc + 3 and layers and not layers[-1][3:]:
            layers[-1].append(regs[PC])          # the loop is done: the next layer starts here
        if pending and code in (0x77, 0x35):
            if not keep:
                m[pending[0]] = pending[1]
            pending = None
        steps += 1
        if steps > 20_000_000:
            raise SystemExit('speedlock: the chain did not reach the loader at $%04X' % LOADER)
    run.starts = starts
    return ops, layers, bytes(m[LO:HI])


def plain(tape_chain):
    """the plain view from the tape's bytes: each byte after its last rewrite"""
    ops, layers, at_loader = run(tape_chain, keep=True)
    out = bytearray(tape_chain)
    for a, recs in ops.items():
        x = tape_chain[a - LO]
        for r in recs:
            x = _apply(r, x)
        out[a - LO] = x
    return bytes(out), layers


def master(plain_chain):
    """the tape's bytes from the plain view"""
    ops, layers, _ = run(plain_chain, keep=False)
    out = bytearray(plain_chain)
    for a, recs in ops.items():
        x = plain_chain[a - LO]
        for r in reversed(recs):
            x = _undo(r, x)
        out[a - LO] = x
    return bytes(out), layers


def main():
    a = sys.argv[1:]
    if a and a[0] == 'layers':
        basic = open(a[1], 'rb').read()
        _, layers = plain(basic[TAIL - PROG:TAIL - PROG + HI - LO])
        for i, (pc, kind, n) in enumerate(layers):
            print('%3d $%04X %-3s %5d bytes' % (i, pc, kind, n))
    elif a and a[0] == 'plain':
        basic = open(a[1], 'rb').read()
        p, layers = plain(basic[TAIL - PROG:TAIL - PROG + HI - LO])
        open(a[2], 'wb').write(p)
        print('speedlock: %d layers, plain view $%04X-$%04X written' % (len(layers), LO, HI - 1))
    elif a and a[0] == 'tape':
        t, layers = master(open(a[1], 'rb').read())
        open(a[2], 'wb').write(t)
    elif a and a[0] == 'master':
        p = open(a[1], 'rb').read()
        head = open(a[2], 'rb').read()
        t, layers = master(p)
        open(a[3], 'wb').write(head[:TAIL - PROG] + t + head[TAIL - PROG + len(t):])
    elif a and a[0] == 'trace':
        p = open(a[1], 'rb').read()
        _, layers = master(p)
        starts = {('%04X' % k): v for k, v in sorted(run.starts.items()) if LO <= k < HI}
        import json
        json.dump({'starts': starts, 'entries': ['%04X' % LO] + ['%04X' % l[3] for l in layers if l[3:]],
                   'reads': {}}, open(a[2], 'w'), indent=0)
        print('speedlock: %d instructions of the chain in %s' % (len(starts), a[2]))
    else:
        print(__doc__)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
