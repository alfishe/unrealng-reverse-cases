#!/usr/bin/env python3
"""D.G. Cooke's turbo loader run in SkoolKit's simulator: the tape's own code decodes and encodes TZX block 2, and the
decryption chain runs from the loaded block to the game's entry (tools/mktape.py, tools/cipher.py, tools/parts.py).

The loader (src/tape/basic.ann, src/loader/stage2.ann) reads a pulse pair at a time in its edge waits `$B70E` and
`$B714` and finds the pilot in `$B693`; these three are traps here. In decode mode a trap hands out the next pair of
the block (a 1 bit: the edge comes 21 counts after the last one, a 0 bit: 7, so the threshold `$CB` in `$B6D4`
tells them apart); in encode mode it asks which bit the loader expects there: a data bit of the byte being loaded
(`$B6D4` writes each byte as 8 bits MSB first and an invert flag, then pads the zeros to 5 more pairs), a padding
zero, a run of the script engine's ones, or a filler the caller always gets. Everything else is the loader's own
code, so a source that changes the loader changes the tape the same way.

Run it with a Python that has SkoolKit: the module re-runs a tool with the venv kit/toolpaths.py finds.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
KIT = os.path.join(CASE, '..', '..', 'kit')


def need_skoolkit():
    """Find SkoolKit: this Python's own, else the venv kit/toolpaths.py finds, through its site-packages when its
    Python is this one's version (the caller keeps its own modules, Pillow for one), else by re-running the tool
    under the venv's Python."""
    try:
        import skoolkit  # noqa: F401
        return
    except ImportError:
        pass
    if os.environ.get('DEFLEKTOR_REEXEC'):
        sys.exit('tapesim: no SkoolKit (kit/toolpaths.py venv)')
    venv = subprocess.run([sys.executable, os.path.join(KIT, 'toolpaths.py'), 'venv'],
                          capture_output=True, text=True).stdout.strip()
    if not venv:
        sys.exit('tapesim: no SkoolKit venv (kit/toolpaths.py venv)')
    site = os.path.join(venv, 'lib', 'python%d.%d' % sys.version_info[:2], 'site-packages')
    if os.path.isdir(os.path.join(site, 'skoolkit')):
        sys.path.append(site)
        return
    os.environ['DEFLEKTOR_REEXEC'] = '1'
    os.execv(os.path.join(venv, 'bin', 'python'), [os.path.join(venv, 'bin', 'python')] + sys.argv)


need_skoolkit()
import skoolkit  # noqa: E402
from skoolkit.simulator import Simulator  # noqa: E402

ROM = open(os.path.join(os.path.dirname(skoolkit.__file__), 'resources', '48.rom'), 'rb').read()
PROG = 0x5CCB             # the BASIC's address; its code at $5D05 is the USR target
CODE = 0x5D05
C0 = 0xBF                 # the EAR / border byte the pilot search leaves in C
LOAD_ENTRY = 0xB727       # LoadBlock: IX = the address, DE = the length
GET_BYTE = 0xB6D4         # ReadByte
EDGE_WAITS = (0xB70E, 0xB714)
PILOT = 0xB693
LAST_LDIR = 0x5B00        # LDIR; RET: the end of the load (the return goes to $5C00)
DATA_RET, CHECK_RET = 0xB734, 0xB74A   # ReadByte's callers: a data byte, the checksum

# The bits the loader's callers always get (ret of the edge wait, ret of its caller): 0 for LoadBlock's lead pair,
# ReadByte's padding and the script's pause, 1 for the end markers the script engine waits on.
FILL = {(0xB70D, 0xB72C): 0, (0xB70D, 0xB6F4): 0, (0xB7F6, 0xB742): 1, (0xB70D, 0xB808): 0,
        (0xB8A5, 0xB774): 1, (0xB8C7, 0xB774): 1}
# The tape's loads in order: (address, length)
LOADS = [(0xB75A, 0x10F), (0xB869, 0x74), (0xB8DD, 0x302), (0xB326, 0x1D8), (0x998E, 0x1998),
         (0xC000, 0x4000), (0x5C00, 0x4000), (0x9C00, 0x1F0)]


def bits_of(data, last):
    """The bits of a TZX turbo block's data, MSB first; the last byte has `last` bits."""
    out = []
    for i, b in enumerate(data):
        n = 8 if i < len(data) - 1 else last
        out.extend((b >> (7 - k)) & 1 for k in range(n))
    return out


def pack_bits(bits):
    """Bits to bytes, MSB first, and the number of bits used in the last byte."""
    out = bytearray()
    for i in range(0, len(bits), 8):
        chunk = bits[i:i + 8]
        out.append(sum(b << (7 - k) for k, b in enumerate(chunk)))
    last = len(bits) % 8 or 8
    return bytes(out), last


