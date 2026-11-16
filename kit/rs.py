#!/usr/bin/env python3
"""Run unreal-ng's re_session.py (tools/verification/analysis/re_session.py) from the kit, so a case's commands name
one path in this repository instead of a variable set on one machine.

    python3 kit/rs.py [--unreal U] capture|open|build|stages|interrupts|call|export|check|stop ...
    python3 kit/rs.py capture ... [--stop] [--expect STATE[@FRAME] ...] [--expect-ranges LO-HI[,LO-HI ...]]
                                  [--tape-seek N]
    python3 kit/rs.py capture --snapshot S ...      (no --model: the snapshot's own model, kitlib.snapshot_model)

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
  --tape-seek N  with --media (a tape): the head goes to block N (POST /tape/seek, the emulator's block index: a
              TZX's text and info blocks count) as soon as the tape is inserted, before LOAD "" (or the 128 menu's
              Tape Loader) runs, so a capture loads a later program of the tape (Rex: side 1 block 6, REX 2 alone),
              with the fast LD-BYTES trap on or off. The seek waits until the tape reports block N
              (kitlib.tape_wait: with a TTD recording running, unreal-ng puts the tape in at the next frame boundary,
              and a seek before it answers "Block N out of range"); frames run for that are printed and kept in
              "tape_seek_wait_frames" (0 when the tape is in at once). The seek's answer is printed and kept in W/capture.json
              "tape_seek"; a case wrapper that replaces corpus.load gets it too when it ends with
              rs.main(['capture', ...]) (the seek follows its load_software call)

  --binary    capture and open with no --binary take $UNREAL_BINARY (work/env.sh sets it to the case's BIN;
              toolpaths.unreal_binary checks it is an executable) and pass it on, printing "rs.py: --binary B
              (UNREAL_BINARY)"; re_session.py's own default (the checkout's cmake-build-agent-release) only when the
              variable is unset. A --binary given is kept. The binary that will run is checked for the unreal-ng
              fixes the recipes name (kit/toolpaths.py build): a warning for each it lacks (f13cee7da: a TZX whose
              last block has no pause does not load), the run goes on

  --snapshot S without --model: re_session.py would create its default 48K and a 128K state would not load there;
              rs.py reads the model from the snapshot (an SZX's machine id, a .z80's hardware byte, a .sna's length)
              and passes --model itself, printing "rs.py: --model 128K from S". A --model that differs from the
              snapshot's is kept, with a warning. A case wrapper that calls re_session.main itself gets the same with
              kitlib.model_from_snapshot(argv)

  interrupts  after re_session.py's lines, a handler that leaves by a patched jump (its tail jumps from one site go
              to several routines: the operand is the interrupted address, Enduro Racer `JP nn` at `$6523`) gets the
              kit's own T-states an entry: L1's inclusive count runs on after such a jump (676 717 T for Enduro
              Racer's 744-25 467), so the kit sums the handler's own T-states and its calls' (rs.handler_estimates).
              kit/handler_time.py measures each entry exactly over a trace window

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
    kit_options.seek = None
    k = 0
    while k < len(args):
        a = args[k]
        if a == '--stop':
            stop = True
        elif a == '--tape-seek' or a.startswith('--tape-seek='):
            if '=' in a:
                value = a.split('=', 1)[1]
            else:
                if k + 1 >= len(args):
                    sys.exit('rs.py: --tape-seek needs a block number')
                k += 1
                value = args[k]
            if not value.isdigit():
                sys.exit(f'rs.py: --tape-seek {value}: a block number')
            kit_options.seek = int(value)
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
    args = kitlib.model_from_snapshot(args, 'rs.py')
    seek = kit_options.seek
    work = args[args.index('--work') + 1] if '--work' in args[:-1] else None
    if (stop or expect) and not work:
        sys.exit('rs.py: --stop / --expect need capture --work W')
    if seek is not None and not any(a == '--media' or a.startswith('--media=') for a in args):
        sys.exit('rs.py: --tape-seek needs capture --media (a tape)')
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

    load = corpus.load

    def load_seek(m, game, media, report, args):
        # --tape-seek: the head to block N right after the tape is inserted, before the ROM's LOAD runs (the fast
        # LD-BYTES trap would read the first program while LOAD "" is typed, before any play)
        call = m.s.call

        def call_seek(tool, params=None, ok=True):
            r = call(tool, params, ok=ok)
            if tool == 'load_software':
                # the insert may land at the next frame boundary (a recording runs): wait until block N shows
                waited = kitlib.tape_wait(m.s, seek)
                if waited:
                    print(f'rs.py: --tape-seek {seek}: the tape showed its blocks after {waited} frame(s)', flush=True)
                report['tape_seek_wait_frames'] = waited
                got = call('invoke_api', {'method': 'POST', 'path': '/api/v1/emulator/{id}/tape/seek',
                                          'body': {'block': seek}}, ok=False)
                text = (got.text or '').splitlines()[-1][:160] if got.text else ''
                report['tape_seek'] = {'block': seek, 'answer': text}
                print(f'rs.py: --tape-seek {seek}: {text}', flush=True)
                if got.is_error or not text.startswith('Seeked'):
                    sys.exit(f'rs.py: --tape-seek {seek} failed: {text}')
            return r

        m.s.call = call_seek
        try:
            return load(m, game, media, report, args)
        finally:
            del m.s.call

    corpus.run_frames = run_frames_checked
    re_session.play_script = play_script_checked
    if seek is not None:
        corpus.load = load_seek
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
        corpus.run_frames, re_session.play_script, corpus.load = run_frames, play_script, load
        if stop and os.path.exists(os.path.join(work, 'session.json')):
            re_session.stop(type('Args', (), {'work': work})())
            print(f'rs.py: the instance of {work} stopped')
    return status


def given_binary(args):
    """the --binary of re_session.py's arguments, or None"""
    for k, a in enumerate(args):
        if a == '--binary' and k + 1 < len(args):
            return args[k + 1]
        if a.startswith('--binary='):
            return a.split('=', 1)[1]
    return None


