"""A model of the 128K's two AY players, step for step as the code does it (docs/09-sound.md 9.6-9.8).

  TunePlayer   TuneStart $B6EC and TuneTick $B767: TuneChannelStep $B79F with its pitch and volume envelopes, the
               stream reader TuneNextEvent $B88F with the one-read-a-tick rule, the calls $75 / $76, TuneEnd.
  SfxPlayer    StartSoundEffect $C1D3 and SoundEffectsTick $BF7E: SfxSlotStep, SfxReadStream, SfxToAyChannel with the
               rotating channel bits.

Both run on a copy of the game image (fig_docb.image()) and return, tick by tick, the AY register writes in the
order the code makes them: a list of (register, value). check_tune() compares the model with the writes of a c128
trace (work/docs/fillS/menu-ay.json, made by work/docs/fillS/aywrites.py).

    python3 tools/aymodel.py check     # the model against the c128 trace of the menu
    python3 tools/aymodel.py stats     # the tune's length, deferrals, calls
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fig_docb as B  # noqa: E402

TUNE_STREAMS = (0xBA01, 0xBB7E, 0xBD06)
TUNE_RECORDS = (0xBE7D, 0xBECD, 0xBF1D)
NOTE_PERIODS_TUNE = 0xC71B
NOTE_PERIODS = 0xC6EB
TUNE_VOLUME = 0xB6E0
SFX_SLOTS = 0xC5EB


class TunePlayer:
    def __init__(self, mem=None):
        self.m = bytearray(mem or B.image())
        self.out = []
        self.log = []            # per tick, per channel: what happened ('read', 'deferred', 'count')
        self.calls = [0, 0, 0]
        self.start()

    def ay(self, reg, val):
        self.out.append((reg, val & 0xFF))

    def silence(self):
        self.mixer = 0xB8
        self.ay(7, 0xB8)
        for r in (8, 9, 10):
            self.ay(r, 0)

    def start(self):
        m = self.m
        self.stopped = 0xFF
        self.ptr = list(TUNE_STREAMS)
        for rec in TUNE_RECORDS:
            m[rec + 3] = m[TUNE_VOLUME]
            for k in (9, 0x0C, 0x0D, 0, 1):
                m[rec + k] = 0
            m[rec + 2] = 1
            m[rec + 4] = m[rec + 5] = 5
        v = m[TUNE_VOLUME]
        m[TUNE_RECORDS[1] + 8] = v
        m[TUNE_RECORDS[0] + 8] = m[TUNE_RECORDS[2] + 8] = v + 1
        self.silence()
        for rec in TUNE_RECORDS:
            m[rec + 2] = 1
        self.stopped = 0
        self.read_flag = 0

    def tick(self):
        """one TuneTick: returns the AY writes it made"""
        self.out = []
        self.read_flag = 0
        what = []
        if self.stopped:
            return self.out
        for ch in range(3):
            self.ch = ch
            self.ended = False
            what.append(self.channel_step(TUNE_RECORDS[ch]))
            if self.ended == 'tick':
                break
        self.log.append(what)
        return self.out

    def channel_step(self, rec):
        m = self.m
        if m[rec + 0x0D]:
            m[rec + 0x0D] = 0
            r = self.next_event(rec)
            if self.ended:
                self.ended = None if self.ended == 'call' else self.ended
                return r
            self.envelopes(rec)
            return 'deferred-' + r
        m[rec + 2] = (m[rec + 2] - 1) & 0xFF
        if m[rec + 2] == 0:
            r = self.next_event(rec)
            if self.ended == 'call':
                self.ended = 'tick'
            return r
        self.envelopes(rec)
        return 'count'

    def envelopes(self, rec):
        m = self.m
        m[rec + 0x1B] = (m[rec + 0x1B] - 1) & 0xFF
        if m[rec + 0x1B] == 0:
            m[rec + 0x19] = (m[rec + 0x19] + m[rec + 0x1D]) & 0xFF
            m[rec + 0x1C] = (m[rec + 0x1C] - 1) & 0xFF
            if m[rec + 0x1C] == 0:
                a = (m[rec + 0x1A] + 3) & 0xFF
                m[rec + 0x1A] = a
                if a == m[rec + 0x1F]:
                    a = m[rec + 0x1A] = 0
                d = (a + 0x20) & 0xFF
                m[rec + 0x1C] = m[rec + d]
                m[rec + 0x1D] = m[rec + d + 1]
                m[rec + 0x1E] = m[rec + d + 2]
            m[rec + 0x1B] = m[rec + 0x1E]
            hl = m[rec] | m[rec + 1] << 8
            if hl:
                hl = (hl + B.s8(m[rec + 0x19])) & 0xFFFF
            self.ay(m[rec + 6] + 1, hl >> 8)
            self.ay(m[rec + 6], hl & 0xFF)
        m[rec + 0x36] = (m[rec + 0x36] - 1) & 0xFF
        if m[rec + 0x36]:
            return
        a = (m[rec + 3] + m[rec + 0x38]) & 0xFF
        if a & 0x80:
            a = 0
        m[rec + 3] = a
        if m[rec + 8] < m[rec + 3]:
            m[rec + 3] = m[rec + 8]
        m[rec + 0x37] = (m[rec + 0x37] - 1) & 0xFF
        if m[rec + 0x37] == 0:
            a = (m[rec + 0x35] + 3) & 0xFF
            m[rec + 0x35] = a
            if a == m[rec + 0x3A]:
                m[rec + 0x38] = 0
                m[rec + 0x37] = 0xFF
                m[rec + 0x39] = 0xFF
            else:
                d = (a + 0x3B) & 0xFF
                m[rec + 0x37] = m[rec + d]
                m[rec + 0x38] = m[rec + d + 1]
                m[rec + 0x39] = m[rec + d + 2]
        m[rec + 0x36] = m[rec + 0x39]
        self.ay(m[rec + 7], m[rec + 3])

    def next_event(self, rec):
        m = self.m
        if self.read_flag:
            m[rec + 0x0D] = self.read_flag
            return 'wait'
        self.read_flag = 0xFF
        p = self.ptr[self.ch]
        while True:
            a = m[p]
            if a < 0x64:
                if a >= 0x32:
                    m[rec + 0x0A] = m[p + 1]
                    p += 1
                    a -= 0x32
                if a:
                    a = (a + m[rec + 9]) & 0xFF
                q = NOTE_PERIODS_TUNE + ((a << 1) & 0xFF)
                m[rec] = m[q]
                m[rec + 1] = m[q + 1]
                m[rec + 2] = m[rec + 0x0A]
                m[rec + 3] = 0
                p += 1
                m[rec + 5] = 1
                m[rec + 0x19] = 0
                m[rec + 0x1B] = 1
                m[rec + 0x1C] = 1
                m[rec + 0x1A] = 0xFD
                m[rec + 0x1D] = 0
                m[rec + 0x37] = m[rec + 0x3B]
                m[rec + 0x38] = m[rec + 0x3C]
                m[rec + 0x39] = m[rec + 0x3D]
                m[rec + 0x36] = m[rec + 0x3D]
                m[rec + 0x35] = 0
                self.ptr[self.ch] = p
                return 'read'
            if a == 0x64:
                self.mixer ^= m[rec + 0x0B]
                self.ay(7, self.mixer)
                p += 1
            elif a == 0x79:
                self.ay(6, m[p + 1])
                p += 2
            elif a < 0x75:
                m[rec + 8] = a - 0x65
                p += 1
            elif a == 0x75:
                ret = p + 3
                d = 0x0E + 2 * m[rec + 0x0C]
                m[rec + d] = ret & 0xFF
                m[rec + d + 1] = ret >> 8
                m[rec + 0x0C] += 1
                self.calls[self.ch] += 1
                p = B.word(m, p + 1)
            elif a == 0x76:
                m[rec + 0x0C] -= 1
                p = B.word(m, rec + 0x0E + 2 * m[rec + 0x0C])
            elif a == 0x77:
                m[rec + 9] = m[p + 1]
                p += 2
            elif a == 0x78:
                p = B.word(m, p + 1)
            elif a == 0xFF:
                self.stopped = 0xFF
                self.silence()
                self.ended = 'call'          # TuneEnd: POP AF, RET
                self.ptr[self.ch] = p
                return 'end'
            elif a in (0x89, 0x8A):
                n = m[p + 1]
                base = 0x1F if a == 0x89 else 0x3A
                for k in range(n + 1):
                    m[rec + base + k] = m[p + 1 + k]
                p += n + 2
            else:
                self.ptr[self.ch] = p
                return 'bad'


def run_tune(max_ticks=8000):
    t = TunePlayer()
    ticks = []
    first = list(t.out)
    while not t.stopped and len(ticks) < max_ticks:
        ticks.append(t.tick())
    return t, first, ticks


class SfxPlayer:
    """the 16 effect slots; start(slot, stream) is StartSoundEffect, tick() is SoundEffectsTick"""

    def __init__(self, mem=None):
        self.m = bytearray(mem or B.image())
        self.noise = 0
        self.channels = []       # per tick: [(slot, channel letter or None)]

    def start(self, slot, stream):
        m, ix = self.m, SFX_SLOTS + 16 * slot
        m[ix] = 0xFF
        m[ix + 1] = stream & 0xFF
        m[ix + 2] = stream >> 8
        m[ix + 3] = 1
        m[ix + 4] = m[ix + 5] = 15
        m[ix + 8] = 1
        m[ix + 9] = m[ix + 10] = 0
        m[ix + 0x0B] = 0x38
        m[ix + 0x0C] = 1
        m[ix] = 0

    def tick(self):
        m = self.m
        out, used = [], []
        index, mixer, bits = 0, 0xBF, 0xF6
        for slot in range(16):
            ix = SFX_SLOTS + 16 * slot
            if m[ix] == 0xFF:
                continue
            m[ix + 3] = (m[ix + 3] - 1) & 0xFF
            freed = False
            if m[ix + 3] == 0:
                freed = self.read(ix)
            if not freed:
                m[ix + 6] = (m[ix + 6] - 1) & 0xFF
                if m[ix + 6] == 0:
                    m[ix + 6] = m[ix + 7]
                    if m[ix + 4]:
                        m[ix + 4] = (m[ix + 4] - m[ix + 8]) & 0xFF
                period, vol = m[ix + 9] | m[ix + 10] << 8, m[ix + 4]
                if index < 3:
                    mixer &= bits | m[ix + 0x0B]
                    out += [(8 + index, vol), (2 * index, period & 0xFF), (2 * index + 1, period >> 8)]
                    used.append((slot, 'ABC'[index], f'{bits:02X}'))
                else:
                    used.append((slot, None, f'{bits:02X}'))
                index += 1
            else:
                used.append((slot, 'freed', f'{bits:02X}'))
            bits = ((bits << 1) | (bits >> 7)) & 0xFF
        out += [(6, self.noise), (7, mixer)]
        self.channels.append(used)
        return out

    def read(self, ix):
        m = self.m
        p = m[ix + 1] | m[ix + 2] << 8
        while True:
            a = m[p]
            if a == 0xFF:
                m[ix] = 0xFF
                return True
            if a == 0xFE:
                m[ix + 5] = m[p + 1]
                p += 2
                continue
            if a == 0xFD:
                m[ix + 7] = m[p + 1]
                m[ix + 6] = (m[p + 1] >> 1) + 1
                m[ix + 8] = m[p + 2]
                p += 3
                continue
            if a == 0xFC:
                m[ix + 0x0B] = m[p + 1]
                p += 2
                continue
            if a == 0xFB:
                p += 1
                a = m[p]
                self.noise = a
            if a >= 0x60:
                a -= 0x60
                p += 1
                m[ix + 0x0C] = m[p]
            p += 1
            m[ix + 1] = p & 0xFF
            m[ix + 2] = p >> 8
            q = NOTE_PERIODS + 2 * a
            m[ix + 9] = m[q]
            m[ix + 10] = m[q + 1]
            m[ix + 3] = m[ix + 0x0C]
            m[ix + 4] = m[ix + 5]
            return False


def check_tune(path=None):
    """the model's writes against the trace's, tick by tick (the trace's ticks are cut at each TuneTick entry)"""
    path = path or os.path.join(B.WORK, 'docs', 'fillS', 'menu-ay.json')
    d = json.load(open(path))
    ft = d['frame_t']
    at = lambda f, t: f * ft + t  # noqa: E731
    starts = [at(e[0], e[1]) for e in d['entries']['B767']]
    ts = at(d['entries']['B6EC'][0][0], d['entries']['B6EC'][0][1])
    writes = [(at(f, t), r, v) for f, t, r, v in d['writes'] if at(f, t) >= ts]
    t, first, ticks = run_tune(len(starts))
    groups = [[(r, v) for w, r, v in writes if w < starts[0]]]
    for k, s in enumerate(starts):
        e = starts[k + 1] if k + 1 < len(starts) else 1 << 62
        groups.append([(r, v) for w, r, v in writes if s <= w < e])
    model = [first] + ticks[:len(starts)]
    bad = [k for k, (a, b) in enumerate(zip(groups, model)) if a != b]
    n = sum(len(g) for g in groups)
    print(f'{len(starts)} ticks, {n} writes in the trace; ticks that differ: {len(bad)}', bad[:5])
    if bad:
        k = bad[0]
        print('trace', groups[k])
        print('model', model[k])
    return not bad


def check_sfx(path=None, seed=None):
    """the effects model against a c128 play trace: the slots seeded from memory_at at the trace's first frame, each
    StartSoundEffect $C1D3 of the trace (A the slot, BC the stream) applied in its order, a model tick at each
    SoundEffectsTick $BF7E; the AY writes compared tick by tick"""
    path = path or os.path.join(B.WORK, 'docs', 'fillS', 'play-ay.json')
    seed = seed or os.path.join(B.WORK, 'docs', 'fillS', 'play-slots-20000.json')
    d, sd = json.load(open(path)), json.load(open(seed))
    ft = d['frame_t']
    at = lambda f, t: f * ft + t  # noqa: E731
    p = SfxPlayer()
    raw = bytes.fromhex(sd['C5E7'])
    p.m[0xC5E7:0xC5E7 + len(raw)] = raw
    p.noise = raw[1]
    ev = [(at(e[0], e[1]), 'tick', None) for e in d['entries']['BF7E']]
    ev += [(at(e[0], e[1]), 'start', (e[2] >> 8, e[3])) for e in d['entries']['C1D3']]
    ev.sort()
    ticks = [e[0] for e in ev if e[1] == 'tick']
    writes = [(at(f, t), r, v) for f, t, r, v in d['writes']]
    bad, n, log = [], 0, []
    for k, s in enumerate(ticks):
        e = ticks[k + 1] if k + 1 < len(ticks) else 1 << 62
        got = [(r, v) for w, r, v in writes if s <= w < e]
        n += len(got)
        for when, kind, arg in ev:
            if kind == 'start' and (ticks[k - 1] if k else -1) < when < s:
                p.start(*arg)
                log.append((k, 'start', arg[0], f'{arg[1]:04X}'))
        want = p.tick()
        if got != want:
            bad.append(k)
    print(f'{len(ticks)} effect ticks, {n} writes in the trace; ticks that differ: {len(bad)}', bad[:5])
    return p, log, bad


def stats():
    t, first, ticks = run_tune()
    deferred = sum(1 for w in t.log for x in w if x.startswith('deferred'))
    waits = sum(1 for w in t.log for x in w if x.endswith('wait'))
    print(f'{len(ticks)} ticks to TuneEnd; {sum(len(x) for x in ticks)} AY writes; calls {t.calls}; '
          f'deferred reads {deferred}, of them re-deferred {waits}')


if __name__ == '__main__':
    {'check': check_tune, 'sfx': check_sfx, 'stats': stats}[sys.argv[1] if len(sys.argv) > 1 else 'check']()
