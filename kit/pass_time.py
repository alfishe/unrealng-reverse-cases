#!/usr/bin/env python3
"""Time each pass of a main loop: from an instruction at START to the first instruction at END after it, the
interrupt entries that land inside included, in T and as a share of a budget of N frames. For a binary without
`analyze_performance section_timer` (python3 kit/toolpaths.py build says whether it has it), and for a recording.

    python3 kit/pass_time.py --start ADDR --end ADDR (--trace FILE.uatr | --work W --window F:T-F:T)
                             [--budget-frames N] [--top 10] [--json OUT]
    python3 kit/pass_time.py --start ADDR --end ADDR --live (--work W | --port-base P | --launch [--binary B])
                             [--snapshot S] [--passes N] [--frames N] [--max-frames 8] [--budget-frames N]
                             [--top 10] [--json OUT]

From a trace (the recording itself): every START ... END pair of the trace's instructions (a second START before an
END starts the pass again); --work W --window traces the window on W's instance once (kept in W/traces/,
kitlib.load_trace). Live (a running machine, played on from where it stands, or from --snapshot S): each pass is
control_execution run_until_pc START, the time (inspect_state snapshot: frame, T in the frame), run_until_pc END,
the time again; the work is the difference. A run_until_pc that does not reach its address within --max-frames
frames skips that pass. --passes N stops after N passes, --frames N once N frames have run (else 100 passes).
--work W attaches to W's instance (kit/rs.py open / capture), --port-base P to any instance on that port base,
--launch starts the binary ($UNREAL_BINARY, --binary) muted on --port-base (default 37720) with a fresh machine of
the snapshot's model, and stops it at the end. The keys stay as they are: a case that replays its input script
sets them between passes through the Python form:

    import pass_time as PT
    for p in PT.live_passes(session, 0xD851, 0xD86B, passes=600, before=set_keys): ...   # dicts: start, end, T
    PT.now(session) -> (frame, T in the frame, registers); PT.run_to(session, pc, frames) -> (frame, T, reached)

Prints the count, the least, the mean and the most, and the --top heaviest passes with their start and end; --json
writes every pass. A binary with section_timer is said so (it times at full speed with no stop a marker).
ATV Simulator: Pass `$D851` to WaitFrames `$D86B`, a budget of 7 frames (tools/pass_trace.py, tools/pass_time.py).
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kitlib  # noqa: E402
import toolpaths  # noqa: E402

FRAME_T = 69888


def trace_passes(trace, start, end):
    """[{start: (frame, T), end: (frame, T), T}] of a trace's START ... END pairs"""
    frame_t, unit = trace.frame_t, max(1, trace.units_per_t)

    def at(x):
        return x.frame * frame_t + x.t // unit

    out, first = [], None
    for x in trace.instructions:
        if x.pc == start:
            first = x
        elif x.pc == end and first is not None:
            out.append({'start': [first.frame, first.t // unit], 'end': [x.frame, x.t // unit],
                        'T': at(x) - at(first)})
            first = None
    return out, frame_t


def now(s):
    """(frame, T in the frame, registers) of the live machine"""
    t = s.call('inspect_state', {'aspects': ['snapshot']}, ok=False).structured['snapshot']
    return t['time']['frame'], t['time']['t'], t['regs']


def pc_of(regs):
    for k in ('pc', 'PC'):
        if k in regs:
            return regs[k]
    pc = (regs.get('special') or {}).get('pc')
    return int(pc, 16) if isinstance(pc, str) else pc


def run_to(s, pc, frames, frame_t=FRAME_T):
    """run_until_pc @p pc (an int) within @p frames frames: (frame, T, reached)"""
    s.call('control_execution', {'action': 'run_until_pc', 'pc': '0x%04X' % pc, 'max_tstates': frames * frame_t},
           ok=False)
    f, t, regs = now(s)
    return f, t, pc_of(regs) == pc


def live_passes(s, start, end, passes=None, frames=None, max_frames=8, before=None, frame_t=FRAME_T):
    """the passes of the live machine, one dict each ({start, end, T}); before(s, frame) runs ahead of each pass
    (a case sets its keys there)"""
    if passes is None and frames is None:
        passes = 100
    f0, _, _ = now(s)
    count = 0
    while True:
        f, _, _ = now(s)
        if (passes is not None and count >= passes) or (frames is not None and f - f0 >= frames):
            return
        if before:
            before(s, f)
        fa, ta, ok = run_to(s, start, max_frames, frame_t)
        if not ok:
            continue
        fb, tb, ok = run_to(s, end, max_frames, frame_t)
        if not ok:
            continue
        count += 1
        yield {'start': [fa, ta], 'end': [fb, tb], 'T': (fb - fa) * frame_t + tb - ta}


def session_for(a):
    """(mcplib session, the launched process or None)"""
    unreal = kitlib.unreal_root(a.unreal)
    sys.path.insert(0, os.path.join(unreal, 'tools', 'verification', 'analysis'))
    sys.path.insert(0, os.path.join(unreal, 'tools', 'verification', 'mcp'))
    import mcplib  # noqa: E402
    if a.work:
        import re_session  # noqa: E402
        s, state = re_session.session_of(a.work)
        return s, None, state.get('binary')
    model = kitlib.snapshot_model(a.snapshot) if a.snapshot else '48K'
    port = a.port_base or 37720
    process, binary = None, None
    if a.launch:
        binary = toolpaths.unreal_binary(a.binary)
        toolpaths.warn_binary(binary, 'pass_time.py')
        process = mcplib.launch(binary, port)
    s = mcplib.Session(f'http://127.0.0.1:{port + 200}/mcp', model)
    if a.launch:
        s.fresh_machine(model, ram_power_on='zero')
        s.call('control_execution', {'action': 'pause'}, ok=False)
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    return s, process, binary


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--start', required=True, type=kitlib.hex_address, help='the pass\'s first instruction (hex)')
    ap.add_argument('--end', required=True, type=kitlib.hex_address, help='the instruction that ends it (hex)')
    ap.add_argument('--budget-frames', type=int, default=1, help='the shares are of this many frames (default 1)')
    ap.add_argument('--top', type=int, default=10)
    ap.add_argument('--json', help='every pass as JSON')
    kitlib.add_trace_args(ap)
    ap.add_argument('--live', action='store_true', help='time the passes on a running machine (run_until_pc)')
    ap.add_argument('--port-base', type=int)
    ap.add_argument('--launch', action='store_true', help='--live: start the binary, stop it at the end')
    ap.add_argument('--binary')
    ap.add_argument('--snapshot', help='--live: load this state first')
    ap.add_argument('--passes', type=int)
    ap.add_argument('--frames', type=int)
    ap.add_argument('--max-frames', type=int, default=8)
    a = ap.parse_args()
    process = None
    if a.live:
        if a.window or a.trace:
            sys.exit('pass_time.py: --live times a running machine; --trace / --window are for a recording')
        s, process, binary = session_for(a)
        try:
            binary = binary or (toolpaths.unreal_binary(required=False) if not a.port_base else None)
            if binary and os.path.isfile(binary) and toolpaths.has_feature(binary, 'section_timer'):
                print(f'pass_time.py: {binary} has analyze_performance section_timer: it times the passes at full '
                      'speed with no stop a marker', flush=True)
            if a.snapshot:
                kitlib.mute(s)
                s.call('invoke_api', {'method': 'POST', 'path': '/api/v1/emulator/{id}/snapshot/load',
                                      'body': {'path': os.path.abspath(a.snapshot)}})
            kitlib.mute(s)
            passes = list(live_passes(s, a.start, a.end, a.passes, a.frames, a.max_frames))
        finally:
            if process is not None:
                process.terminate()
                try:
                    process.wait(10)
                except Exception:  # noqa: BLE001
                    process.kill()
        frame_t = FRAME_T
    else:
        passes, frame_t = trace_passes(kitlib.load_trace(a), a.start, a.end)
    if a.json:
        with open(a.json, 'w') as f:
            json.dump(passes, f, indent=0)
    if not passes:
        sys.exit('pass_time.py: no whole pass')
    budget = a.budget_frames * frame_t
    ts = [p['T'] for p in passes]
    print(f'passes {len(ts)}, least {min(ts)} T ({100 * min(ts) / budget:.1f} %), mean {sum(ts) // len(ts)} T, '
          f'most {max(ts)} T ({100 * max(ts) / budget:.1f} % of {a.budget_frames} x {frame_t})')
    for p in sorted(passes, key=lambda p: -p['T'])[:a.top]:
        print(f'{p["T"]:7d} T {100 * p["T"] / budget:5.1f} %  ${a.start:04X} {p["start"][0]} T {p["start"][1]} to '
              f'${a.end:04X} {p["end"][0]} T {p["end"][1]}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
