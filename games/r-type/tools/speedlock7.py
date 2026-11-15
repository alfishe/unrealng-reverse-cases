#!/usr/bin/env python3
"""R-Type's SpeedLock 7 decryption chain, both ways (docs/03-build-and-load.md 3.1).

    python3 tools/speedlock7.py layers BASIC.bin             # run the chain on the tape's BASIC, list the layers
    python3 tools/speedlock7.py plain BASIC.bin OUT.bin      # the plain view of $EC00-$FEE7 (below)
    python3 tools/speedlock7.py trace PLAIN.bin OUT.json     # the chain's instructions as a simulator trace
    python3 tools/speedlock7.py tape PLAIN.bin OUT.bin       # the tape's bytes of $EC00-$FEE7 (the build's step)

BASIC.bin is the BASIC block's data without its flag and checksum (4933 bytes at PROG $5CCB). Its machine code
($5D06, the hidden USR of line 0) copies the 4840 bytes from PROG+$5C to $EC00-$FEE7 and returns into them
(PUSH DE / RET). There, 26 layers follow one another: each one is a short routine that first shifts the bytes
behind its own `LDDR` down by one (the code already run is garbled), then rewrites every byte from the end of its
own code up to $FEE7, and runs into the bytes it has just rewritten, the next layer. The last one runs into the
SpeedLock loader at $FB7E. A layer rewrites a byte in one of these ways (A is the key, made from `LD A,R` and a
register; c the byte before, p after):

    ADD A,(HL) [then CPL / SUB D / SUB n]   p = post(key + c)
    SUB (HL) then XOR IXl / DEC DE          p = post(key - c)
    XOR (HL) [then XOR D]                   p = key XOR c [XOR D]   (with XOR D, D is the byte the layer wrote
                                                                     just before, plus 1: CHAINED)
    DEC (HL) / INC (HL)                     p = c - 1 / c + 1    (no key)
    POP DE / LD A,R / XOR D / LD D,A / PUSH DE / DEC SP
                                            p = key XOR c, from $FEE7 down: the stack walks the bytes

The keys depend on the R register (set to $45 by the chain's first instructions, `LD R,A`), on constants and on
the loop counters, never on the bytes, except D in the chained XOR layers.

The plain view (the source the build assembles, src/loader/chain.asm) is every byte of $EC00-$FEE7 as it is after
the last layer that rewrites it: a layer's code as it runs, the loader as the last layer leaves it. The tape's
bytes are found from it by running the chain over the plain view in SkoolKit's simulator, every rewrite noted but
not kept (each byte keeps its plain value, which is what the code sees when it runs it), then undoing the noted
rewrites of each byte in reverse order. The control flow never depends on the bytes rewritten (the loops count
BC or DE). The method is Myth's tools/speedlock.py (the same SpeedLock 7 generation), with R-Type's addresses.
"""
import json
import sys

from skoolkit.simulator import Simulator
from skoolkit.traceutils import disassemble
from skoolkit.simutils import PC, SP, A, D, H, L, IXl

LO, HI = 0xEC00, 0xFEE8          # the chain as the BASIC copies it
PROG = 0x5CCB
COPY_FROM = PROG + 0x5C          # $5D27: the bytes copied to $EC00
LOADER = 0xFB7E                  # the SpeedLock loader, entered by the last layer
CHAINED = bytes((0xAE, 0xAA, 0x77, 0x57))   # XOR (HL) / XOR D / LD (HL),A / LD D,A
STACKED = bytes((0xD1, 0xED, 0x5F, 0xAA, 0x57, 0xD5))   # POP DE / LD A,R / XOR D / LD D,A / PUSH DE
READ_OPS = {0x86: 'add', 0x96: 'sub', 0xAE: 'xor', 0x35: 'dec', 0x34: 'inc'}


