#!/bin/bash
# k2's sound windows traced from its TTD session (docs/09-sound.md 9.8): the missile, the E.C.M., a ship hit, the bomb
cd "$(dirname "$0")/.." && { [ -f work/env.sh ] && source work/env.sh; : "${RS:?set RS to unreal-ng tools/verification/analysis/re_session.py and BIN to unreal-qt}"; }
python3 $RS stop --work work/view >/dev/null 2>&1
python3 $RS open --work work/view --ttd work/k2/session.ttd --port-base 18320 --binary $BIN | tail -1
python3 - <<'PY'
import sys, types; sys.path.insert(0, 'tools'); sys.path.insert(0, '../../kit')
import elitelib as E, kitlib as K
E.session('work/view').call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master', 'body': {'muted': True}})
for w in ['2540:0-2600:0', '3185:0-3200:0', '3302:0-3335:0']:
    a = types.SimpleNamespace(trace=None, work='work/view', window=w, max_cycles=None, unreal=None)
    t = K.load_trace(a)
    print(w, len(t.instructions))
PY
mkdir -p work/k2/traces && mv work/view/traces/2540_0-2600_0.uatr work/view/traces/3185_0-3200_0.uatr work/view/traces/3302_0-3335_0.uatr work/k2/traces/
python3 $RS stop --work work/view
