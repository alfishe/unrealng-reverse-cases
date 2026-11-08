#!/bin/bash
# docs/img/arch/memory-pass.gif: memory over two station passes of f1 (tools/memanim.py, the kit tool with larger text; muted view instance, stopped after)
cd "$(dirname "$0")/.." && { [ -f work/env.sh ] && source work/env.sh; : "${RS:?set RS to unreal-ng tools/verification/analysis/re_session.py and BIN to unreal-qt}"; }
python3 $RS stop --work work/view >/dev/null 2>&1
python3 $RS open --work work/view --ttd work/f1/session.ttd --port-base 18320 --binary $BIN | tail -1
python3 -c "
import sys; sys.path.insert(0, 'tools')
import elitelib as E
E.session('work/view').call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master', 'body': {'muted': True}})"
python3 tools/memanim.py --work work/view --from 1504 --to 1515 --step 34944 --from-address 5B00 --screen \
  --label "f1 1504-1515, two station passes, every half frame" \
  --delay 250 docs/img/arch/memory-pass.gif
python3 $RS stop --work work/view
