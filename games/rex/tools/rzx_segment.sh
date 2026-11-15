#!/bin/sh
# One recording of an RZX run: part P's RZX (1: rex1.rzx, 2: rex2.rzx) from its state after FROM frames
# (tools/rzx_log.py, work/stage1/rzx/pP/), the RZX's keys of frames FROM+1 .. TO (tools/rzx_script.py) replayed with
# the TTD on, then the match against the RZX's own screens (tools/rzx_match.py).
#   sh tools/rzx_segment.sh P FROM TO [PORT_BASE] [poke]      (run in the case; source work/env.sh first)
# With "poke" the script starts with the POKE file's infinite lives (part 1 `40057,0`, part 2 `40303,0`): the replay
# may drift from the RZX, and without it Rex dies where the player did not. Such a recording says so in its name.
set -e
P=$1; FROM=$2; TO=$3; PB=${4:-37780}; K=${5:-}
NAME=rzx-p$P-$(printf %05d $FROM)${K:+-poke}
SNAP=work/stage1/rzx/p$P/at$(printf %06d $FROM).szx; [ $FROM = 0 ] && SNAP=work/stage1/rzx/p$P/start.szx
mkdir -p work/stage1/rec
python3 tools/rzx_script.py work/stage1/rzx/inputs-p$P.json $FROM $TO > work/stage1/rec/$NAME.keys
{ head -1 work/stage1/rec/$NAME.keys
  if [ -n "$K" ]; then [ $P = 1 ] && echo '0 POKE 40057 0'; [ $P = 2 ] && echo '0 POKE 40303 0'; fi
  tail -n +2 work/stage1/rec/$NAME.keys; } > tests/inputs/$NAME.txt
rm work/stage1/rec/$NAME.keys
python3 tools/capture.py --work work/stage1/rec/$NAME --snapshot $SNAP \
  --model 128K --inputs tests/inputs/$NAME.txt --ranges 4000-FFFF --port-base $PB --binary $BIN > work/stage1/rec/$NAME.log 2>&1
python3 tools/rzx_match.py work/stage1/rzx/p$P $FROM work/stage1/rec/$NAME > work/stage1/rec/$NAME/match.txt
tail -1 work/stage1/rec/$NAME/match.txt
python3 $RS stop --work work/stage1/rec/$NAME > /dev/null 2>&1 || true
