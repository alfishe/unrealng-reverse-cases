#!/usr/bin/env python3
"""Run unreal-ng's re_session.py (tools/verification/analysis/re_session.py) from the kit, so a case's commands name
one path in this repository instead of a variable set on one machine.

    python3 kit/rs.py [--unreal U] capture|open|build|stages|interrupts|call|export|check|stop ...
    python3 kit/rs.py capture ... [--stop] [--expect STATE[@FRAME] ...] [--expect-ranges LO-HI[,LO-HI ...]]

Everything after the optional --unreal goes to re_session.py unchanged, but for these, read here first (capture):

  --inputs    each script is read first (kitlib.capture_inputs): a word that is no key fails here naming the line,
              and "W+O" chords, zx-reaper's form, go over as a copy in W/inputs/ with the keys separated by spaces
  --stop      the instance the capture launched is stopped once it is done (re_session.py stop --work W): a batch of
              captures on one port base works without a stop after each; without it the instance stays up, as
              re_session.py leaves it, for build / call / export on the live recording
  --expect    the replay check: STATE is the live run's saved state (an SZX snapshot, or a 64 K / 48 K dump: kitlib.
              memory_image) at FRAME frames into the capture's input scripts (counted from the first script's frame
              0 on, the scripts one after another as re_session.py plays them); without @FRAME, at the scripts' end.
              The capture's memory there is compared with it over --expect-ranges (hex, inclusive; default
              4000-FFFF): "identical", or how many bytes differ, in which ranges, and the first few. A bot that saves
              the state at an event (a level's end) and writes its keys as a script from its previous save gives
              both: a replay that does not reach that state (a frame off, the random seed) is told apart from a
              witness. Repeat for several frames. The results go to W/replay-check.json; any difference makes rs.py
              exit with status 3 once the capture's own files are written (and after --stop)

re_session.py's docstring (python3 kit/rs.py -h) is the reference for the rest. The cases' `$RS` (docs/case-files.md)
is this script. The checkout is found as kit/toolpaths.py finds it: --unreal, $UNREAL_NG, the unreal-ng submodule, a
checkout near this repository; `python3 kit/toolpaths.py re_session` prints the script's path.

A case's own capture wrapper that imports re_session and replaces corpus.load (Deflektor's tools/rs_capture.py)
calls `rs.main(['capture', ...])` after its patch and gets the same checks and options.

The name is not re_session.py because the kit's scripts and the cases' tools `import re_session` (unreal-ng's) with
the kit on their path. re_session.py is not copied into the kit: it imports corpus.py, mm_session.py and the MCP
client beside it, and it drives the unreal-qt build of that same checkout, so a copy would drift from the binary it
talks to.
"""
import json
import os
import runpy
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import toolpaths  # noqa: E402
import kitlib  # noqa: E402

del sys.path[0]  # re_session.py and its modules are looked up beside it, not in the kit


def check_inputs(args):
    """capture --inputs read first (kitlib.capture_inputs, kept here under its older name)"""
    return kitlib.capture_inputs(args)


def kit_options(args):
    """(re_session.py's arguments, stop, [(state path, frame or None)], [(lo, hi exclusive)]): the kit's own capture
    options taken out"""
    out, stop, expect, ranges = [], False, [], '4000-FFFF'
    k = 0
    while k < len(args):
        a = args[k]
        if a == '--stop':
            stop = True
        elif a in ('--expect', '--expect-ranges') or a.startswith(('--expect=', '--expect-ranges=')):
            if '=' in a:
                a, value = a.split('=', 1)
            else:
                if k + 1 >= len(args):
                    sys.exit(f'rs.py: {a} needs a value')
                k += 1
                value = args[k]
            if a == '--expect':
                path, _, frame = value.partition('@')
                if not os.path.isfile(path):
                    sys.exit(f'rs.py: --expect {value}: no file {path}')
                if frame and not frame.isdigit():
                    sys.exit(f'rs.py: --expect {value}: the frame after @ is a count of frames')
                expect.append((path, int(frame) if frame else None))
            else:
                ranges = value
        else:
            out.append(a)
        k += 1
    spans = []
    for part in ranges.split(','):
        lo, _, hi = part.partition('-')
        spans.append((int(lo, 16), int(hi or lo, 16) + 1))
    return out, stop, expect, spans


