"""Shared helpers of the zgsA figure scripts (docs 01-06): the instance of a work folder (gs_session.py or
re_session.py's session.json), TTD memory reads at a frame, the screen and the RAM pages as the recording had them."""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
KIT = os.path.normpath(os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, KIT)
import kitlib as K  # noqa: E402

IMG = os.path.join(CASE, 'docs', 'img')


def session(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'mcp'))
    import mcplib  # noqa: E402
    state = json.load(open(os.path.join(work, 'session.json')))
    s = mcplib.Session(f"http://127.0.0.1:{state['port_base'] + 200}/mcp", state['model'])
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    return s


def read(s, frame, lo, n, tinframe=None, space='cpu'):
    """n bytes from lo at the end of a frame (or at frame:tinframe), in a TTD memory space"""
    out = bytearray()
    for a in range(lo, lo + n, 0x4000):
        args = {'action': 'memory_at', 'space': space, 'frame': frame, 'offset': a,
                'length': min(0x4000, lo + n - a)}
        if tinframe is not None:
            args['tinframe'] = tinframe
        r = s.call('time_travel', args, ok=False)
        if not r.structured or 'hex' not in r.structured:
            raise RuntimeError(f'memory_at {frame}:{tinframe} {space} ${a:04X}: {r.text}')
        out += bytes.fromhex(r.structured['hex'])
    return bytes(out)


def screen(s, frame, tinframe=None):
    return read(s, frame, 0x4000, 6912, tinframe)


def out(topic, name):
    d = os.path.join(IMG, topic)
    os.makedirs(d, exist_ok=True)
    return os.path.join(d, name)


def cached(work, frame, lo=0x4000, n=6912, tinframe=None, space='cpu'):
    """read() through a cache in WORK/mem (the recording does not change): one file a frame and range"""
    d = os.path.join(work, 'mem')
    os.makedirs(d, exist_ok=True)
    name = f'{space}-{frame}' + (f'_{tinframe}' if tinframe is not None else '') + f'-{lo:04X}-{n}.bin'
    path = os.path.join(d, name)
    if not os.path.exists(path):
        data = read(session(work), frame, lo, n, tinframe, space)
        open(path, 'wb').write(data)
    return open(path, 'rb').read()


def render(scr, scale=1, flash_off=True):
    """a 6912-byte screen as a PIL image (kit/zxscreen.py's colours, flash in its off phase)"""
    from PIL import Image
    image = Image.new('RGB', (256, 192))
    px = image.load()
    for y in range(192):
        row = ((y & 0xC0) << 5) | ((y & 0x07) << 8) | ((y & 0x38) << 2)
        for col in range(32):
            bits = scr[row + col]
            attr = scr[0x1800 + (y >> 3) * 32 + col]
            lvl = 0xFF if attr & 0x40 else 0xCD

            def c(i):
                return (lvl if i & 2 else 0, lvl if i & 4 else 0, lvl if i & 1 else 0)
            ink, paper = c(attr & 7), c((attr >> 3) & 7)
            for b in range(8):
                px[col * 8 + b, y] = ink if bits & (0x80 >> b) else paper
    return image.resize((256 * scale, 192 * scale), Image.NEAREST) if scale != 1 else image