def byte_bits(v):
    """ReadByte's form of a byte: 8 bits and the invert flag (the form with fewer ones), and the padding zeros."""
    zeros = 8 - bin(v).count('1')
    if zeros >= 4:
        b = [(v >> (7 - i)) & 1 for i in range(8)] + [0]
    else:
        b = [((~v) >> (7 - i)) & 1 for i in range(8)] + [1]
    return b, b.count(0) - 5


def _machine(basic):
    mem = bytearray(ROM) + bytearray(0x10000 - len(ROM))
    mem[PROG:PROG + len(basic)] = basic
    sim = Simulator(mem, {'PC': CODE, 'BC': CODE, 'SP': 0xFF00})
    return mem, sim


def decode(basic, bits, stop=LAST_LDIR):
    """Run the loader over the block's bits: the memory and simulator at `stop`, and the loads [(addr, bytes)]."""
    mem, sim = _machine(basic)
    r, ops = sim.registers, sim.opcodes
    edge = 0
    loads = []
    while r[24] != stop:
        pc = r[24]
        if pc == LOAD_ENTRY:
            loads.append([r[8] << 8 | r[9], bytearray()])
        elif pc == 0xB737:
            loads[-1][1].append(r[7])
        if pc == PILOT or pc in EDGE_WAITS:
            sp = r[12]
            ret = mem[sp] | mem[sp + 1] << 8
            if pc == PILOT:
                r[3] = C0
            else:
                k = edge // 2
                if k >= len(bits):
                    raise SystemExit('tapesim: the tape ran out at pair %d' % k)
                r[2] = (r[2] + (21 if bits[k] else 7)) & 0xFF
                r[3] ^= 0xFF
                r[0] = r[3]
                edge += 1
            r[1] = 0x01
            r[12] = sp + 2
            r[24] = ret
            continue
        ops[mem[pc]]()
    return mem, sim, [(a, bytes(b)) for a, b in loads], edge // 2


def encode(basic, loads, stop=LAST_LDIR):
    """The bits of the turbo block that make the loader load `loads` [(addr, bytes)] in order."""
    mem, sim = _machine(basic)
    r, ops = sim.registers, sim.opcodes
    out = []
    edge = 0
    queue, pad = [], []
    cur = None
    li = -1
    bit = 0
    while r[24] != stop:
        pc = r[24]
        if pc == LOAD_ENTRY:
            li += 1
            addr, data = loads[li]
            ix, de = r[8] << 8 | r[9], r[4] << 8 | r[5]
            if (ix, de) != (addr, len(data)):
                raise SystemExit('tapesim: load %d is $%04X+%d, the source gives $%04X+%d' % (li, ix, de, addr, len(data)))
            cur = (addr, data)
        if pc == GET_BYTE:
            sp = r[12]
            ret = mem[sp] | mem[sp + 1] << 8
            if ret == DATA_RET:
                ix = r[8] << 8 | r[9]
                v = cur[1][ix - cur[0]]
            elif ret == CHECK_RET:
                v = r[6]
            else:
                raise SystemExit('tapesim: ReadByte called from $%04X' % ret)
            queue, npad = byte_bits(v)
            pad = [0] * npad
        if pc == PILOT or pc in EDGE_WAITS:
            sp = r[12]
            ret = mem[sp] | mem[sp + 1] << 8
            if pc == PILOT:
                r[3] = C0
            else:
                if edge % 2 == 0:
                    key = (ret, mem[sp + 2] | mem[sp + 3] << 8)
                    if key == (0xB70D, 0xB6DD):
                        bit = queue.pop(0)
                    elif key == (0xB70D, 0xB6F4):
                        bit = pad.pop(0)
                    elif key == (0xB70D, 0xB702):
                        bit = 0 if r[7] & 0x80 else 1
                    else:
                        bit = FILL[key]
                    out.append(bit)
                r[2] = (r[2] + (21 if bit else 7)) & 0xFF
                r[3] ^= 0xFF
                r[0] = r[3]
                edge += 1
            r[1] = 0x01
            r[12] = sp + 2
            r[24] = ret
            continue
        ops[mem[pc]]()
    if li != len(loads) - 1:
        raise SystemExit('tapesim: the loader took %d loads of %d' % (li + 1, len(loads)))
    return out


def run_to(mem, sim, stop):
    """Go on from a decoded tape (decode()) to `stop` (the chain's end `$FD00`, the game's entry `$8382`)."""
    r, ops = sim.registers, sim.opcodes
    n = 0
    while r[24] != stop:
        ops[mem[r[24]]]()
        n += 1
        if n > 5000000:
            raise SystemExit('tapesim: $%04X not reached (PC $%04X)' % (stop, r[24]))
    return mem