def compare(expected, got, spans):
    """{"differ": N, "ranges": ["$LO-$HI" ...], "first": ["$ADDR live XX replay YY" ...]} over spans"""
    diff = [a for lo, hi in spans for a in range(lo, hi) if expected[a] != got[a]]
    runs = []
    for a in diff:
        if runs and a <= runs[-1][1] + 8:
            runs[-1][1] = a
        else:
            runs.append([a, a])
    return {'differ': len(diff), 'ranges': ['$%04X-$%04X' % (lo, hi) for lo, hi in runs[:12]],
            'first': ['$%04X live %02X replay %02X' % (a, expected[a], got[a]) for a in diff[:6]]}


def capture(args, script):
    """re_session.py's capture, imported rather than run as a script, so that the replay check can stop the scripts
    at a frame; the instance stopped afterwards when asked. Returns the exit status"""
    args, stop, expect, spans = kit_options(args)
    work = args[args.index('--work') + 1] if '--work' in args[:-1] else None
    if (stop or expect) and not work:
        sys.exit('rs.py: --stop / --expect need capture --work W')
    sys.path.insert(0, os.path.dirname(script))
    import corpus
    import re_session
    results = []
    pending = sorted((f, p) for p, f in expect if f is not None)
    at_end = [p for p, f in expect if f is None]
    playing, total = [False], [0]

    def check(m, path, frame):
        r = dict(compare(kitlib.memory_image(path), m.read(0, 0x10000), spans), state=path, frame=frame,
                 compared=['$%04X-$%04X' % (lo, hi - 1) for lo, hi in spans])
        results.append(r)
        what = 'identical' if not r['differ'] else \
            f"{r['differ']} bytes differ ({', '.join(r['ranges'])}; first {', '.join(r['first'][:3])})"
        print(f'replay check: {path} at frame {frame}: {what}', flush=True)

    run_frames = corpus.run_frames
    play_script = re_session.play_script

    def run_frames_checked(m, frames, screens, at, on_screen=None):
        # only while the scripts play (not a tape's load before them): stop at each expected frame on the way
        while playing[0] and pending and at < pending[0][0] <= at + frames:
            frame, path = pending.pop(0)
            step = frame - at
            at = run_frames(m, step, screens, at, on_screen)
            frames -= step
            check(m, path, frame)
        return run_frames(m, frames, screens, at, on_screen) if frames > 0 else at

    def play_script_checked(s, m, path, screens, at):
        playing[0] = True
        try:
            took = play_script(s, m, path, screens, at)
        finally:
            playing[0] = False
        total[0] = at + took
        return took

    corpus.run_frames = run_frames_checked
    re_session.play_script = play_script_checked
    status = 0
    try:
        sys.argv = [script] + args
        re_session.main()
        if at_end or pending:
            s, state = re_session.session_of(work)
            m = corpus.Machine(s, state['port_base'])
            for frame, path in pending:
                print(f'replay check: {path} at frame {frame}: past the scripts\' end (frame {total[0]})')
                results.append({'state': path, 'frame': frame, 'differ': None,
                                'note': f'past the scripts\' end, frame {total[0]}'})
            for path in at_end:
                check(m, path, total[0])
        if results:
            with open(os.path.join(work, 'replay-check.json'), 'w') as f:
                json.dump(results, f, indent=1)
            if any(r['differ'] != 0 for r in results):
                status = 3
    finally:
        corpus.run_frames, re_session.play_script = run_frames, play_script
        if stop and os.path.exists(os.path.join(work, 'session.json')):
            re_session.stop(type('Args', (), {'work': work})())
            print(f'rs.py: the instance of {work} stopped')
    return status


def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    hint = None
    if args[:1] == ['--unreal'] and len(args) > 1:
        hint, args = args[1], args[2:]
    elif args and args[0].startswith('--unreal='):
        hint, args = args[0].split('=', 1)[1], args[1:]
    script = toolpaths.re_session(hint)
    args = check_inputs(args)
    if args[:1] == ['capture']:
        return capture(args, script)
    sys.argv = [script] + args
    sys.path.insert(0, os.path.dirname(script))
    runpy.run_path(script, run_name='__main__')
    return 0


if __name__ == '__main__':
    sys.exit(main())
