"""capture_real_rom.py: re_session.py capture with the 'fasttape' trap off, so every ROM LD-BYTES call runs the real ROM.

Elite's last loader stage calls LD-BYTES ($0802) from a DI context and relies on SA/LD-RET's EI at $054F to switch the
interrupts back on before the Lenslok screen polls FLAGS / HALTs. unreal-ng's fast-tape trap skips that EI (IFF1 left as
it was, tapefastload.cpp), so with the trap on the Lenslok screen never sees a key. Same arguments as
`re_session.py capture`."""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elitelib as E  # noqa: E402,F401  (puts the kit and unreal-ng paths in place)
from kitlib import unreal_root  # noqa: E402

sys.path.insert(0, os.path.join(unreal_root(), 'tools', 'verification', 'analysis'))
import corpus  # noqa: E402
import re_session  # noqa: E402

_load = corpus.load


def load_without_trap(m, game, media, report, args):
    m.s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/feature/fasttape',
                            'body': {'enabled': False}}, ok=False)
    r = m.s.call('invoke_api', {'method': 'GET', 'path': '/api/v1/emulator/{id}/feature/fasttape'}, ok=False)
    report['fasttape'] = r.text[:200]
    return _load(m, game, media, report, args)


corpus.load = load_without_trap
if __name__ == '__main__':
    sys.argv[0] = 're_session.py'
    re_session.main()