def binary_args(args):
    """capture / open with no --binary: $UNREAL_BINARY (a case's work/env.sh sets it to its BIN) passed on as
    --binary, so the instance is the case's build, not re_session.py's default (the checkout's
    cmake-build-agent-release); printed once. Without the variable the arguments stay as they are. Either way the
    binary that will run is checked for the unreal-ng fixes the recipes name (toolpaths.warn_binary: a warning a
    fix it lacks, e.g. f13cee7da, the tape's last edge)"""
    if args[:1] not in (['capture'], ['open']):
        return args
    binary = given_binary(args)
    if binary is None and os.environ.get('UNREAL_BINARY'):
        binary = toolpaths.unreal_binary()
        print(f'rs.py: --binary {binary} (UNREAL_BINARY)', flush=True)
        args = args + ['--binary', binary]
    found = binary or toolpaths.unreal_binary(required=False)
    if found and os.path.isfile(found):
        toolpaths.warn_binary(found, 'rs.py')
    return args


def handler_estimates(doc):
    """[(entry, T an entry, own T, calls T, the tail site, its targets)] of the interrupt handlers of an L1 that
    leave by a patched jump: their tail calls from one site go to more than one routine (Enduro Racer: `JP nn` at
    `$6523`, its operand the interrupted address). L1's tstates_inclusive of such a handler runs on after the jump;
    the kit counts the handler's own T-states and those of the routines it calls (each callee's inclusive count, or
    its own when that is larger, times the share of its entries the handler made), not the tail jumps"""
    routines, out = doc['routines'], []
    calls = {}
    for c in doc['calls']:
        calls.setdefault(c['caller'], []).append(c)
    for i, r in enumerate(routines):
        kinds = r['kinds'].split(',') if isinstance(r['kinds'], str) else r['kinds']
        if not any(k.strip() in ('interrupt', 'nmi') for k in kinds):
            continue
        sites = {}
        for c in calls.get(i, []):
            if c['kind'] == 'tail':
                for site in c.get('sites', []):
                    sites.setdefault(site, set()).add(c['callee'])
        patched = [(site, len(t)) for site, t in sites.items() if len(t) > 1]
        if not patched:
            continue
        p = r['profile']
        entries = max(1, p['entries'])
        own, called = p['tstates'], 0
        for c in calls.get(i, []):
            if c['kind'] == 'tail':
                continue
            q = routines[c['callee']]['profile']
            called += max(q['tstates_inclusive'], q['tstates']) * c['count'] / max(1, q['entries'])
        site, targets = max(patched, key=lambda x: x[1])
        out.append((r['entry'], (own + called) / entries, own / entries, called / entries, site, targets))
    return out


def interrupts_note(args):
    """after re_session.py interrupts: the kit's own T-states an entry for a handler that leaves by a patched jump"""
    work = args[args.index('--work') + 1] if '--work' in args[:-1] else None
    path = os.path.join(work, 'l1.json') if work else None
    if not path or not os.path.exists(path):
        return
    with open(path) as f:
        doc = json.load(f)
    for entry, each, own, called, site, targets in handler_estimates(doc):
        print(f'rs.py: {entry} leaves by a patched jump ({site} to {targets} places): the T an entry above runs on '
              f'after it. The kit: {each:.0f} T an entry (own {own:.0f} + calls {called:.0f}, the mean over the '
              f'build); kit/handler_time.py --exit {site.lstrip("$")} measures each entry over a trace window')


def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    hint = None
    if args[:1] == ['--unreal'] and len(args) > 1:
        hint, args = args[1], args[2:]
    elif args and args[0].startswith('--unreal='):
        hint, args = args[0].split('=', 1)[1], args[1:]
    script = toolpaths.re_session(hint)
    args = binary_args(check_inputs(args))
    if args[:1] == ['capture']:
        return capture(args, script)
    sys.argv = [script] + args
    sys.path.insert(0, os.path.dirname(script))
    runpy.run_path(script, run_name='__main__')
    if args[:1] == ['interrupts']:
        sys.stdout.flush()
        interrupts_note(args)
    return 0


if __name__ == '__main__':
    sys.exit(main())
