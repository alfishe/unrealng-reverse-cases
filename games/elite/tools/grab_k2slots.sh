#!/bin/bash
# k2's slots every 4 frames over the fight and the screens every 8 (docs/07-objects.md 7.7)
cd "$(dirname "$0")/.." && { [ -f work/env.sh ] && source work/env.sh; : "${RS:?set RS to unreal-ng tools/verification/analysis/re_session.py and BIN to unreal-qt}"; }
python3 $RS stop --work work/view >/dev/null 2>&1
python3 $RS open --work work/view --ttd work/k2/session.ttd --port-base 18320 --binary $BIN | tail -1
python3 -c "
import sys; sys.path.insert(0, 'tools')
import elitelib as E
E.session('work/view').call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master', 'body': {'muted': True}})"
python3 tools/grab_slots.py --work work/view k2 2484:4248:4
python3 tools/grab.py --work work/view k2 2484:4248:8 | tail -1
python3 $RS stop --work work/view
