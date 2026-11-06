#!/usr/bin/env python3
"""Shared by the tools/fig_*.py scripts: the case's recordings and real frames of them.

A frame is the picture unreal-ng shows at the end of a recorded frame: the script launches its own unreal-qt
(offscreen, muted, on --port-base, default 16530; MCP +200), loads the recording (time_travel load), seeks to the
frame (time_travel seek) and takes the WebAPI screen capture (GET .../capture/screen?format=png&area=full: 352 x 288,
the border included). Nothing is drawn by hand: a figure is these pictures, scaled by whole numbers with nearest
neighbour, side by side.

    with Recordings(port_base) as rec:
        image = rec.frame('r99', 3830)            # PIL RGB, 352 x 288

The unreal-ng checkout is $UNREAL_NG (default: the stage 1 worktree named in work/stage2/BRIEF.md).
"""
import base64
import io
import json
import os
import re
import sys
import time
import urllib.request

from PIL import Image, ImageDraw, ImageFont
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import toolpaths  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CASES = os.path.dirname(ROOT)
UNREAL = toolpaths.unreal_ng(required=False) or 'unreal-ng'
BINARY = os.path.join(UNREAL, 'cmake-build-agent-release', 'bin', 'unreal-qt.app', 'Contents', 'MacOS', 'unreal-qt')
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
import mcplib  # noqa: E402

# name: (session.ttd, model, what it is)
RECORDINGS = {
    'r98': ('work/stage1/r98/session.ttd', 'PENTAGON', "'98, Pentagon 128 + TR-DOS, power-on to play"),
    'r99': ('work/stage1/r99/session.ttd', 'PENTAGON',
            "'99, Pentagon 128 + TR-DOS, autostart, every start-up menu page, LOAD MAP, play"),
    'r99-48': ('work/stage1/r99-48/session.ttd', 'PENTAGON', "'99, Pentagon 48 BASIC (paging locked), the 48 K path"),
    's98': ('work/stage2/scorpion/s98/session.ttd', 'SCORPION', "'98, Scorpion ZS-256 + TR-DOS"),
    's99': ('work/stage2/scorpion/s99/session.ttd', 'SCORPION', "'99, Scorpion ZS-256 + TR-DOS"),
    'e99s': ('work/stage2/scorpion/e99s/session.ttd', 'SCORPION', "'99, Scorpion ZS-256, START with no map loaded"),
    'x98': ('work/stage2/texts/x98/session.ttd', 'PENTAGON',
            "'98, Pentagon 128 + TR-DOS, power-on, the game menu's 5 LOAD NEW LEVEL, then 0 START"),
    'x99': ('work/stage2/texts/x99/session.ttd', 'PENTAGON',
            "'99, Pentagon 128 + TR-DOS, autostart, REDEFINE, LOAD MAP NELEV_06 (the highlight moved by A / Q), START, abort"),
    'ne-load': (os.path.join(CASES, 'nether-earth', 'work', 'load', 'session.ttd'), '48K',
                'Nether Earth (case nether-earth), 48K, the tape load'),
    'ne-play': (os.path.join(CASES, 'nether-earth', 'work', 'play', 'session.ttd'), '48K',
                'Nether Earth (case nether-earth), 48K, play'),
}


def ttd_path(name):
    path = RECORDINGS[name][0]
    return path if os.path.isabs(path) else os.path.join(ROOT, path)


