"""The scenes of docs/runtime-analysis.md: a window of a recording each, profiled by tools/eprof.py.

    python3 tools/rtscenes.py            # the summary table of the scenes (profiles them first when needed)

A scene is (key, label, recording, window). The profiles are kept in work/prof/ (eprof.cached), so the figures
read them without an emulator; a missing one needs its recording open (re_session.py open, WALKTHROUGH 6).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import eprof  # noqa: E402

CASE = eprof.CASE
FRAME_T = 69888

# the routines whose calls are logged with their inclusive T (the maths, the PRNGs, the 3D pipeline)
CALLS = ('DrawLine,Multiply8,Multiply8High,MultiplyScaled,MulBits,DivideFrac8,DivideShifted,Divide24,DividePoint,'
         'Divide16,DivideFraction,SquareRoot,Random,StarRandom,TextRandom,ProjectVertices,DrawEdges,FaceVisibility,'
         'UpdateSlot,UpdateShips,DrawScanner,ClearView,CopyBackBuffer,MultiplyRound,LineFraction,RotateNormal,'
         'RotateVertexScaled,Project,StardustFront,DrawSunPlanet,SoundTick,IM2Handler').split(',')

SCENES = [
    ('title', 'title (ship turning)', 'd1', '100:0-200:0'),
    ('status', 'docked: status', 'd1', '600:0-700:0'),
    ('market', 'docked: market', 'd1', '1030:0-1130:0'),
    ('galaxy', 'docked: galactic chart', 'd1', '1470:0-1570:0'),
    ('launch', 'the launch', 'f1', '960:0-1060:0'),
    ('station', 'flight: station, planet', 'f1', '1500:0-1600:0'),
    ('countdown', 'flight: jump countdown', 'f1', '1820:0-1920:0'),
    ('deep', 'flight: empty space', 'f1', '2400:0-2500:0'),
    ('tunnel', 'hyperspace tunnel', 'w1', '2100:0-2200:0'),
    ('combat', 'combat: 4 Thargoids', 'w1', '3470:0-3620:0'),
    ('death', 'death, explosion', 'w1', '4280:0-4380:0'),
]


def work(rec):
    return os.path.join(CASE, 'work', rec)


def profile(scene):
    _k, _l, rec, window = scene
    return eprof.cached(work(rec), window, CALLS)


def scene(key):
    return next(s for s in SCENES if s[0] == key)


def ships(rec, window):
    """the mean count of occupied slots over the window, from work/prof/<rec>-timeline.json (tools/timeline.py)"""
    path = os.path.join(CASE, 'work', 'prof', rec + '-timeline.json')
    if not os.path.isfile(path):
        return None
    f0, f1 = [int(x.split(':')[0]) for x in window.split('-')]
    rows = [r for r in json.load(open(path)) if f0 <= r['frame'] < f1]
    return sum(len(r['slots']) for r in rows) / len(rows) if rows else None


def summary(p):
    r = p['routines']
    tot = p['total_t']
    frames = p['frames'][1] - p['frames'][0]
    updates = r.get('ClearView', {}).get('calls', 0)
    return {
        'frames': frames,
        'updates': updates,
        'frames_per_update': frames / updates if updates else None,
        'halt': r.get('HALT', {}).get('self', 0) / tot,
        'top': sorted(((n, v['self'] / tot) for n, v in r.items()), key=lambda x: -x[1])[:5],
    }


def main():
    print('| scene | recording, frames | ships | 3D updates | frames an update | HALT | the top routines (self) |')
    print('| --- | --- | --- | --- | --- | --- | --- |')
    for s in SCENES:
        p = profile(s)
        m = summary(p)
        sh = ships(s[2], s[3])
        fpu = '%.2f' % m['frames_per_update'] if m['frames_per_update'] else '-'
        top = ', '.join('%s %.1f %%' % (n, 100 * v) for n, v in m['top'][:3])
        print('| %s | `%s` %s | %s | %d | %s | %.1f %% | %s |' % (
            s[1], s[2], s[3].replace(':0', ''), '%.1f' % sh if sh is not None else '-', m['updates'], fpu,
            100 * m['halt'], top))


if __name__ == '__main__':
    main()