def post_ops(m, pc, regs):
    """the operations on A between a layer's read of (HL) and its `LD (HL),A`"""
    ops = []
    a = pc + 1
    while m[a] != 0x77:
        op = m[a]
        if op == 0x2F:
            ops.append(('cpl', 0))
        elif op == 0x92:
            ops.append(('sub', regs[D]))
        elif op == 0xAA:
            ops.append(('xor', regs[D]))
        elif op == 0xD6:
            ops.append(('sub', m[a + 1]))
        elif op == 0xEE:
            ops.append(('xor', m[a + 1]))
        elif op == 0xC6:
            ops.append(('sub', (-m[a + 1]) & 255))
        elif op == 0xDD and m[a + 1] == 0xAD:
            ops.append(('xor', regs[IXl]))
        elif op in (0x1B, 0x0B, 0x00):
            pass                                # DEC DE / DEC BC / NOP: A untouched
        else:
            raise SystemExit('speedlock7: an operation this tool does not know at $%04X: %s'
                             % (a, disassemble(m, a)[0]))
        a += disassemble(m, a)[1]
    return ops


def apply(op, c):
    kind, key, post = op[:3]
    if kind in ('dec', 'inc'):
        return (c + (1 if kind == 'inc' else -1)) & 255
    x = (key + c) & 255 if kind == 'add' else key ^ c if kind == 'xor' else (key - c) & 255
    for p, n in post:
        x = (~x) & 255 if p == 'cpl' else (x - n) & 255 if p == 'sub' else x ^ n
    return x


def undo(op, x):
    kind, key, post = op[:3]
    if kind in ('dec', 'inc'):
        return (x - (1 if kind == 'inc' else -1)) & 255
    for p, n in reversed(post):
        x = (~x) & 255 if p == 'cpl' else (x + n) & 255 if p == 'sub' else x ^ n
    return (x - key) & 255 if kind == 'add' else key ^ x if kind == 'xor' else (key - x) & 255


WRITERS = {0xC5, 0xD5, 0xE5, 0xF5, 0xCD, 0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC, 0xC7, 0xCF, 0xD7, 0xDF,
           0xE7, 0xEF, 0xF7, 0xFF, 0xE3, 0x22, 0x32, 0x02, 0x12, 0x36, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x77, 0x34,
           0x35, 0xDD, 0xFD, 0xED, 0xCB}


def run(chain, keep):
    """Run the chain over CHAIN (the bytes of $EC00-$FEE7). keep=True: the rewrites are kept (the real run, from the
    tape's bytes); keep=False: after each rewrite the byte gets its CHAIN value back (the run over the plain view,
    where a byte holds what the code sees when it runs it). Returns the events of each address (('op', rewrite) or
    ('write', value): a byte some other instruction wrote, a PUSH of the next layer's code), the layers [entry,
    kind, count, next] and the bytes at the loader's entry."""
    m = bytearray(0x10000)
    m[LO:HI] = chain
    shadow = bytearray(chain)
    sim = Simulator(m, {'SP': 0x5FF0, 'PC': LO})
    regs = sim.registers
    events = {}
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
            events.setdefault(hl, []).append(('op', (op, regs[A], post_ops(m, pc, regs) if op not in ('dec', 'inc') else [], pc,
                                                     m[pc:pc + 4] == CHAINED, m[hl])))
            pending = hl
        elif code == 0xAA and m[pc - 3:pc + 3] == STACKED and LO <= regs[SP] - 1 < HI:
            a = regs[SP] - 1                     # the D of the POP DE before: the byte at SP-1
            if not layers or layers[-1][0] != pc:
                layers.append([pc, 'pop', 0])
            layers[-1][2] += 1
            events.setdefault(a, []).append(('op', ('xor', regs[A], [], pc, False, regs[D])))
            pending = a
        sim.run()
        if code == 0xC2 and regs[PC] == pc + 3 and layers and not layers[-1][3:]:
            layers[-1].append(regs[PC])          # the loop is done: the next layer starts here
        if pending is not None and code in (0x77, 0x35, 0x34, 0xD5):
            if not keep:
                m[pending] = chain[pending - LO]
            shadow[pending - LO] = m[pending]
            pending = None
        elif code in WRITERS and m[LO:HI] != shadow:
            for i, (x, y) in enumerate(zip(m[LO:HI], shadow)):
                if x != y:
                    events.setdefault(LO + i, []).append(('write', x, pc))
            shadow[:] = m[LO:HI]
        steps += 1
        if steps > 20_000_000:
            raise SystemExit('speedlock7: the chain did not reach the loader at $%04X' % LOADER)
    run.starts = starts
    run.steps = steps
    return events, layers, bytes(m[LO:HI])