class Recordings:
    """One unreal-qt of our own; each recording is loaded on first use (a fresh machine of its model)"""

    def __init__(self, port_base=16530):
        self.port_base = port_base
        self.process = None
        self.loaded = None
        self.session = None
        self.emulator = None

    def __enter__(self):
        self.process = mcplib.launch(BINARY, self.port_base)
        self.session = mcplib.Session(f'http://127.0.0.1:{self.port_base + 200}/mcp', 'PENTAGON')
        return self

    def __exit__(self, *exc):
        if self.process:
            self.process.terminate()
            try:
                self.process.wait(10)
            except Exception:  # noqa: BLE001
                self.process.kill()

    def load(self, name):
        if self.loaded == name:
            return
        _path, model, _what = RECORDINGS[name]
        s = self.session
        s.fresh_machine(model, ram_power_on='zero')
        s.call('control_execution', {'action': 'take_control'}, ok=False)
        s.call('control_execution', {'action': 'pause'}, ok=False)
        s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                              'body': {'muted': True}}, ok=False)
        r = s.call('time_travel', {'action': 'load', 'path': ttd_path(name)}, ok=False)
        if r.is_error and 'recorded kempston' in (r.text or ''):
            # the recording was made with a Kempston card (re_session's capture plugs one): fit it, then load again
            s.call('emulator_manage', {'action': 'slots_plug', 'slot': 'edge.1', 'card': 'kempston'}, ok=False)
            for _ in range(100):
                if 'slots_plug slot=edge.1' not in s.call('joystick_input', {'action': 'status'}, ok=False).text:
                    break
                time.sleep(0.1)
            s.call('control_execution', {'action': 'pause'}, ok=False)
            s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                                  'body': {'muted': True}}, ok=False)
            r = s.call('time_travel', {'action': 'load', 'path': ttd_path(name)}, ok=False)
        if r.is_error:
            raise SystemExit(f'{name}: {r.text}')
        m = re.search(r'frames (\d+)\.\.(\d+)', r.text or '')
        self.frames = (int(m.group(1)), int(m.group(2))) if m else None
        listing = json.load(urllib.request.urlopen(f'http://127.0.0.1:{self.port_base}/api/v1/emulator'))
        self.emulator = listing['emulators'][0]['id']
        self.loaded = name

    def frame(self, name, frame):
        """The picture at the end of recorded frame FRAME (352 x 288, border included)"""
        self.load(name)
        r = self.session.call('time_travel', {'action': 'seek', 'frame': int(frame)}, ok=False)
        if r.is_error or 'Reached frame' not in (r.text or ''):
            raise SystemExit(f'{name} frame {frame}: {r.text}')
        url = (f'http://127.0.0.1:{self.port_base}/api/v1/emulator/{self.emulator}/capture/screen'
               '?format=png&area=full')
        for _ in range(3):
            try:
                answer = json.load(urllib.request.urlopen(url))
                return Image.open(io.BytesIO(base64.b64decode(answer['data']))).convert('RGB')
            except Exception:  # noqa: BLE001
                time.sleep(0.2)
        raise SystemExit(f'{name} frame {frame}: no screen capture')


def scaled(image, scale=2):
    return image.resize((image.width * scale, image.height * scale), resample=Image.NEAREST)


def font(size=14):
    for path in ('/System/Library/Fonts/Supplemental/Arial.ttf', '/System/Library/Fonts/Helvetica.ttc',
                 '/Library/Fonts/Arial.ttf'):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def titled_row(images, titles, gap=12, title_height=28, background=(255, 255, 255)):
    """Pictures side by side, a short title over each (no overlay on the pictures)"""
    width = sum(i.width for i in images) + gap * (len(images) - 1)
    height = max(i.height for i in images) + title_height
    sheet = Image.new('RGB', (width, height), background)
    draw = ImageDraw.Draw(sheet)
    f = font(16)
    x = 0
    for image, title in zip(images, titles):
        sheet.paste(image, (x, title_height))
        w = draw.textlength(title, font=f)
        draw.text((x + (image.width - w) / 2, 5), title, fill=(0, 0, 0), font=f)
        x += image.width + gap
    return sheet


def with_counter(image, text, height=22):
    """The picture with a strip under it holding TEXT (a frame counter): never drawn over the picture"""
    out = Image.new('RGB', (image.width, image.height + height), (255, 255, 255))
    out.paste(image, (0, 0))
    ImageDraw.Draw(out).text((6, image.height + 3), text, fill=(0, 0, 0), font=font(14))
    return out


def save_gif(path, pictures, durations):
    """An animated GIF, every picture with its own palette (the Spectrum's 15 colours fit), looping"""
    frames = [p.convert('P', palette=Image.ADAPTIVE, colors=32) for p in pictures]
    frames[0].save(path, save_all=True, append_images=frames[1:], duration=durations, loop=0, optimize=True,
                   disposal=1)
