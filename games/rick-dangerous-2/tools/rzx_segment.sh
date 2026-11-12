#!/bin/sh
# One recording of the RZX run: level L's RZX from its state after FROM frames (tools/rzx_log.py), the RZX's keys of
# frames FROM+1 .. TO (tools/rzx_script.py) replayed with the TTD on, then the match against the RZX's own screens.
#   sh tools/rzx_segment.sh L FROM TO [PORT_BASE] [poke]      (run in the case; source work/env.sh first)
# With "poke" the script starts with the POKE file's cheats (infinite lives `$8A30`, immune to enemies `$8C67`, to
# moving objects `$A475`, to the bomb's blast `$93B4`): the replay drifts from the RZX (the passes fall on other
# frames than in the RZX's player), and without them Rick dies where the player did not. Such a recording says so.
set -e
L=$1; FROM=$2; TO=$3; PB=${4:-37500}; P=${5:-}
NAME=rzx-l$L-$(printf %05d $FROM)${P:+-poke}
SNAP=work/stage1/rzx/l$L/at$(printf %06d $FROM).szx; [ $FROM = 0 ] && SNAP=work/stage1/rzx/l$L/start.szx
python3 tools/rzx_script.py work/stage1/rzx/inputs-l$L.json $FROM $TO > work/stage1/rec/$NAME.keys
{ head -1 work/stage1/rec/$NAME.keys
  [ -n "$P" ] && printf '0 POKE 35376 0\n0 POKE 35943 58\n0 POKE 42101 58\n0 POKE 37812 58\n'
  tail -n +2 work/stage1/rec/$NAME.keys; } > tests/inputs/$NAME.txt
rm work/stage1/rec/$NAME.keys
python3 tools/capture.py --work work/stage1/rec/$NAME --snapshot $SNAP \
  --model 128K --inputs tests/inputs/$NAME.txt --ranges 4000-FFFF --port-base $PB --binary $BIN > work/stage1/rec/$NAME.log 2>&1
python3 tools/rzx_match.py work/stage1/rzx/l$L $FROM work/stage1/rec/$NAME > work/stage1/rec/$NAME/match.txt
tail -1 work/stage1/rec/$NAME/match.txt
python3 $RS stop --work work/stage1/rec/$NAME > /dev/null 2>&1 || true