def plain(tape_chain):
    """the plain view from the tape's bytes: each byte as its last rewrite left it; and the tape bytes that no
    rewrite reaches through (written over by another instruction before the rewrites that count)"""
    events, layers, at_loader = run(tape_chain, keep=True)
    out = bytearray(tape_chain)
    lost = {}
    for a, evs in events.items():
        last_op = max((i for i, e in enumerate(evs) if e[0] == 'op'), default=None)
        if last_op is None:
            continue
        r = evs[last_op][1]
        out[a - LO] = apply(r, r[5])
        if any(e[0] == 'write' for e in evs[:last_op]):
            lost[a] = tape_chain[a - LO]
    return bytes(out), layers, lost


def master(plain_chain, lost):
    """the tape's bytes from the plain view and the lost bytes"""
    events, layers, _ = run(plain_chain, keep=False)
    out = bytearray(plain_chain)
    after = {}                               # (layer, address) -> the byte that layer wrote
    for a in sorted(events):
        evs = events[a]
        if not any(e[0] == 'op' for e in evs):
            continue
        while evs[-1][0] == 'write':         # written after its last rewrite: code already run, garbled
            evs = evs[:-1]
        x = plain_chain[a - LO]
        for kind, r, *_ in reversed(evs):
            if kind == 'write':
                assert x == r, 'speedlock7: $%04X: the rewrites go back to $%02X, the write there was $%02X' % (a, x, r)
                x = lost[a]
                break
            after[r[3], a] = x
            if r[4] and (r[3], a - 1) in after:
                r = (r[0], r[1], [('xor', (after[r[3], a - 1] + 1) & 255)], r[3], r[4])
            x = undo(r, x)
        out[a - LO] = x
    return bytes(out), layers


def chain_of(basic):
    return basic[COPY_FROM - PROG:COPY_FROM - PROG + HI - LO]


def lost_text(lost):
    return ''.join('$%04X %02X\n' % (a, v) for a, v in sorted(lost.items()))


def read_lost(path):
    lost = {}
    for line in open(path):
        line = line.split('#')[0].split()
        if line:
            lost[int(line[0].lstrip('$'), 16)] = int(line[1], 16)
    return lost


def main():
    a = sys.argv[1:]
    if a and a[0] == 'layers':
        _, layers, lost = plain(chain_of(open(a[1], 'rb').read()))
        for i, (pc, kind, n, *nxt) in enumerate(layers):
            print('%3d $%04X %-3s %5d bytes  next $%04X' % (i, pc, kind, n, nxt[0] if nxt else 0))
        print('%d rewrite loops, %d instructions, %d lost bytes' % (len(layers), run.steps, len(lost)))
    elif a and a[0] == 'plain':
        p, layers, lost = plain(chain_of(open(a[1], 'rb').read()))
        open(a[2], 'wb').write(p)
        if len(a) > 3:
            open(a[3], 'w').write(lost_text(lost))
        print('speedlock7: %d rewrite loops, plain view $%04X-$%04X written, %d lost bytes'
              % (len(layers), LO, HI - 1, len(lost)))
    elif a and a[0] == 'tape':
        t, layers = master(open(a[1], 'rb').read(), read_lost(a[3]) if len(a) > 3 else {})
        open(a[2], 'wb').write(t)
    elif a and a[0] == 'trace':
        p = open(a[1], 'rb').read()
        _, layers = master(p, read_lost(a[3]) if len(a) > 3 else {})
        starts = {('%04X' % k): v for k, v in sorted(run.starts.items()) if LO <= k < HI}
        json.dump({'starts': starts, 'entries': ['%04X' % LO] + ['%04X' % l[3] for l in layers if l[3:]],
                   'reads': {}}, open(a[2], 'w'), indent=0)
        print('speedlock7: %d instructions of the chain in %s' % (len(starts), a[2]))
    else:
        print(__doc__)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
