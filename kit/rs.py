#!/usr/bin/env python3
"""Run unreal-ng's re_session.py (tools/verification/analysis/re_session.py) from the kit, so a case's commands name
one path in this repository instead of a variable set on one machine.

    python3 kit/rs.py [--unreal U] capture|open|build|stages|interrupts|call|export|check|stop ...

Everything after the optional --unreal goes to re_session.py unchanged (but for capture's --inputs scripts, read
first: a word that is no key fails here naming the line, and "W+O" chords, zx-reaper's form, go over as a copy in
W/inputs/ with the keys separated by spaces); its docstring (python3 kit/rs.py -h) is the reference. The cases'
`$RS` (docs/case-files.md) is this script. The checkout is found as kit/toolpaths.py finds it: --unreal,
$UNREAL_NG, the unreal-ng submodule, a checkout near this repository; `python3 kit/toolpaths.py re_session` prints
the script's path.

The name is not re_session.py because the kit's scripts and the cases' tools `import re_session` (unreal-ng's) with
the kit on their path. re_session.py is not copied into the kit: it imports corpus.py, mm_session.py and the MCP
client beside it, and it drives the unreal-qt build of that same checkout, so a copy would drift from the binary it
talks to.
"""
import os
import runpy
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import toolpaths  # noqa: E402
import kitlib  # noqa: E402

del sys.path[0]  # re_session.py and its modules are looked up beside it, not in the kit


def check_inputs(args):
    """capture --inputs: each script read first (kitlib.input_script), so a word that is no key stops here with the
    line and the reason, not in the emulator's "Unknown key"; a script with "+" chords ("W+O": zx-reaper's form,
    which mm_session.py does not take) is handed over as a copy with the chords split, in W/inputs/"""
    if not args or args[0] != 'capture' or '--inputs' not in args:
        return args
    work = args[args.index('--work') + 1] if '--work' in args[:-1] else '.'
    out, k = list(args), args.index('--inputs') + 1
    problems = []
    while k < len(out) and not out[k].startswith('--'):
        path = out[k]
        lines, bad = kitlib.input_script(path)
        problems += bad
        if not bad and any(len(w.split('+')) > 1 for _, _, text in lines for w in text.split()[1:]):
            os.makedirs(os.path.join(work, 'inputs'), exist_ok=True)
            out[k] = os.path.join(work, 'inputs', os.path.basename(path))
            kitlib.plain_input_script(path, out[k])
            print(f'rs.py: {path}: its "+" chords split into {out[k]}')
        k += 1
    if problems:
        sys.exit('\n'.join(problems))
    return out


def main():
    args = sys.argv[1:]
    hint = None
    if args[:1] == ['--unreal'] and len(args) > 1:
        hint, args = args[1], args[2:]
    elif args and args[0].startswith('--unreal='):
        hint, args = args[0].split('=', 1)[1], args[1:]
    script = toolpaths.re_session(hint)
    args = check_inputs(args)
    sys.argv = [script] + args
    sys.path.insert(0, os.path.dirname(script))
    runpy.run_path(script, run_name='__main__')


if __name__ == '__main__':
    main()
